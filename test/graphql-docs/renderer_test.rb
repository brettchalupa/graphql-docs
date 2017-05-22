require 'test_helper'

class RendererTest < Minitest::Test

  def setup
    @swapi = File.read(File.join(fixtures_dir, 'sw-api.json'))
    @parsed_schema = GraphQLDocs::Parser.new(@swapi, {})
    @renderer = GraphQLDocs::Renderer.new(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS, @parsed_schema)
  end

  def test_that_broken_yaml_is_caught
    broken_file = File.read(File.join(fixtures_dir, 'landing_pages', 'broken_yaml.md'))

    assert_raises TypeError do
      @renderer.render('static', 'broken_yaml', broken_file)
    end
  end

  def test_that_schemas_missing_types_do_not_err
    options = {}
    options[:path] = File.join(fixtures_dir, 'missing-unions-schema.json')

    GraphQLDocs.build(options)
  end
end
