# AI CLI Devbox

Docker + Dev Container で Claude Code / Gemini CLI / Codex CLI がすぐ使える開発ボックス。

全ツールを **マルチステージ Dockerfile の `tools` ステージ** に焼き込み、プロジェクト固有の
Python 依存だけを `final` ステージで追加する構成です。`tools` 層は Docker のレイヤーキャッシュで
プロジェクト間に再利用されるため、プロジェクトを増やしても重いツール層が重複しにくくなっています。

## 含まれるツール

| ツール | 管理方法 | バージョン |
|--------|----------|------------|
| **Claude Code** | tools ステージに焼き込み | 2.1.168（`Dockerfile` の ARG で集中管理） |
| **Gemini CLI** | tools ステージに焼き込み | 0.45.2 |
| **Codex CLI** | tools ステージに焼き込み | 0.137.0 |
| **Node.js** | tools ステージに焼き込み | 20.x |
| **Python** | tools ステージのベース | 3.11-slim（digest 固定） |

> 旧構成（Dev Container Features + postCreateCommand での npm インストール）は廃止しました。
> ツールはすべてイメージに焼き込み済みなので、コンテナ起動が速く、プロジェクトごとの
> feature 層の重複も発生しません。
> バージョンは `Dockerfile` 冒頭の ARG 一箇所で集中管理しています（更新時はここだけ変更して再ビルド）。

## Claude Code のスキル

コンテナ内の Claude Code では以下のスキルが使えます：

- `/codex <依頼内容>` - Codex CLI にタスクを委譲（読み取り専用サンドボックスで実行）

> Gemini への委譲スキル（`/codex` 相当）は、現行 Gemini CLI に非対話で安全に使える
> サンドボックス／承認モードが揃うまで一旦同梱していません。Gemini CLI 自体はイメージに
> 含まれているため、コンテナ内で `gemini` を直接実行する形では利用できます。

## 仕組み（重要）

このリポジトリは GitHub の **テンプレートリポジトリ** です。
「Use this template」で新しいプロジェクト用リポジトリを作成し、ローカルに clone して使います。

- 各プロジェクトは自分の `docker-compose.yml`（`build: .`）で**プロジェクト固有のイメージ**を
  ビルドします。固定の共有タグは使わないため、プロジェクト間でタグが上書き衝突することはありません。
- 重い `tools` 層（AI CLI ツール群）は、**同一の Dockerfile 命令・ベースイメージ・ビルド引数を
  使う限り、BuildKit のキャッシュと Docker の内容アドレス可能レイヤーが再利用されます**。
  そのため 2 プロジェクト目以降は `tools` 層のビルドが省略され、`requirements.txt` を変えた
  `final` 層だけが再ビルドされます。
  （キャッシュを削除した場合や別の Builder を使う場合は再ビルドされます。）
- 認証情報はイメージに焼き込まず、名前付きボリューム（`claude-code-config` ほか）に
  分離・永続化します。

### 再現性の到達範囲

- **ベースイメージ**: `python:3.11-slim` を index（manifest list）digest で固定（linux/amd64・linux/arm64 を確認済み）。
- **Python 依存**: `requirements.txt` で `==` 固定。
- **pip 自体**: base digest 固定中は同梱 pip も実質固定（明示的なアップグレードはしない）。
- **Node / apt パッケージ**: 浮動を許容（NodeSource は旧版を削除し得るため、版の厳密固定は不採用）。

## ディレクトリ構成

```
.
├── Dockerfile              # マルチステージ（tools: 全ツール焼き込み / final: Python 依存）
├── .dockerignore           # ビルドコンテキストから秘密情報・キャッシュ類を除外
├── docker-compose.yml      # build: . でプロジェクト固有イメージをビルド
├── .devcontainer/
│   └── devcontainer.json   # Dev Container 設定（features なし）
├── .claude/
│   ├── settings.json       # Claude Code 設定
│   ├── rules/              # エージェント協働ルール
│   └── skills/             # カスタムスキル定義（codex）
├── scripts/
│   └── update-claude-code  # Claude Code を安全に更新（ARG 書き換え→再ビルド）
├── requirements.txt        # Python 依存関係（== 固定）
└── .bashrc_aliases         # シェルエイリアス
```

## カスタマイズ

- **Python パッケージ追加**: `requirements.txt` を編集 → イメージを再ビルド（`final` 層のみ再ビルドされる）
- **ツールのバージョン変更**: `Dockerfile` 冒頭の ARG を編集 → イメージを再ビルド
- **Claude Code 設定**: `.claude/settings.json` を編集
- **VS Code 拡張機能追加**: `.devcontainer/devcontainer.json` の `extensions` に追加

## Claude Code の更新

Claude Code は更新が頻繁なため、更新スクリプトを用意しています。
**Dockerfile のピン留めを「正」としたまま**、バージョンの書き換えと再ビルドを 1 コマンドで行います。

```bash
# ホスト側で実行（コンテナ内からは docker を操作できないため）
./scripts/update-claude-code            # stable へ更新（既定）
./scripts/update-claude-code latest     # latest へ更新
./scripts/update-claude-code 2.1.170    # 明示バージョンへ更新
```

スクリプトは次を行います：

1. npm の dist-tag から対象バージョンを取得（既定は回帰を避けやすい **stable**。約1週間遅れ）
2. `Dockerfile` の `ARG CLAUDE_CODE_VERSION` を書き換え
3. `docker compose up --build -d` で再ビルド・起動（Claude Code は独立レイヤーなので再インストールは Claude Code のみ）
4. 反映後の `claude --version` を確認

> コンテナ内の自動更新は `DISABLE_AUTOUPDATER=1` で無効化しています（イメージのピン版と
> 実行版が乖離するのを防ぐため）。バージョン変更は `Dockerfile` の Git 差分として残ります。
> 以前の版に戻したいときは、その版を明示指定して再実行すれば安全に戻せます
> （例: `./scripts/update-claude-code 2.1.168`）。ビルドに失敗した場合はスクリプトが
> `Dockerfile` を自動で元に戻すため、書き換えだけが残ることはありません。
>
> コンテナ内で `cu` と打つと、このスクリプトの実行方法が表示されます。

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

### 2. コンテナの起動

**VS Code を使う場合:**

1. VS Code でフォルダを開く
2. コマンドパレットから **「Dev Containers: Reopen in Container」** を実行

初回はイメージがビルドされます。`Dockerfile` や `requirements.txt` を変更したあとは
**「Dev Containers: Rebuild Container」** で再ビルドしてください。

**CLI を使う場合:**

```bash
# 起動（初回・変更後はビルドを伴う）
docker compose up --build -d

# コンテナに入る（非root の appuser で入る）
docker compose exec --user appuser app bash

# 停止
docker compose down
```

> `requirements.txt` や `Dockerfile` を変更したときは `docker compose up --build -d` で
> ビルドと起動をまとめて行えます。`requirements.txt` だけを変更した場合は通常 `final` 層のみが
> 再ビルドされます（`Dockerfile` の `tools` 部分を変更した場合は、それ以降の層も再ビルドされます）。

### 3. 各ツールの認証

コンテナ起動後、各ツールのログインコマンドで認証します：

```bash
claude        # Claude Code（Anthropic アカウント）
gemini        # Gemini CLI（Google アカウント）
codex login   # Codex CLI（OpenAI アカウント）
```

認証情報は Docker ボリュームに永続化されるため、コンテナを再起動しても再ログインは不要です。
（ボリュームはプロジェクト名で分かれるため、別プロジェクトでは初回ログインが必要です。）
