# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'date'

# Notion API HTTP クライアント
class NotionApiClient
  API_URL = 'https://api.notion.com/v1/pages'
  API_VERSION = '2022-06-28'

  def initialize(token)
    @token = token
  end

  def create_page(request_data)
    uri = URI(API_URL)
    request = create_http_request(uri, request_data)
    response = execute_request(uri, request)
    handle_response(response)
  end

  private

  def create_http_request(uri, request_data)
    request = Net::HTTP::Post.new(uri)
    configure_request_headers(request)
    request.body = JSON.generate(request_data.to_h)
    request
  end

  def configure_request_headers(request)
    request['Authorization'] = "Bearer #{@token}"
    request['Content-Type'] = 'application/json'
    request['Notion-Version'] = API_VERSION
  end

  def execute_request(uri, request)
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
  end

  def handle_response(response)
    case response
    in Net::HTTPSuccess
      JSON.parse(response.body)
    else
      handle_error_response(response)
    end
  end

  def handle_error_response(response)
    error_body = parse_error_body(response.body)
    raise "HTTP Error #{response.code}: #{error_body['message']}"
  end

  def parse_error_body(body)
    JSON.parse(body)
  rescue StandardError
    { 'message' => 'Unknown error' }
  end
end

# Ruby 3.2+ Data classを使用してAPIの構造を型安全に定義
NotionPageRequest = Data.define(:parent, :properties) do
  def self.create(database_id, title, mood)
    new(
      parent: { 'database_id' => database_id },
      properties: {
        'タスク' => {
          'title' => [{
            'text' => { 'content' => title }
          }]
        },
        'お気持ち' => {
          'rich_text' => [{
            'text' => { 'content' => mood }
          }]
        }
      }
    )
  end

  def to_h
    { 'parent' => parent, 'properties' => properties }
  end
end

NotionApiResponse = Data.define(:id, :status) do
  def self.from_response(response_body)
    parsed = JSON.parse(response_body)
    new(id: parsed['id'], status: :success)
  rescue JSON::ParserError
    new(id: nil, status: :error)
  end
end

NOTION_TOKEN = ENV.fetch('NOTION_TOKEN', nil)
DATABASE_ID = ENV.fetch('NOTION_DATABASE_ID', nil)

# メイン処理: 引数を解析してNotionにページを作成する
def main(args)
  # 半角スペースと全角スペースの両方を区切り文字として分割
  # \s+ は1つ以上の空白文字（半角スペース、タブ、改行など）にマッチ
  # 　+ は1つ以上の全角スペースにマッチ
  args_array = args.split(/[\s　]+/)

  # パターンマッチングで引数の検証を行う
  case args_array
  in [String => title, String => mood, *] if !title.empty? && !mood.empty?
    # 正常なケース - そのまま処理を続行
  in [String => title, *] if title.empty?
    raise 'Title is required'
  in [String, *]
    raise 'Mood is required'
  in []
    raise 'Both title and mood are required'
  else
    raise 'Invalid arguments'
  end

  begin
    response = send_notion(title, mood)
    puts "Success! Page created with ID: #{response['id']}"
  rescue StandardError => e
    # Notion APIからのエラーメッセージを表示
    puts "Failed to create page: #{e.message}"
  end
end

# Notion APIにページを作成する
# @param title [String] ページタイトル
# @param mood [String] 気持ちの内容
# @return [Hash] APIレスポンス
def send_notion(title, mood)
  client = NotionApiClient.new(NOTION_TOKEN)
  request_data = NotionPageRequest.create(DATABASE_ID, title, mood)
  client.create_page(request_data)
end

# このメソッドはData classのNotionPageRequestに置き換えられました
# 後方互換性のために残していますが、非推奨です
def create_request_body(title, mood)
  NotionPageRequest.create(DATABASE_ID, title, mood).to_h
end

# このファイルが直接実行されるときだけmainを実行する。
main(ARGV.join(' ')) if __FILE__ == $PROGRAM_NAME
