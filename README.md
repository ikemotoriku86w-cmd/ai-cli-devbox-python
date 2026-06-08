# AI CLI Devbox

Docker + Dev Container で Claude Code / Gemini CLI / Codex CLI がすぐ使える開発ボックス。

全ツールを **共有ベースイメージ `ai-devbox:1.0`** に焼き込み、各プロジェクトはそれを
**参照するだけ** の構成です。プロジェクトごとに重いツール層を重複して持たないため、
プロジェクトを増やしてもディスク使用量がほとんど増えません。

## 含まれるツール

| ツール | 管理方法 | バージョン |
|--------|----------|------------|
| **Claude Code** | 共有イメージに焼き込み | 2.1.168（`Dockerfile` の ARG で集中管理） |
| **Gemini CLI** | 共有イメージに焼き込み | 0.45.2 |
| **Codex CLI** | 共有イメージに焼き込み | 0.137.0 |
| **Node.js** | 共有イメージに焼き込み | 20.x |
| **Python** | 共有イメージのベース | 3.11-slim |

> 旧構成（Dev Container Features + postCreateCommand での npm インストール）は廃止しました。
> ツールはすべてイメージに焼き込み済みなので、コンテナ起動が速く、プロジェクトごとの
> feature 層の重複（実測 ~870MB/台）も発生しません。
> バージョンは `Dockerfile` 冒頭の ARG 一箇所で集中管理しています（更新時はここだけ変更して再ビルド）。

## Claude Code のスキル

コンテナ内の Claude Code では以下のスキルが使えます：

- `/gemini <依頼内容>` - Gemini CLI にタスクを委譲
- `/codex <依頼内容>` - Codex CLI にタスクを委譲

## 仕組み（重要）

このリポジトリは GitHub の **テンプレートリポジトリ** です。
「Use this template」で新しいプロジェクト用リポジトリを作成し、ローカルに clone して使います。

- このリポジトリ（および複製された各プロジェクト）に含まれる `Dockerfile` が、
  共有ベースイメージ **`ai-devbox:1.0` の定義元** です（全プロジェクトで同一内容）。
- 各プロジェクトの `docker-compose.yml` は `image: ai-devbox:1.0` を **参照するだけ** で、
  ビルドはしません。
- そのため **マシンごとに一度だけ** `docker build -t ai-devbox:1.0 .` してベースを作れば、
  以降そのマシン上の全プロジェクトが同じ 1 イメージを共有します。
- 認証情報はイメージに焼き込まず、名前付きボリューム（`claude-code-config` ほか）に
  分離・永続化します。

## ディレクトリ構成

```
.
├── Dockerfile              # 共有ベースイメージ ai-devbox:1.0 の定義（全ツール焼き込み）
├── .env.example            # 環境変数テンプレート
├── docker-compose.yml      # ai-devbox:1.0 を参照するコンテナ構成
├── .devcontainer/
│   └── devcontainer.json   # Dev Container 設定（features なし）
├── .claude/
│   ├── settings.json       # Claude Code 設定
│   ├── rules/              # エージェント協働ルール
│   └── skills/             # カスタムスキル定義
├── requirements.txt        # Python 依存関係
└── .bashrc_aliases         # シェルエイリアス
```

## カスタマイズ

- **Python パッケージ追加**: `requirements.txt` を編集 → ベースイメージを再ビルド
- **ツールのバージョン変更**: `Dockerfile` 冒頭の ARG を編集 → ベースイメージを再ビルド
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

### 1. プロジェクトを作成

GitHub の **「Use this template」** から新しいリポジトリを作成し、ローカルに clone してください
（既存テンプレートを直接使う場合は ZIP ダウンロードでも可）。

### 2. 環境変数ファイルの作成

`.env.example` をコピーして `.env` を作成してください。

```bash
cp .env.example .env
```

必要に応じて `.env` 内の値を編集してください。`.env` は `.gitignore` で除外されているため、シークレット情報を安全に管理できます。

### 3. 共有ベースイメージのビルド（マシンに一度だけ）

プロジェクトのフォルダで、共有ベースイメージを一度だけビルドします。

```bash
docker build -t ai-devbox:1.0 .
```

> このコマンドはマシンに `ai-devbox:1.0` が無いときだけ必要です。一度作れば、同じマシン上の
> 他のプロジェクトはビルド不要でそのまま起動できます。

### 4. コンテナの起動

VS Code を使う場合:

1. VS Code でフォルダを開く
2. コマンドパレットから **「Dev Containers: Reopen in Container」** を実行

CLI を使う場合:

```bash
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . bash
```

### 5. 各ツールの認証

コンテナ起動後、各ツールのログインコマンドで認証します：

```bash
claude        # Claude Code（Anthropic アカウント）
gemini        # Gemini CLI（Google アカウント）
codex login   # Codex CLI（OpenAI アカウント）
```

認証情報は Docker ボリュームに永続化されるため、コンテナを再起動しても再ログインは不要です。
（ボリュームはプロジェクト名で分かれるため、別プロジェクトでは初回ログインが必要です。）
