require 'test_helper'

class ParserTest < Minitest::Test
  def setup
    @ghapi = File.read(File.join(fixtures_dir, 'gh-schema.graphql'))
    @swapi = File.read(File.join(fixtures_dir, 'sw-schema.graphql'))
    @parser = GraphQLDocs::Parser.new(@ghapi, {})
    @results = @parser.parse
  end

  def test_types_are_sorted
    names = @results[:object_types].map { |t| t[:name] }
    assert_equal names.sort, names
  end

  def test_connections_are_plucked
    issue = @results[:object_types].find { |t| t[:name] == 'Issue' }
    refute issue[:connections].empty?
  end

  def test_knows_implementers_for_interfaces
    comment = @results[:interface_types].find { |t| t[:name] == 'Comment' }
    refute comment[:implemented_by].empty?
  end

  def test_groups_items_by_type
    assert @results[:input_object_types]
    assert @results[:object_types]
    assert @results[:scalar_types]
    assert @results[:interface_types]
    assert @results[:enum_types]
    assert @results[:union_types]
    assert @results[:mutation_types]
  end

  def test_mutationless_schemas_do_not_explode
    parser = GraphQLDocs::Parser.new(@swapi, {})
    results = parser.parse

    assert_empty results[:mutation_types]
  end

  def test_scalar_inputs_for_mutations_are_supported
    schema = <<-SCHEMA
    type Query {
      foo : ID
    }
    input MessageInput {
      content: String
      author: String
    }
    type Mutation {
      bar(id: ID!, input: MessageInput) : ID
    }
    SCHEMA

    parser = GraphQLDocs::Parser.new(schema, {})
    results = parser.parse

    assert results[:mutation_types]
  end
end
