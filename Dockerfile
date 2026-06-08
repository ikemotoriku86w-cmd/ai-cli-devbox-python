# ============================================================
# AI CLI DevBox — 共有ベースイメージ（配布対応版）
# ・全ツールをここに焼き込む（features / postCreate は使わない）
# ・バージョンは下の ARG 一箇所で集中管理（配布のため全ピン留め）
# ・ビルドツール群は入れない（= 旧 nodeGypDependencies:true を廃止）
#
# このリポジトリは共有ベースイメージ ai-devbox:1.0 の生成元です。
# 各プロジェクトの docker-compose.yml は image: ai-devbox:1.0 を参照します。
# 先に一度だけ：docker build -t ai-devbox:1.0 .
# ============================================================
FROM python:3.11-slim

# --- バージョン集中管理：更新時はここだけ変えて再ビルド ---
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

# システム依存（最小限。build-essential 等のコンパイラ群は入れない）
RUN apt-get update && apt-get install -y --no-install-recommends \
      git curl sudo ca-certificates wget gnupg2 \
  && rm -rf /var/lib/apt/lists/*

# Python 依存
COPY requirements.txt .
RUN python -m pip install --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt

# Node.js（ピン留めしたメジャー）
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/*

# AI CLI 3種（バージョン固定・グローバル / いずれも純JSでコンパイル不要）
RUN npm install -g \
      @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} \
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

RUN echo "" >> ~/.bashrc \
 && echo "if [ -f /app/.bashrc_aliases ]; then . /app/.bashrc_aliases; fi" >> ~/.bashrc

CMD ["sleep", "infinity"]
