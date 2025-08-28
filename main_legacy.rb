# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'date'

NOTION_TOKEN = ENV.fetch('NOTION_TOKEN', nil)
DATABASE_ID = ENV.fetch('NOTION_DATABASE_ID', nil)

# Ruby 2.6対応のNotion API HTTPクライアント
class LegacyNotionApiClient
  API_URL = 'https://api.notion.com/v1/pages'
  API_VERSION = '2022-06-28'

  def initialize(token)
    @token = token
  end

  def create_page(request_body)
    uri = URI(API_URL)
    request = create_http_request(uri, request_body)
    response = execute_http_request(uri, request)
    process_response(response)
  end

  private

  def create_http_request(uri, request_body)
    request = Net::HTTP::Post.new(uri)
    configure_headers(request)
    request.body = JSON.generate(request_body)
    request
  end

  def configure_headers(request)
    request['Authorization'] = "Bearer #{@token}"
    request['Content-Type'] = 'application/json'
    request['Notion-Version'] = API_VERSION
  end

  def execute_http_request(uri, request)
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
  end

  def process_response(response)
    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      handle_error_response(response)
    end
  end

  def handle_error_response(response)
    error_message = parse_error_message(response.body)
    raise "HTTP Error #{response.code}: #{error_message}"
  end

  def parse_error_message(response_body)
    error_body = JSON.parse(response_body)
    error_body['message'] || 'Unknown error'
  rescue JSON::ParserError
    'Unknown error'
  end
end

# 引数文字列を解析してタイトルと気持ちを抽出する（Ruby 2.6対応）
# @param args [String] 引数文字列
# @return [Array<String>] 解析された引数の配列
def parse_arguments_legacy(args)
  # 半角スペースと全角スペースの両方を区切り文字として分割
  # \\s+ は1つ以上の空白文字（半角スペース、タブ、改行など）にマッチ
  # 　+ は1つ以上の全角スペースにマッチ
  args.split(/[\s　]+/)
end

# 解析された引数を検証する（Ruby 2.6対応）
# @param args_array [Array<String>] 解析された引数の配列
# @return [Array<String>] [title, mood] の配列
# @raise [RuntimeError] 引数が不正な場合
def validate_arguments_legacy(args_array)
  # Ruby 2.6対応の引数検証（パターンマッチング不使用）
  raise 'Title and Mood is required' if args_array.empty?

  title = args_array[0]
  raise 'Title is required' if title.nil? || title.empty?

  # 2番目以降の引数を全てmoodとして結合
  mood_parts = args_array[1..]
  raise 'Mood is required' if mood_parts.nil? || mood_parts.empty? || mood_parts.any?(&:empty?)

  mood = mood_parts.join
  [title, mood]
end

# Notionページを作成し、結果を出力する（Ruby 2.6対応）
# @param title [String] ページタイトル
# @param mood [String] 気持ちの内容
def create_notion_page_legacy(title, mood)
  response = send_notion(title, mood)
  puts "Success! Page created with ID: #{response['id']}"
rescue StandardError => e
  # Notion APIからのエラーメッセージを表示
  puts "Failed to create page: #{e.message}"
end

# メイン処理: 引数を解析してNotionにページを作成する
def main(args)
  args_array = parse_arguments_legacy(args)
  title, mood = validate_arguments_legacy(args_array)
  create_notion_page_legacy(title, mood)
end

# Notion APIにページを作成する（Ruby 2.6対応）
# @param title [String] ページタイトル
# @param mood [String] 気持ちの内容
# @return [Hash] APIレスポンス
def send_notion(title, mood)
  client = LegacyNotionApiClient.new(ENV.fetch('NOTION_TOKEN', nil))
  request_body = create_request_body(title, mood)
  client.create_page(request_body)
end

# Notion API用のリクエストボディを作成する
# @param title [String] ページタイトル
# @param mood [String] 気持ちの内容
# @return [Hash] リクエストボディ
def create_request_body(title, mood)
  {
    'parent' => { 'database_id' => ENV.fetch('NOTION_DATABASE_ID', nil) },
    'properties' => {
      'タスク' => {
        'title' => [
          {
            'text' => {
              'content' => title
            }
          }
        ]
      },
      'お気持ち' => {
        'rich_text' => [
          {
            'text' => {
              'content' => mood
            }
          }
        ]
      }
    }
  }
end

# このファイルが直接実行されるときだけmainを実行する。
main(ARGV.join(' ')) if __FILE__ == $PROGRAM_NAME
