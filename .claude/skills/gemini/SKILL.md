---
name: gemini
description: Gemini CLI（Google）を使ってタスクを実行する
argument-hint: "依頼内容"
user-invocable: true
allowed-tools: Bash
---

# Gemini CLI 連携スキル

Gemini CLI を使って、指定されたタスクを実行します。

## 実行方法

以下のコマンドで Gemini CLI をワンショット実行してください：

```bash
npx gemini -y "$ARGUMENTS"
```

## オプション説明

- `-y`: 自動承認モード（YOLOモード）を有効化
- positional argument で直接プロンプトを渡し、ワンショット実行

## 注意事項

- Gemini の出力結果を確認し、必要に応じて内容を統合・補足してユーザーに報告してください
- Gemini の提案をそのまま適用せず、妥当性を判断した上で採用してください
