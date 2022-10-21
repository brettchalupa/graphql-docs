# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'graphql-docs'

require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/focus'

def fixtures_dir
  File.join(File.dirname(__FILE__), 'graphql-docs', 'fixtures')
end

def output_dir
  File.join(fixtures_dir, 'output')
end
def clean_up_output
  FileUtils.rm_rf(output_dir)
end
clean_up_output

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
