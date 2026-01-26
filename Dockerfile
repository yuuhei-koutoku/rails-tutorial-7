FROM ruby:3.2.9

# 必要なパッケージのインストール
# Rails 7 + SQLite3に必要なビルドツールとライブラリ
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libsqlite3-dev \
    vim

# 作業ディレクトリの設定
WORKDIR /app

# ホストのGemfileをコンテナ内にコピー
# (バンドルインストールをキャッシュさせるため、ソースコード全体のコピーより先に行う)
COPY src/Gemfile src/Gemfile.lock /app/

# Gemのインストール
RUN bundle install

# ソースコード全体をコピー
COPY src /app

# サーバー起動コマンド（デフォルト）
# -b 0.0.0.0 はコンテナ外からアクセス可能にするために必須
CMD ["rails", "server", "-b", "0.0.0.0"]
