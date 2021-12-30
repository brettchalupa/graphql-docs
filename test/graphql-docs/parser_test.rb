# frozen_string_literal: true

require 'test_helper'

class ParserTest < Minitest::Test
  def setup
    @ghapi = File.read(File.join(fixtures_dir, 'gh-schema.graphql'))
    @swapi = File.read(File.join(fixtures_dir, 'sw-schema.graphql'))
    @gh_parser = GraphQLDocs::Parser.new(@ghapi, {})
    @gh_results = @gh_parser.parse
  end

  def test_it_accepts_schema_class
    schema = MySchema

    results = GraphQLDocs::Parser.new(schema, {}).parse
    assert_equal 'test', results[:operation_types][0][:fields][0][:name]
    assert_equal "Title paragraph.\n  ```\n    line1\n    line2\n        line3\n  ```", results[:operation_types][0][:fields][0][:description]
  end

  def test_types_are_sorted
    names = @gh_results[:object_types].map { |t| t[:name] }
    assert_equal names.sort, names
  end

  def test_connections_are_plucked
    issue = @gh_results[:object_types].find { |t| t[:name] == 'Issue' }
    refute issue[:connections].empty?
  end

  def test_knows_implementers_for_interfaces
    comment = @gh_results[:interface_types].find { |t| t[:name] == 'Comment' }
    refute comment[:implemented_by].empty?
  end

  def test_groups_items_by_type
    assert @gh_results[:input_object_types]
    assert @gh_results[:object_types]
    assert @gh_results[:scalar_types]
    assert @gh_results[:interface_types]
    assert @gh_results[:enum_types]
    assert @gh_results[:union_types]
    assert @gh_results[:mutation_types]
    assert @gh_results[:directive_types]
  end

  def test_directives
    names = @gh_results[:directive_types].map { |t| t[:name] }
    assert_equal %w[deprecated include preview skip], names

    preview_directive = @gh_results[:directive_types].find { |t| t[:name] == 'deprecated' }
    assert_equal %i[FIELD_DEFINITION ENUM_VALUE ARGUMENT_DEFINITION INPUT_FIELD_DEFINITION], preview_directive[:locations]

    assert_equal 'Marks an element of a GraphQL schema as no longer supported.', preview_directive[:description]
    reason_arg = preview_directive[:arguments].first
    assert_equal 'reason', reason_arg[:name]
    assert_equal 'Explains why this element was deprecated, usually also including a suggestion for how to access supported similar data. Formatted in [Markdown](https://daringfireball.net/projects/markdown/).', reason_arg[:description]
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

  def test_schemas_with_quote_style_comments_works
    schema = <<-SCHEMA
    type Query {
      profile: User
    }

    """
    A user
    """
    type User {
      """
      The id of the user
      """
      id: String!

      """
      The email of user
      """
      email: String
    }
    SCHEMA

    parser = GraphQLDocs::Parser.new(schema, {})

    results = parser.parse
    assert results[:object_types]
    user = results[:object_types].first
    assert_equal 'The id of the user', user[:fields].first[:description]
  end
end
