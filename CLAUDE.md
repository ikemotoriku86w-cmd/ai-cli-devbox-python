# Claude Code 用コンテキスト

## プロジェクト概要

<!-- プロジェクト固有の情報をここに追記してください -->

## 設定構成

- 言語設定: `.claude/settings.json` の `language` で管理
- エージェント協働ルール: `.claude/rules/agent-collaboration.md`
- Codex CLI 連携: `/codex` スキル

## 開発環境の運用

- このリポジトリはマルチステージ Dockerfile + Dev Container 構成。作業は非root の `appuser`、ワークスペースは `/app`。
- **ツールのバージョン更新**: `Dockerfile` 冒頭の ARG を編集 → 再ビルド（`docker compose up --build` / Rebuild Container）。コンテナ内 `npm update -g` は再生成で消えるため使わない。
- **Python 依存の追加**: `requirements.txt` に追記 → 再ビルド。コンテナ内 `pip install` は一時的（再生成で消える）。
