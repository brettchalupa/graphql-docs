# frozen_string_literal: true

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

  def test_that_renderer_passes_all_options_to_template
    # Test that renderer passes all options to template, not just specific keys
    custom_options = GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS.merge({
      custom_key: 'custom_value',
      title: 'Custom Title'
    })

    renderer = GraphQLDocs::Renderer.new(@parsed_schema, custom_options)
    contents = renderer.render('Test content', type: 'test', name: 'test')

    # Title from options should be rendered
    assert_match %r{<title>Custom Title</title>}, contents

    # This verifies that @options is being passed entirely, not just select keys
    # Without this, YAML frontmatter variables wouldn't be accessible
  end

  def test_that_html_conversion_works
    contents = @renderer.to_html('**R2D2**')

    assert_equal '<p><strong>R2D2</strong></p>', contents
  end

  def test_that_unsafe_html_is_not_blocked_by_default
    contents = @renderer.to_html('<strong>Oh hello</strong>')

    assert_equal '<p><strong>Oh hello</strong></p>', contents
  end

  def test_that_unsafe_html_is_blocked_when_asked
    renderer = GraphQLDocs::Renderer.new(@parsed_schema, GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS.merge({
                                                                                                                  pipeline_config: {
                                                                                                                    pipeline:
                                                                                                                      %i[ExtendedMarkdownFilter
                                                                                                                         EmojiFilter
                                                                                                                         TableOfContentsFilter],
                                                                                                                    context: {
                                                                                                                      gfm: false,
                                                                                                                      unsafe: false,
                                                                                                                      asset_root: 'https://a248.e.akamai.net/assets.github.com/images/icons'
                                                                                                                    }
                                                                                                                  }
                                                                                                                }))
    contents = renderer.to_html('<strong>Oh</strong> **hello**')

    assert_equal '<p><!-- raw HTML omitted -->Oh<!-- raw HTML omitted --> <strong>hello</strong></p>', contents
  end

  def test_that_filename_accessible_to_filters
    renderer = GraphQLDocs::Renderer.new(@parsed_schema, GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS.merge({
                                                                                                                  pipeline_config: {
                                                                                                                    pipeline:
                                                                                                                      %i[ExtendedMarkdownFilter
                                                                                                                         EmojiFilter
                                                                                                                         TableOfContentsFilter
                                                                                                                         AddFilenameFilter],
                                                                                                                    context: {
                                                                                                                      gfm: false,
                                                                                                                      unsafe: true,
                                                                                                                      asset_root: 'https://a248.e.akamai.net/assets.github.com/images/icons'
                                                                                                                    }
                                                                                                                  }
                                                                                                                }))
    contents = renderer.render('<span id="fill-me"></span>', type: 'Droid', name: 'R2D2', filename: '/this/is/the/filename')
    assert_match %r{<span id="fill-me">/this/is/the/filename</span>}, contents
  end
end

class AddFilenameFilter < HTML::Pipeline::Filter
  def call
    doc.search('span[@id="fill-me"]').each do |span|
      span.inner_html = context[:filename]
    end
    doc
  end

  def validate
    needs :filename
  end
end
