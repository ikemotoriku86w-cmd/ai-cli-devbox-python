# Claude Code 用コンテキスト

## プロジェクト概要

<!-- プロジェクト固有の情報をここに追記してください -->

## 設定構成

- 言語設定: `.claude/settings.json` の `language` で管理
- エージェント協働ルール: `.claude/rules/agent-collaboration.md`
- Codex CLI 連携: `/codex` スキル

## 開発環境の運用

- このリポジトリはマルチステージ Dockerfile + Dev Container 構成。作業は非root の `appuser`、ワークスペースは `/app`。
- **Claude Code の更新**: ホスト側で `./scripts/update-claude-code`（既定 stable / `latest` 指定可）。`Dockerfile` の ARG を書き換えて再ビルドし、更新を永続化する。コンテナ内の自動更新は `DISABLE_AUTOUPDATER=1` で無効化済み（イメージのピン版と実行版の乖離を防ぐため）。
- **ツールのバージョン更新（汎用）**: `Dockerfile` 冒頭の ARG を編集 → 再ビルド（`docker compose up --build` / Rebuild Container）。コンテナ内 `npm update -g` は再生成で消えるため使わない。
- **Python 依存の追加**: `requirements.txt` に追記 → 再ビルド。コンテナ内 `pip install` は一時的（再生成で消える）。
