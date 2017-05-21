# rubocop:disable Style/FileName
require 'test_helper'

class GraphQLDocsTest < Minitest::Test
  def test_that_it_requires_a_file_or_url
    assert_raises ArgumentError do
      GraphQLDocs.build({})
    end
  end

  def test_that_it_does_not_require_a_file_and_a_url
    assert_raises ArgumentError do
      GraphQLDocs.build(url: 'http://graphql.org/swapi-graphql/', path: File.join(fixtures_dir, 'gh-api.json'))
    end
  end
end
