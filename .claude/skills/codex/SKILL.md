---
name: codex
description: Codex CLI（OpenAI）を使ってコード相談・レビューを実行する
argument-hint: "依頼内容"
user-invocable: true
allowed-tools: Bash
---

# Codex CLI 連携スキル

Codex CLI を使って、指定されたタスクを実行します。

## 実行方法

以下のコマンドで Codex CLI を非対話型実行してください：

```bash
codex exec --sandbox read-only --skip-git-repo-check "$ARGUMENTS"
```

## オプション説明

- `exec`: 非対話型実行モード
- `--sandbox read-only`: ファイルへの書き込みを制限した読み取り専用サンドボックス（調査用コマンドの実行は可能）
- `--skip-git-repo-check`: git リポジトリチェックをスキップ

## 注意事項

- Codex の出力結果を確認し、必要に応じて内容を統合・補足してユーザーに報告してください
- Codex の提案をそのまま適用せず、妥当性を判断した上で採用してください
