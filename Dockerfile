FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl sudo ca-certificates \
    wget \
    gnupg2 \
  && rm -rf /var/lib/apt/lists/*

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=Asia/Tokyo

COPY requirements.txt .
RUN python -m pip install --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt

# ============================================
# AI CLIツールのインストール
# ============================================
# 注意: ツールの管理方法
# - Claude Code: devcontainer.jsonのfeaturesで管理（公式Feature使用）
# - Node.js: devcontainer.jsonのfeaturesで管理（devcontainer feature使用）
# - Gemini CLI: devcontainer.jsonのpostCreateCommandでnpm経由インストール
# - Codex CLI: devcontainer.jsonのpostCreateCommandでnpm経由インストール
# ============================================

RUN groupadd -g 1000 appuser \
  && useradd -m -u 1000 -g 1000 -s /bin/bash appuser \
  && echo "appuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99-appuser \
  && chmod 440 /etc/sudoers.d/99-appuser \
  && chown -R appuser:appuser /app

USER appuser

RUN echo "" >> ~/.bashrc \
  && echo "if [ -f /app/.bashrc_aliases ]; then" >> ~/.bashrc \
  && echo "    . /app/.bashrc_aliases" >> ~/.bashrc \
  && echo "fi" >> ~/.bashrc

CMD ["sleep", "infinity"]
