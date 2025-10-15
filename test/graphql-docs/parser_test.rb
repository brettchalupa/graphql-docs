# frozen_string_literal: true

require "test_helper"

class ParserTest < Minitest::Test
  def setup
    @ghapi = File.read(File.join(fixtures_dir, "gh-schema.graphql"))
    @swapi = File.read(File.join(fixtures_dir, "sw-schema.graphql"))
    @gh_parser = GraphQLDocs::Parser.new(@ghapi, {})
    @gh_results = @gh_parser.parse
  end

  def test_it_accepts_schema_class
    schema = MySchema

    results = GraphQLDocs::Parser.new(schema, {}).parse
    assert_equal "myField", results[:operation_types][0][:fields][0][:name]
    assert_equal "Title paragraph.\n  ```\n    line1\n    line2\n        line3\n  ```", results[:operation_types][0][:fields][0][:description]
  end

  def test_types_are_sorted
    names = @gh_results[:object_types].map { |t| t[:name] }
    assert_equal names.sort, names
  end

  def test_connections_are_plucked
    issue = @gh_results[:object_types].find { |t| t[:name] == "Issue" }
    refute issue[:connections].empty?
  end

  def test_knows_implementers_for_interfaces
    comment = @gh_results[:interface_types].find { |t| t[:name] == "Comment" }
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
    assert_equal %w[deprecated include oneOf preview skip specifiedBy], names

    preview_directive = @gh_results[:directive_types].find { |t| t[:name] == "deprecated" }
    assert_equal %i[FIELD_DEFINITION ENUM_VALUE ARGUMENT_DEFINITION INPUT_FIELD_DEFINITION], preview_directive[:locations]

    assert_equal "Marks an element of a GraphQL schema as no longer supported.", preview_directive[:description]
    reason_arg = preview_directive[:arguments].first
    assert_equal "reason", reason_arg[:name]
    assert_equal "Explains why this element was deprecated, usually also including a suggestion for how to access supported similar data. Formatted in [Markdown](https://daringfireball.net/projects/markdown/).", reason_arg[:description]
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
    assert_equal "The id of the user", user[:fields].first[:description]
  end

  def test_deprecations
    schema = MySchema

    fields = GraphQLDocs::Parser.new(schema, {}).parse[:operation_types][0][:fields]

    refute fields[0][:is_deprecated]
    assert fields[1][:is_deprecated]
    assert fields[2][:arguments][0][:is_deprecated]
  end

  def test_query_field_deprecation
    schema = MySchema
    results = GraphQLDocs::Parser.new(schema, {}).parse

    query_types = results[:query_types]

    # Find the myField query
    my_field = query_types.find { |q| q[:name] == "myField" }
    refute my_field[:is_deprecated], "myField should not be deprecated"
    assert_nil my_field[:deprecation_reason], "myField should not have a deprecation reason"

    # Find the deprecatedField query
    deprecated_field = query_types.find { |q| q[:name] == "deprecatedField" }
    assert deprecated_field[:is_deprecated], "deprecatedField should be marked as deprecated"
    assert_equal "Not useful any more", deprecated_field[:deprecation_reason], "deprecatedField should have correct deprecation reason"

    # Find the fieldWithDeprecatedArg query
    field_with_deprecated_arg = query_types.find { |q| q[:name] == "fieldWithDeprecatedArg" }
    refute field_with_deprecated_arg[:is_deprecated], "fieldWithDeprecatedArg itself should not be deprecated"
    assert field_with_deprecated_arg[:arguments][0][:is_deprecated], "myArg should be marked as deprecated"
    assert_equal "Not useful any more", field_with_deprecated_arg[:arguments][0][:deprecation_reason], "myArg should have correct deprecation reason"
  end

  def test_mutation_field_deprecation
    schema = MySchema
    results = GraphQLDocs::Parser.new(schema, {}).parse

    mutation_types = results[:mutation_types]

    # Find the createUser mutation
    create_user = mutation_types.find { |m| m[:name] == "createUser" }
    refute create_user[:is_deprecated], "createUser should not be deprecated"
    assert_nil create_user[:deprecation_reason], "createUser should not have a deprecation reason"

    # Find the deprecatedMutation
    deprecated_mutation = mutation_types.find { |m| m[:name] == "deprecatedMutation" }
    assert deprecated_mutation[:is_deprecated], "deprecatedMutation should be marked as deprecated"
    assert_equal "Use createUser instead", deprecated_mutation[:deprecation_reason], "deprecatedMutation should have correct deprecation reason"
  end
end
