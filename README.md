# Rails Tutorial 環境構築ガイド (Docker版)

Dockerを使用した `sample_app` の環境構築手順です。

## 前提条件
- Docker Desktop がインストールされ、起動していること。

## 初回セットアップ手順

### 1. DockerイメージのビルドとGemのインストール
まず、指定されたRubyバージョンとGemfileをもとにイメージを作成します。

```bash
docker compose build
```
