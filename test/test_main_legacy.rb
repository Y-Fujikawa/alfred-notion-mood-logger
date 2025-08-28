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
    assert_equal 'Title and Mood is required', error.message
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

  # 新しい複数単語の気持ち機能のテスト (Legacy版)
  def test_main_with_multiple_mood_words
    # Notion APIのモック
    stub_request(:post, 'https://api.notion.com/v1/pages')
      .to_return(
        status: 200,
        body: JSON.generate({ 'id' => 'test_page_id' }),
        headers: { 'Content-Type' => 'application/json' }
      )

    # 複数単語の気持ちでのテスト
    output = capture_io do
      main('プロジェクト完了 とても 疲れた けど やりがい があった')
    end

    assert_match(/Success! Page created with ID: test_page_id/, output[0])
  end

  def test_main_with_mixed_spaces_and_multiple_words
    # Notion APIのモック
    stub_request(:post, 'https://api.notion.com/v1/pages')
      .to_return(
        status: 200,
        body: JSON.generate({ 'id' => 'test_page_id' }),
        headers: { 'Content-Type' => 'application/json' }
      )

    # 全角・半角スペース混在での複数単語テスト
    output = capture_io do
      main('会議　終了 とても　長くて　疲れた　会議　だった')
    end

    assert_match(/Success! Page created with ID: test_page_id/, output[0])
  end

  def test_main_with_empty_mood_parts
    # 空の部分がある場合はエラーになることを確認（タイトルのみで気持ちが空）
    error = assert_raises(RuntimeError) do
      main('タイトル　　　') # 全角スペースのみで気持ち部分が空になる
    end
    assert_equal 'Mood is required', error.message
  end

  def test_backwards_compatibility_two_arguments
    # 既存の2引数での動作が変わらないことを確認
    # Notion APIのモック
    stub_request(:post, 'https://api.notion.com/v1/pages')
      .to_return(
        status: 200,
        body: JSON.generate({ 'id' => 'test_page_id' }),
        headers: { 'Content-Type' => 'application/json' }
      )

    output = capture_io do
      main('タスク完了 満足')
    end

    assert_match(/Success! Page created with ID: test_page_id/, output[0])
  end

  def test_send_notion_with_multiple_mood_words
    # 複数単語の気持ちでのAPI呼び出しテスト
    expected_body = {
      'parent' => { 'database_id' => 'test_database_id' },
      'properties' => {
        'タスク' => {
          'title' => [
            {
              'text' => {
                'content' => 'プロジェクト'
              }
            }
          ]
        },
        'お気持ち' => {
          'rich_text' => [
            {
              'text' => {
                'content' => 'とても疲れたけどやりがいがあった'
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

    result = send_notion('プロジェクト', 'とても疲れたけどやりがいがあった')

    assert_equal 'created_page_id', result['id']
  end

  def test_parse_arguments_legacy_with_multiple_words
    result = parse_arguments_legacy('今日のタスク とても 疲れた 一日 だった')
    expected = %w[今日のタスク とても 疲れた 一日 だった]

    assert_equal expected, result
  end

  def test_parse_arguments_legacy_with_mixed_spaces
    result = parse_arguments_legacy('プロジェクト　完了 とても　疲れた')
    expected = %w[プロジェクト 完了 とても 疲れた]

    assert_equal expected, result
  end

  def test_parse_arguments_legacy_with_basic_input
    result = parse_arguments_legacy('タスク完了 満足')
    expected = %w[タスク完了 満足]

    assert_equal expected, result
  end

  def test_validate_arguments_legacy_with_multiple_mood_words
    args_array = %w[今日のタスク とても 疲れた 一日 だった]
    result = validate_arguments_legacy(args_array)

    assert_equal %w[今日のタスク とても疲れた一日だった], result
  end

  def test_validate_arguments_legacy_with_two_arguments
    args_array = %w[タスク完了 満足]
    result = validate_arguments_legacy(args_array)

    assert_equal %w[タスク完了 満足], result
  end

  def test_validate_arguments_legacy_with_empty_array
    error = assert_raises(RuntimeError) do
      validate_arguments_legacy([])
    end
    assert_equal 'Title and Mood is required', error.message
  end

  def test_validate_arguments_legacy_with_empty_title
    args_array = ['', '気持ち']

    error = assert_raises(RuntimeError) do
      validate_arguments_legacy(args_array)
    end
    assert_equal 'Title is required', error.message
  end

  def test_validate_arguments_legacy_with_missing_mood
    args_array = ['タイトル']

    error = assert_raises(RuntimeError) do
      validate_arguments_legacy(args_array)
    end
    assert_equal 'Mood is required', error.message
  end

  def test_validate_arguments_legacy_with_empty_mood_part
    args_array = ['タイトル', '', '気持ち']

    error = assert_raises(RuntimeError) do
      validate_arguments_legacy(args_array)
    end
    assert_equal 'Mood is required', error.message
  end

  def test_create_notion_page_legacy_success
    # 成功時のテスト - 出力をキャプチャ
    stub_request(:post, 'https://api.notion.com/v1/pages')
      .to_return(
        status: 200,
        body: JSON.generate({ 'id' => 'test_success_id' }),
        headers: { 'Content-Type' => 'application/json' }
      )

    output = capture_io do
      create_notion_page_legacy('テスト', '成功')
    end

    assert_match(/Success! Page created with ID: test_success_id/, output[0])
  end

  def test_create_notion_page_legacy_error
    # エラー時のテスト - 出力をキャプチャ
    stub_request(:post, 'https://api.notion.com/v1/pages')
      .to_return(
        status: 400,
        body: JSON.generate({ 'message' => 'Bad Request' }),
        headers: { 'Content-Type' => 'application/json' }
      )

    output = capture_io do
      create_notion_page_legacy('テスト', 'エラー')
    end

    assert_match(/Failed to create page: HTTP Error 400: Bad Request/, output[0])
  end
end
