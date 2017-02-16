require 'test_helper'

class ParserTest < Minitest::Test
  def setup
    @json = File.read(File.join(fixtures_dir, 'gh-api.json'))
    @parser = GraphQLDocs::Parser.new(@json, {})
    @results = @parser.parse
    @issue = @results['types'].find { |t| t['name'] == 'Issue' }
  end

  def test_types_are_sorted
    names = @results['types'].map { |t| t['name']}
    assert_equal names.sort, names
  end

  def test_connections_are_plucked
    assert !@issue['connections'].empty?
  end

  def test_groups_items_by_type
    assert @results['input_object_types']
    assert @results['object_types']
    assert @results['scalar_types']
    assert @results['interface_types']
    assert @results['enum_types']
    assert @results['union_types']
  end
end
