# frozen_string_literal: true

require 'minitest/autorun'
require 'json'
require_relative '../main_legacy'

class TestMainLegacySimple < Minitest::Test
  def setup
    # 環境変数のセットアップ
    ENV['NOTION_TOKEN'] = 'test_token'
    ENV['NOTION_DATABASE_ID'] = 'test_database_id'
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

  def test_argument_parsing_with_spaces
    # 引数の解析テスト（実際のAPI呼び出しなし）
    args = 'テストタイトル 楽しい'
    args_array = args.split(/[\s　]+/)

    assert_equal 'テストタイトル', args_array[0]
    assert_equal '楽しい', args_array[1]
  end

  def test_argument_parsing_with_full_width_space
    # 全角スペースでの引数解析テスト
    args = 'テストタイトル　楽しい'
    args_array = args.split(/[\s　]+/)

    assert_equal 'テストタイトル', args_array[0]
    assert_equal '楽しい', args_array[1]
  end

  def test_json_generation
    # JSONの生成テスト
    data = create_request_body('テスト', '気持ち')
    json_string = JSON.generate(data)

    assert_instance_of String, json_string
    refute_empty json_string

    # JSONとして再パース可能か確認
    parsed = JSON.parse(json_string)

    assert_equal data, parsed
  end
end
