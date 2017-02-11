require 'test_helper'

class ParserTest < Minitest::Test
  def setup
    @json = File.read("#{fixtures_dir}/gh-api.json")
    @parser = GraphQLDocs::Parser.new(@json)
    results = @parser.parse
    @issue = results['types'].find { |t| t['name'] == 'Issue' }
  end

  def test_types_are_sorted
    names = @parser.parse['types'].map { |t| t['name']}
    assert_equal names.sort, names
  end

  def test_connections_are_plucked
    assert !@issue['connections'].empty?
  end
end
