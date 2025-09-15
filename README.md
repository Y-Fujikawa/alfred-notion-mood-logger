# Alfred Notion Mood Logger

Notionデータベースに気持ちやタスクを記録するためのRubyスクリプトです。タイトルと気持ちを引数として受け取り、Notion APIを使用してページを作成します。

## 機能

- Notion APIを使用してデータベースにページを作成
- タイトルと気持ちを記録
- 半角・全角スペースの両方に対応した引数解析
- エラーハンドリング機能

## ファイル構成

### `main.rb` (モダン版)
- Ruby 3.4.5以上（Ruby 3.0+の機能を使用）
- パターンマッチング、Data class等の新機能を活用

### `main_legacy.rb` (レガシー版)
- Ruby 2.6.10以上（macOSデフォルト対応）
- 従来の構文で記述、古いRubyでも動作

## 必要要件

### モダン版 (main.rb)
- Ruby 3.4.5以上（Ruby 3.0+の機能を使用）
- 以下のgemが必要です：
  - net/http（標準ライブラリ）
  - uri（標準ライブラリ）
  - json（標準ライブラリ）
  - date（標準ライブラリ）

#### Ruby機能要件
- パターンマッチング（Ruby 3.0+）
- Data class（Ruby 3.2+）

### レガシー版 (main_legacy.rb)
- Ruby 2.6.10以上（macOSシステムRuby対応）
- 標準ライブラリのみ使用（追加gemなし）

## 環境変数の設定

### セキュリティ注意事項
⚠️ **重要**: Notion APIトークンは機密情報です。以下の点にご注意ください：
- `.env`ファイルは絶対にGitリポジトリにコミットしないでください
- 環境変数やトークンをコードに直接書き込まないでください
- 本番環境では適切な権限管理を行ってください

### 設定方法

#### 方法1: .envファイルを使用（推奨）
1. `.env.example`をコピーして`.env`ファイルを作成：
```bash
cp .env.example .env
```

2. `.env`ファイルを編集して実際の値を設定：
```bash
# Notion API Token
NOTION_TOKEN=secret_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Notion Database ID  
NOTION_DATABASE_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

#### 方法2: 環境変数を直接設定
```bash
export NOTION_TOKEN="your_notion_token"
export NOTION_DATABASE_ID="your_database_id"
```

### トークンの取得方法
1. [Notion My Integrations](https://www.notion.so/my-integrations) でインテグレーションを作成
2. 生成されたトークンをコピー
3. データベースをインテグレーションと共有
4. データベースのIDを取得（URLから確認可能）

## 使用方法

### 1. 単体での実行

#### モダン版 (Ruby 3.4.5+)
```bash
ruby main.rb "タスクのタイトル" "気持ち"
```

#### レガシー版 (macOSシステムRuby 2.6.10)
```bash
ruby main_legacy.rb "タスクのタイトル" "気持ち"
# または
/usr/bin/ruby main_legacy.rb "タスクのタイトル" "気持ち"
```

### 2. Alfred Workflowでの使用

Alfred Workflowに設定して使用することも可能です。Workflowのスクリプトフィルターやアクションとして組み込むことで、Alfredから直接Notionにデータを記録できます。

macOSデフォルト環境では`main_legacy.rb`の使用を推奨します。

### 例

```bash
# モダン版
ruby main.rb "今日の作業" "楽しい"
ruby main.rb "プロジェクト完了" "達成感がある"

# レガシー版
ruby main_legacy.rb "今日の作業" "楽しい"
ruby main_legacy.rb "プロジェクト完了" "達成感がある"
```

## Notionデータベースの設定

スクリプトが動作するためには、Notionデータベースに以下のプロパティが必要です：

- `タスク`（Title型）
- `お気持ち`（Rich text型）

## コード品質

### RuboCop
コードスタイルチェックにRubocopを使用しています。

```bash
# スタイルチェック実行
bundle exec rubocop

# 自動修正（可能な違反のみ）
bundle exec rubocop --auto-correct
```

## テスト

### モダン版のテスト
テストファイル（`test/test_main.rb`）が含まれています。以下のgemが必要です：

- minitest
- webmock

テストの実行：
```bash
bundle exec rake test
```

### レガシー版のテスト
2つのテストファイルが用意されています：

#### フル機能版（`test/test_main_legacy.rb`）
- WebMockを使用した完全なAPIモックテスト
- minitest、webmockが必要

```bash
ruby test/test_main_legacy.rb
```

#### シンプル版（`test/test_main_legacy_simple.rb`）
- 外部依存なし、macOSシステムRubyで動作
- minitestのみ使用

```bash
# macOSシステムRubyでの実行
/usr/bin/ruby test/test_main_legacy_simple.rb
```

## エラーハンドリング

- タイトルまたは気持ちが空の場合はエラーメッセージを表示
- Notion APIからのエラーレスポンスを適切に処理
- HTTP エラーコードとメッセージを表示

## 実装詳細

### メイン関数

`main(args)` - 引数を解析してNotionにページを作成

### API送信関数

`send_notion(title, mood, method)` - Notion APIへHTTPリクエストを送信

### リクエストボディ作成

`create_request_body(title, mood)` - Notion API用のJSONリクエストボディを生成
