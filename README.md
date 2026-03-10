# AI CLI Devbox

Docker + Dev Container で Claude Code / Gemini CLI / Codex CLI がすぐ使える開発ボックス。

## 含まれるツール

| ツール | 管理方法 | 用途 |
|--------|----------|------|
| **Claude Code** | Dev Container Feature | AI コーディングアシスタント |
| **Gemini CLI** | npm (postCreateCommand) | Google Gemini との対話 |
| **Codex CLI** | npm (postCreateCommand) | OpenAI Codex との対話 |
| **Python 3.11** | Dockerfile ベースイメージ | Python 開発 |

## Claude Code のスキル

コンテナ内の Claude Code では以下のスキルが使えます：

- `/gemini <依頼内容>` - Gemini CLI にタスクを委譲
- `/codex <依頼内容>` - Codex CLI にタスクを委譲

## ディレクトリ構成

```
.
├── Dockerfile              # Python 3.11-slim ベースイメージ
├── .env.example            # 環境変数テンプレート
├── docker-compose.yml      # コンテナ構成
├── .devcontainer/
│   └── devcontainer.json   # Dev Container 設定
├── .claude/
│   ├── settings.json       # Claude Code 設定
│   ├── rules/              # エージェント協働ルール
│   └── skills/             # カスタムスキル定義
├── requirements.txt        # Python 依存関係
└── .bashrc_aliases         # シェルエイリアス
```

## カスタマイズ

- **Python パッケージ追加**: `requirements.txt` を編集
- **Claude Code 設定**: `.claude/settings.json` を編集
- **VS Code 拡張機能追加**: `.devcontainer/devcontainer.json` の `extensions` に追加

## 前提条件

以下のツールを事前にインストールしてください。

### Docker Desktop

コンテナを動かすために必要です。

- [Docker Desktop ダウンロード](https://www.docker.com/products/docker-desktop/)（Windows / Mac / Linux）
- インストール後、Docker Desktop を起動しておく

### VS Code + Dev Containers 拡張機能

コンテナ内での開発に使います。

1. [VS Code ダウンロード](https://code.visualstudio.com/)
2. VS Code を開き、拡張機能から **Dev Containers**（`ms-vscode-remote.remote-containers`）をインストール

### AI サービスのアカウント

使いたいツールに応じて、いずれかのサブスクリプションが必要です。

- [Claude](https://claude.ai/)（Claude Code 用）
- [Gemini](https://gemini.google.com/)（Gemini CLI 用）
- [ChatGPT](https://chatgpt.com/)（Codex CLI 用）

## 使い方

### 1. ダウンロード

GitHub ページの **「Code」→「Download ZIP」** からダウンロードし、任意の場所に展開してください。

### 2. フォルダ名の変更

展開したフォルダ名をプロジェクトに合わせてわかりやすい名前に変更してください（例: `my-project`）。

### 3. 環境変数ファイルの作成

`.env.example` をコピーして `.env` を作成してください。

```bash
cp .env.example .env
```

必要に応じて `.env` 内の値を編集してください。`.env` は `.gitignore` で除外されているため、シークレット情報を安全に管理できます。

### 4. コンテナの起動

1. VS Code でフォルダを開く
2. コマンドパレットから **「Dev Containers: Reopen in Container」** を実行

### 5. 各ツールの認証

コンテナ起動後、各ツールのログインコマンドで認証します：

```bash
claude login        # Claude Code（Anthropic アカウント）
gemini              # Gemini CLI（Google アカウント）
codex login         # Codex CLI（OpenAI アカウント）
```

認証情報は Docker ボリュームに永続化されるため、コンテナを再起動しても再ログインは不要です。
