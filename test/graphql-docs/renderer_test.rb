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

  def test_that_filename_accessible_to_filters
    @renderer = GraphQLDocs::Renderer.new(@parsed_schema, GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS.merge({
      pipeline_config: {
        pipeline:
          %i(ExtendedMarkdownFilter
             EmojiFilter
             TableOfContentsFilter
             AddFilenameFilter),
        context: {
          gfm: false,
          asset_root: 'https://a248.e.akamai.net/assets.github.com/images/icons'
        }
      }
    }))
    contents = @renderer.render('<span id="fill-me"></span>', type: 'Droid', name: 'R2D2', filename: '/this/is/the/filename')
    assert_match %r{<span id="fill-me">/this/is/the/filename</span>}, contents
  end
end

class AddFilenameFilter < HTML::Pipeline::Filter
  def call
    doc.search('span[@id="fill-me"]').each do |span|
      span.inner_html=(context[:filename])
    end
    doc
  end

  def validate
    needs :filename
  end
end
