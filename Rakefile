# frozen_string_literal: true

require 'rake/testtask'

task default: [:test]

Rake::TestTask.new do |test|
  test.test_files = Dir['test/**/test_main.rb']
  test.verbose = true
end
