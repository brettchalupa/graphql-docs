# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'graphql-docs'

require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/focus'
require 'pry'

def fixtures_dir
  File.join(File.dirname(__FILE__), 'graphql-docs', 'fixtures')
end

FileUtils.rm_rf(File.join(fixtures_dir, 'output'))

class QueryType < GraphQL::Schema::Object
  field :test, Int, "Title paragraph.
  ```
    line1
    line2
        line3
  ```", null: false
end

class MySchema < GraphQL::Schema
  query QueryType
end
