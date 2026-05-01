# Railsチュートリアル 学習用リポジトリ

Railsチュートリアルの学習用アプリ（`sample_app`）を、Dockerを用いてローカル開発できるようにしたリポジトリ。

## Railsチュートリアル リンク

- [Ruby on Railsチュートリアル](https://railstutorial.jp)
- [Rails チュートリアル sample_app コード集](https://github.com/yasslab/sample_apps/tree/main)

## 動作環境 / 前提

- Docker Desktop がインストールされ、起動していること

## 構成（重要）

- Railsアプリ本体: `src/`
- Dockerイメージ定義: `Dockerfile`
- 開発用Compose: `docker-compose.yml`
  - `./src` をコンテナの `/app` にマウント（ローカル編集が即反映）
  - Bundlerのインストール先を `bundle_data` ボリュームに永続化
  - `tmp/pids/server.pid` を削除してから `rails s -b 0.0.0.0` を起動

## クイックスタート（初回）

```bash
docker compose build
docker compose up -d
docker compose exec app bin/rails db:prepare
```

ブラウザで `http://localhost:3000` にアクセス。

## よく使うコマンド

### サーバー起動 / 停止

```bash
docker compose up
```

```bash
docker compose down
```

### Railsコマンドの実行（例）

```bash
docker compose exec app bin/rails routes
docker compose exec app bin/rails console
docker compose exec app bin/rails db:migrate
```

### ローカルDBへ接続

開発環境（`development`）は SQLite を使用。（`src/config/database.yml` 参照）

```bash
docker compose exec app bin/rails dbconsole
```

SQLiteを直接開く場合。

```bash
docker compose exec app sqlite3 db/development.sqlite3
```

### テスト

Minitestを実行。

```bash
docker compose exec app bin/rails test
```

テストを自動実行。（Guardを起動）

```bash
docker compose exec app bin/bundle exec guard
```

## トラブルシュート

### `A server is already running. Check tmp/pids/server.pid.`

このリポジトリのCompose設定は起動時に `tmp/pids/server.pid` を削除するが、手動で起動方法を変えた場合などに残ることがある。

```bash
docker compose exec app rm -f tmp/pids/server.pid
```

### Bundler周りの不整合が出る

```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```
