require 'test_helper'

class RendererTest < Minitest::Test

  def setup
    @swapi = File.read(File.join(fixtures_dir, 'sw-schema.graphql'))
    @parsed_schema = GraphQLDocs::Parser.new(@swapi, {}).parse
    @renderer = GraphQLDocs::Renderer.new(@parsed_schema, GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
  end

  def test_that_rendering_works
    contents = @renderer.render('R2D2', type: 'Droid', name: 'R2D2')

    assert_match %r{<title>R2D2</title>}, contents
  end

  def test_that_html_conversion_works
    contents = @renderer.to_html('**R2D2**')

    assert_equal '<p><strong>R2D2</strong></p>', contents
  end
end
