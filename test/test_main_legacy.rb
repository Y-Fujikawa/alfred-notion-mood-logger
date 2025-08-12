# frozen_string_literal: true

require 'minitest/autorun'
require 'webmock/minitest'
require 'json'
require_relative '../main_legacy'

class TestMainLegacy < Minitest::Test
  def setup
    # 環境変数のセットアップ
    ENV['NOTION_TOKEN'] = 'test_token'
    ENV['NOTION_DATABASE_ID'] = 'test_database_id'

    # WebMockを有効にして外部APIコールをモック
    WebMock.enable!
  end

  def teardown
    WebMock.disable!
  end

  def test_create_request_body
    title = 'テストタイトル'
    mood = '楽しい'

    result = create_request_body(title, mood)

    expected = {
      'parent' => { 'database_id' => 'test_database_id' },
      'properties' => {
        'タスク' => {
          'title' => [
            {
              'text' => {
                'content' => 'テストタイトル'
              }
            }
          ]
        },
        'お気持ち' => {
          'rich_text' => [
            {
              'text' => {
                'content' => '楽しい'
              }
            }
          ]
        }
      }
    }

    assert_equal expected, result
  end

  def test_main_with_valid_args
    # Notion APIのモック
    stub_request(:post, 'https://api.notion.com/v1/pages')
      .to_return(
        status: 200,
        body: JSON.generate({ 'id' => 'test_page_id' }),
        headers: { 'Content-Type' => 'application/json' }
      )

    # 標準出力をキャプチャ
    output = capture_io do
      main('テストタイトル 楽しい')
    end

    assert_match(/Success! Page created with ID: test_page_id/, output[0])
  end

  def test_main_with_missing_title
    error = assert_raises(RuntimeError) do
      main('')
    end
    assert_equal 'Title is required', error.message
  end

  def test_main_with_missing_mood
    error = assert_raises(RuntimeError) do
      main('タイトル')
    end
    assert_equal 'Mood is required', error.message
  end

  def test_main_with_full_width_space
    # Notion APIのモック
    stub_request(:post, 'https://api.notion.com/v1/pages')
      .to_return(
        status: 200,
        body: JSON.generate({ 'id' => 'test_page_id' }),
        headers: { 'Content-Type' => 'application/json' }
      )

    # 全角スペースでの区切りテスト
    output = capture_io do
      main('テストタイトル　楽しい')
    end

    assert_match(/Success! Page created with ID: test_page_id/, output[0])
  end

  def test_send_notion_success
    # 成功レスポンスのモック
    expected_body = {
      'parent' => { 'database_id' => 'test_database_id' },
      'properties' => {
        'タスク' => {
          'title' => [
            {
              'text' => {
                'content' => 'テスト'
              }
            }
          ]
        },
        'お気持ち' => {
          'rich_text' => [
            {
              'text' => {
                'content' => '気持ち'
              }
            }
          ]
        }
      }
    }

    stub_request(:post, 'https://api.notion.com/v1/pages')
      .with(
        headers: {
          'Authorization' => 'Bearer test_token',
          'Content-Type' => 'application/json',
          'Notion-Version' => '2022-06-28'
        },
        body: JSON.generate(expected_body)
      )
      .to_return(
        status: 200,
        body: JSON.generate({ 'id' => 'created_page_id' }),
        headers: { 'Content-Type' => 'application/json' }
      )

    result = send_notion('テスト', '気持ち')

    assert_equal 'created_page_id', result['id']
  end

  def test_send_notion_error
    # エラーレスポンスのモック
    stub_request(:post, 'https://api.notion.com/v1/pages')
      .to_return(
        status: 400,
        body: JSON.generate({ 'message' => 'Invalid request' }),
        headers: { 'Content-Type' => 'application/json' }
      )

    error = assert_raises(RuntimeError) do
      send_notion('テスト', '気持ち')
    end
    assert_match(/HTTP Error 400: Invalid request/, error.message)
  end

  def test_send_notion_error_with_invalid_json
    # 無効なJSONレスポンスのモック
    stub_request(:post, 'https://api.notion.com/v1/pages')
      .to_return(
        status: 500,
        body: 'Internal Server Error',
        headers: { 'Content-Type' => 'text/html' }
      )

    error = assert_raises(RuntimeError) do
      send_notion('テスト', '気持ち')
    end
    assert_match(/HTTP Error 500: Unknown error/, error.message)
  end

  def test_main_handles_api_error
    # エラーレスポンスのモック
    stub_request(:post, 'https://api.notion.com/v1/pages')
      .to_return(
        status: 401,
        body: JSON.generate({ 'message' => 'Unauthorized' }),
        headers: { 'Content-Type' => 'application/json' }
      )

    # 標準出力をキャプチャ
    output = capture_io do
      main('テストタイトル 楽しい')
    end

    assert_match(/Failed to create page: HTTP Error 401: Unauthorized/, output[0])
  end
end
