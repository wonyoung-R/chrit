# Chrit - 知識管理サービス

URLを貼り付けるだけで、YouTube動画や記事を自動的に保存・要約するシンプルな知識管理サービスです。

## 主な機能

- 🎯 **ワンクリック保存**: URLを貼り付けるだけで自動処理
- 🎥 **YouTube対応**: 動画の内容を自動で文字起こし・要約
- 📄 **記事対応**: Webページの内容を抽出・要約
- 🤖 **AI要約**: OpenAI APIを使用した自動要約生成
- ⚡ **リアルタイム更新**: Turbo使用によるスムーズなUI

## セットアップ

### 必要な環境

- Ruby 3.2+
- Rails 8.0+
- PostgreSQL 15+
- Redis
- Node.js 18+

### インストール手順

1. リポジトリをクローン
```bash
git clone https://github.com/yourusername/chrit.git
cd chrit
```

2. 依存関係をインストール
```bash
bundle install
```

3. データベースをセットアップ
```bash
rails db:create
rails db:migrate
```

4. 環境変数を設定
```bash
cp .env.example .env
# .envファイルを編集してAPIキーを設定
```

5. 서버 시작
```bash
bin/dev
```

http://localhost:5050 에서 접속할 수 있습니다.

## 環境変数

`.env`ファイルに以下を設定してください：

- `YOUTUBE_API_KEY`: YouTube Data API v3のキー
- `OPENAI_API_KEY`: OpenAI APIキー（要約生成用）
- `REDIS_URL`: Redis接続URL（デフォルト: redis://localhost:6379/1）

## 使い方

1. アカウントを作成してログイン
2. URLを入力欄に貼り付け
3. 自動的に処理が開始
4. 処理完了後、要約を確認

## 技術スタック

- **Backend**: Ruby on Rails 8.0
- **Frontend**: Hotwire (Turbo + Stimulus)
- **Database**: PostgreSQL
- **Background Jobs**: Sidekiq
- **Styling**: Tailwind CSS
- **APIs**: YouTube Data API, OpenAI API

## ライセンス

MIT License
