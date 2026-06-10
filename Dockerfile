# ============================================================
# AI CLI DevBox — マルチステージ構成
# ・tools ステージ: 全プロジェクト共通の AI CLI ツール群を導入。
#   命令・ベースイメージ・ビルド引数が同一である限り、BuildKit キャッシュと
#   内容アドレス可能レイヤーがプロジェクト間で再利用される（＝重い層を共有）。
#   ※キャッシュ削除や別 Builder では再ビルドされる。
# ・final ステージ: プロジェクト固有の Python 依存（requirements.txt）を導入。
#   ここだけは requirements 変更時に再ビルドされる薄い層。
#
# 各プロジェクトの docker-compose.yml は build: . でプロジェクト固有のイメージを
# ビルドする（固定共有タグは使わない＝タグ上書き衝突は発生しない）。
#
# 再現性の到達範囲:
#   - ベースイメージ … index(manifest list) digest で固定（amd64/arm64 を確認済み）
#   - Python 依存   … requirements.txt で == 固定
#   - pip 自体      … base digest 固定中は同梱 pip も実質固定（明示アップグレードしない）
#   - Node / apt    … 浮動を許容（NodeSource は旧版を削除し得るため版固定は不採用）
# ============================================================

# --- ベースイメージ（FROM より前で宣言。FROM 行でのみ参照可能） ---
# python:3.11-slim の index digest（マルチアーキ: linux/amd64, linux/arm64/v8 を含む）。
# 更新時は `docker buildx imagetools inspect python:3.11-slim` で新しい digest を取得し、
# 対象プラットフォームでの動作（tzdata 等）を再検証すること。
ARG PYTHON_BASE=python:3.11-slim@sha256:a3ab0b966bc4e91546a033e22093cb840908979487a9fc0e6e38295747e49ac0

# ============================================================
# tools ステージ：全プロジェクト共有の AI CLI ツール層
# ============================================================
FROM ${PYTHON_BASE} AS tools

# --- バージョン集中管理：更新時はここだけ変えて再ビルド ---
# （FROM より後で宣言しないとステージ内で参照できない点に注意）
ARG NODE_MAJOR=20
ARG CLAUDE_CODE_VERSION=2.1.168
ARG GEMINI_CLI_VERSION=0.45.2
ARG CODEX_VERSION=0.137.0

WORKDIR /app

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=Asia/Tokyo \
    NODE_OPTIONS=--max-old-space-size=4096

# Claude Code は自動更新を許可する（更新版は設定ボリューム /home/appuser/.claude に
# 保存されるため、コンテナを再作成しても保持される）。ARG のピン版は初期導入版の意味。

# システム依存（最小限。build-essential 等のコンパイラ群は入れない）
RUN apt-get update && apt-get install -y --no-install-recommends \
      git curl sudo ca-certificates wget gnupg2 \
  && rm -rf /var/lib/apt/lists/*

# Node.js（ピン留めしたメジャー / NodeSource 経由は版が浮動）
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/*

# AI CLI（バージョン固定・グローバル / いずれも純JSでコンパイル不要）
# gemini / codex は root のシステム領域へ（更新頻度が低く、ピン版のままでよい）
RUN npm install -g \
      @google/gemini-cli@${GEMINI_CLI_VERSION} \
      @openai/codex@${CODEX_VERSION} \
 && npm cache clean --force

# 非root ユーザー
RUN groupadd -g 1000 appuser \
 && useradd -m -u 1000 -g 1000 -s /bin/bash appuser \
 && echo "appuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99-appuser \
 && chmod 440 /etc/sudoers.d/99-appuser \
 && chown -R appuser:appuser /app

USER appuser

# Claude Code は appuser が書き込める npm prefix（~/.npm-global）へ導入する。
# root のシステム領域だと appuser の自動更新が権限エラーで失敗するため。
# ここはコンテナ層（再作成でピン版に戻る）。再作成後も初回起動の自動更新で最新化される。
RUN npm config set prefix /home/appuser/.npm-global \
 && npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} \
 && npm cache clean --force
ENV PATH=/home/appuser/.npm-global/bin:$PATH

RUN echo "" >> ~/.bashrc \
 && echo "if [ -f /app/.bashrc_aliases ]; then . /app/.bashrc_aliases; fi" >> ~/.bashrc

# ============================================================
# final ステージ：プロジェクト固有の Python 依存層
# ・tools は USER appuser のため、システム領域への pip install は root に戻して実行
# ============================================================
FROM tools AS final

USER root
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
USER appuser

CMD ["sleep", "infinity"]
