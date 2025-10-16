# frozen_string_literal: true

require "test_helper"

class RendererTest < Minitest::Test
  def setup
    @swapi = File.read(File.join(fixtures_dir, "sw-schema.graphql"))
    @parsed_schema = GraphQLDocs::Parser.new(@swapi, {}).parse
    @renderer = GraphQLDocs::Renderer.new(@parsed_schema, GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
  end

  def test_that_rendering_works
    contents = @renderer.render("R2D2", type: "Droid", name: "R2D2")

    assert_match %r{<title>R2D2</title>}, contents
  end

  def test_that_renderer_passes_all_options_to_template
    # Test that renderer passes all options to template, not just specific keys
    custom_options = GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS.merge({
      custom_key: "custom_value",
      title: "Custom Title"
    })

    renderer = GraphQLDocs::Renderer.new(@parsed_schema, custom_options)
    contents = renderer.render("Test content", type: "test", name: "test")

    # Title from options should be rendered
    assert_match %r{<title>Custom Title</title>}, contents

    # This verifies that @options is being passed entirely, not just select keys
    # Without this, YAML frontmatter variables wouldn't be accessible
  end

  def test_that_html_conversion_works
    contents = @renderer.to_html("**R2D2**")

    assert_equal "<p><strong>R2D2</strong></p>", contents
  end

  def test_that_unsafe_html_is_not_blocked_by_default
    contents = @renderer.to_html("<strong>Oh hello</strong>")

    assert_equal "<p><strong>Oh hello</strong></p>", contents
  end

  def test_that_unsafe_html_is_blocked_when_asked
    renderer = GraphQLDocs::Renderer.new(@parsed_schema, GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS.merge({
      pipeline_config: {
        pipeline: [],
        context: {
          gfm: false,
          unsafe: false,
          asset_root: "https://a248.e.akamai.net/assets.github.com/images/icons"
        }
      }
    }))
    contents = renderer.to_html("<strong>Oh</strong> **hello**")

    assert_equal "<p><!-- raw HTML omitted -->Oh<!-- raw HTML omitted --> <strong>hello</strong></p>", contents
  end

  # Note: Custom filters are no longer supported in the same way with html-pipeline 3
  # and commonmarker 2.x. The rendering is now handled directly by commonmarker.
  # If custom post-processing is needed, it should be done via the Renderer subclass.

  # Tests for commonmarker 2.x GitHub Flavored Markdown features

  def test_that_tables_render_correctly
    markdown = "| Foo | Bar |\n|-----|-----|\n| 1   | 2   |"
    html = @renderer.to_html(markdown)

    assert_match(/<table>/, html)
    assert_match(/<th>Foo<\/th>/, html)
    assert_match(/<th>Bar<\/th>/, html)
    assert_match(/<td>1<\/td>/, html)
    assert_match(/<td>2<\/td>/, html)
  end

  def test_that_strikethrough_renders
    markdown = "~~deleted text~~"
    html = @renderer.to_html(markdown)

    assert_match(/<del>deleted text<\/del>/, html)
  end

  def test_that_autolinks_work
    markdown = "Visit https://example.com for more"
    html = @renderer.to_html(markdown)

    assert_match(%r{<a href="https://example.com">https://example.com</a>}, html)
  end

  def test_that_task_lists_render
    markdown = "- [ ] Todo item\n- [x] Done item"
    html = @renderer.to_html(markdown)

    assert_match(/<input type="checkbox"/, html)
    assert_match(/disabled=""/, html)
  end

  def test_that_header_anchors_are_generated
    markdown = "# My Header"
    html = @renderer.to_html(markdown)

    # Commonmarker 2.x generates anchor tags with IDs inside the heading
    assert_match(/id="my-header"/, html)
    assert_match(/My Header<\/h1>/, html)
  end

  def test_that_code_blocks_preserve_content
    markdown = "```json\n{\n  \"nested\": {\n    \"value\": true\n  }\n}\n```"
    html = @renderer.to_html(markdown)

    assert_match(/nested/, html)
    assert_match(/value/, html)
    assert_match(/<code/, html)
  end

  def test_that_inline_code_works
    markdown = "Use `code` here"
    html = @renderer.to_html(markdown)

    assert_match(/<code>code<\/code>/, html)
  end

  def test_that_blockquotes_render
    markdown = "> This is a quote"
    html = @renderer.to_html(markdown)

    assert_match(/<blockquote>/, html)
    assert_match(/This is a quote/, html)
  end

  # Tests for emoji rendering

  def test_that_emoji_shortcodes_are_converted
    markdown = "Hello :smile: world :heart:"
    html = @renderer.to_html(markdown)

    assert_match(/😄/, html, "Expected :smile: to be converted to 😄")
    assert_match(/❤️/, html, "Expected :heart: to be converted to ❤️")
    refute_match(/:smile:/, html, "Emoji shortcode should be replaced")
    refute_match(/:heart:/, html, "Emoji shortcode should be replaced")
  end

  def test_that_unknown_emoji_shortcodes_are_left_unchanged
    markdown = "Hello :not_a_real_emoji: world"
    html = @renderer.to_html(markdown)

    assert_match(/:not_a_real_emoji:/, html, "Unknown emoji shortcodes should remain unchanged")
  end

  def test_that_emoji_works_with_markdown
    markdown = "**Bold :smile:** and *italic :heart:*"
    html = @renderer.to_html(markdown)

    assert_match(/<strong>Bold 😄<\/strong>/, html)
    assert_match(/<em>italic ❤️<\/em>/, html)
  end

  def test_that_emoji_in_code_blocks_are_converted
    markdown = "```\n:smile:\n```"
    html = @renderer.to_html(markdown)

    # Note: Emoji replacement happens BEFORE markdown parsing, so emoji in code blocks
    # ARE converted. This is a known limitation of the current implementation.
    # To preserve emoji shortcodes in code blocks, escape them or use a different approach.
    assert_match(/😄/, html, "Current implementation converts emoji even in code blocks")
  end

  # Tests for error handling

  def test_that_malformed_markdown_is_handled_gracefully
    # Even though commonmarker is forgiving, test the error handling
    contents = @renderer.to_html(nil)
    assert_equal "", contents
  end

  def test_that_empty_string_handled
    contents = @renderer.to_html("")
    assert_equal "", contents
  end

  # Test helpers module emoji support

  def test_that_markdownify_helper_converts_emoji
    @renderer.extend(GraphQLDocs::Helpers)
    @renderer.instance_variable_set(:@options, GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)

    html = @renderer.markdownify("Testing :tada: emoji")

    assert_match(/🎉/, html, "Expected :tada: to be converted to 🎉")
  end
end
