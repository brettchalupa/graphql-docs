# rubocop:disable Style/FileName
require 'test_helper'

class GraphQLDocsTest < Minitest::Test
  def test_that_it_requires_a_file_or_string
    assert_raises ArgumentError do
      GraphQLDocs.build({})
    end
  end

  def test_it_demands_string_argument
    assert_raises TypeError do
      GraphQLDocs.build(filename: 43)
    end

    assert_raises TypeError do
      GraphQLDocs.build(schema: 43)
    end
  end

  def test_it_needs_a_file_that_exists
    assert_raises ArgumentError do
      GraphQLDocs.build(filename: 'not/a/real/file')
    end
  end

  def test_it_needs_one_or_the_other
    assert_raises ArgumentError do
      GraphQLDocs.build(filename: 'http://graphql.org/swapi-graphql/', schema: File.join(fixtures_dir, 'gh-api.json'))
    end

    assert_raises ArgumentError do
      GraphQLDocs.build
    end
  end
end
