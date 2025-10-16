# frozen_string_literal: true

require "test_helper"

class GeneratorTest < Minitest::Test
  class CustomRenderer
    def initialize(_, _)
    end

    def render(contents, type: nil, name: nil, filename: nil) # rubocop:disable Lint/UnusedMethodArgument
      to_html(contents)
    end

    def to_html(contents)
      return "" if contents.nil?

      contents.sub(/CodeOfConduct/i, "CoC!!!!!")
    end
  end

  def setup
    schema = File.read(File.join(fixtures_dir, "gh-schema.graphql"))
    @parser = GraphQLDocs::Parser.new(schema, {})
    @results = @parser.parse

    tiny_schema = File.read(File.join(fixtures_dir, "tiny-schema.graphql"))
    @tiny_parser = GraphQLDocs::Parser.new(tiny_schema, {})
    @tiny_results = @tiny_parser.parse

    @output_dir = File.join(fixtures_dir, "output")
  end

  def deep_copy(hash)
    Marshal.load(Marshal.dump(hash))
  end

  def test_that_it_requires_templates
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:templates][:objects] = "BOGUS"

    assert_raises IOError do
      GraphQLDocs::Generator.new(@results, options)
    end
  end

  def test_that_it_does_not_require_default
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:templates][:default] = nil

    GraphQLDocs::Generator.new(@results, options)
  end

  def test_that_it_works
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:output_dir] = @output_dir
    options[:delete_output] = true

    generator = GraphQLDocs::Generator.new(@results, options)
    generator.generate

    assert File.exist? File.join(@output_dir, "index.html")
    assert File.exist? File.join(@output_dir, "assets", "style.css")
    assert File.exist? File.join(@output_dir, "enum", "issuestate", "index.html")
    assert File.exist? File.join(@output_dir, "input_object", "projectorder", "index.html")
    assert File.exist? File.join(@output_dir, "interface", "reactable", "index.html")
    assert File.exist? File.join(@output_dir, "query", "codeofconduct", "index.html")
    assert File.exist? File.join(@output_dir, "mutation", "addcomment", "index.html")
    assert File.exist? File.join(@output_dir, "object", "repository", "index.html")
    assert File.exist? File.join(@output_dir, "scalar", "boolean", "index.html")
    assert File.exist? File.join(@output_dir, "union", "issuetimelineitem", "index.html")
    assert File.exist? File.join(@output_dir, "directive", "deprecated", "index.html")

    # content sanity checks
    Dir.glob("#{@output_dir}/**/*.html") do |file|
      contents = File.read(file)
      # no empty types
      refute_match %r{<code></code>}, contents
    end
  end

  def test_that_turning_off_styles_works
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:output_dir] = @output_dir
    options[:delete_output] = true
    options[:use_default_styles] = false

    generator = GraphQLDocs::Generator.new(@tiny_results, options)
    generator.generate

    refute File.exist? File.join(@output_dir, "assets", "style.css")
  end

  def test_that_setting_base_url_works
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:output_dir] = @output_dir
    options[:delete_output] = true
    options[:base_url] = "wowzers"

    generator = GraphQLDocs::Generator.new(@tiny_results, options)
    generator.generate

    contents = File.read File.join(@output_dir, "index.html")
    assert_match %r{<link rel="stylesheet" href="wowzers/assets/style.css">}, contents

    contents = File.read File.join(@output_dir, "object", "codeofconduct", "index.html")
    assert_match %r{href="wowzers/object/codeofconduct/"}, contents
  end

  def test_that_custom_renderer_can_be_used
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:output_dir] = @output_dir

    options[:renderer] = CustomRenderer

    generator = GraphQLDocs::Generator.new(@tiny_results, options)
    generator.generate

    contents = File.read(File.join(@output_dir, "object", "codeofconduct", "index.html"))

    assert_match(/CoC!!!!!/, contents)
  end

  def test_that_it_sets_classes
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:output_dir] = @output_dir
    options[:delete_output] = true
    options[:classes][:field_entry] = "my-4"

    generator = GraphQLDocs::Generator.new(@tiny_results, options)
    generator.generate

    object = File.read File.join(@output_dir, "object", "codeofconduct", "index.html")

    assert_match(/<div class="field-entry my-4">/, object)
  end

  def test_that_missing_landing_pages_are_reported
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:landing_pages][:index] = "BOGUS"

    assert_raises IOError do
      GraphQLDocs::Generator.new(@tiny_results, options)
    end
  end

  def test_that_erb_landing_pages_work
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:output_dir] = @output_dir
    options[:landing_pages][:object] = File.join(fixtures_dir, "landing_pages", "object.erb")
    options[:landing_pages][:variables] = {some_var: "wowie!!"}

    generator = GraphQLDocs::Generator.new(@tiny_results, options)
    generator.generate

    object = File.read File.join(@output_dir, "object", "index.html")

    assert_match(/Variable Objects/, object)
    assert_match(/wowie!!/, object)
  end

  def test_that_broken_yaml_is_caught
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:landing_pages][:index] = File.join(fixtures_dir, "landing_pages", "broken_yaml.md")
    generator = GraphQLDocs::Generator.new(@tiny_results, options)

    assert_raises TypeError do
      generator.generate
    end
  end

  def test_that_markdown_preserves_whitespace
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:output_dir] = @output_dir
    options[:landing_pages][:index] = File.join(fixtures_dir, "landing_pages", "whitespace_template.md")

    generator = GraphQLDocs::Generator.new(@tiny_results, options)
    generator.generate

    contents = File.read File.join(@output_dir, "index.html")

    # Commonmarker 2.x wraps code in <pre><code> but preserves whitespace structure
    # Check that the nested structure is maintained
    assert_match(/nest2/, contents, "Expected 'nest2' to be present in output")
    assert_match(/nest3/, contents, "Expected 'nest3' to be present in output")

    # Ensure it's in a code block (commonmarker wraps code in pre/code tags)
    assert_match(/<code[^>]*>.*nest2.*<\/code>/m, contents, "Expected nest2 to be in a code block")

    # Verify nesting order is preserved (nest3 should appear after nest2)
    nest2_pos = contents.index("nest2")
    nest3_pos = contents.index("nest3")
    assert nest2_pos < nest3_pos, "Expected nest2 to appear before nest3 to maintain nesting structure"
  end

  def test_that_yaml_frontmatter_title_renders_in_html
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:output_dir] = @output_dir
    options[:landing_pages][:index] = File.join(fixtures_dir, "landing_pages", "whitespace_template.md")

    generator = GraphQLDocs::Generator.new(@tiny_results, options)
    generator.generate

    contents = File.read File.join(@output_dir, "index.html")

    # Should render title from YAML frontmatter, not "index"
    assert_match(%r{<title>GraphQL documentation</title>}, contents)
    refute_match(%r{<title>index</title>}, contents)

    # YAML frontmatter should not appear in page content
    refute_match(/^---$/, contents)
    refute_match(/^title: GraphQL documentation$/, contents)
  end

  def test_that_yaml_frontmatter_does_not_pollute_across_files
    # Critical test: Ensures YAML frontmatter from one file doesn't leak into another.
    # This tests the thread-safe immutable options pattern where each file with YAML
    # gets its own temporary renderer instead of mutating shared state.
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:output_dir] = @output_dir
    options[:delete_output] = true

    # Set up templates: one with YAML frontmatter, one without
    options[:templates][:objects] = File.join(fixtures_dir, "templates", "with_yaml_title.html")
    options[:templates][:scalars] = File.join(fixtures_dir, "templates", "without_yaml.html")

    generator = GraphQLDocs::Generator.new(@tiny_results, options)
    generator.generate

    # Object should have the custom YAML title
    object_file = File.read(File.join(@output_dir, "object", "codeofconduct", "index.html"))
    assert_match(%r{<title>Custom YAML Title</title>}, object_file)

    # Scalar should NOT have the custom YAML title - should use fallback
    scalar_file = File.read(File.join(@output_dir, "scalar", "uri", "index.html"))
    refute_match(%r{<title>Custom YAML Title</title>}, scalar_file)
    assert_match(%r{<title>URI</title>}, scalar_file) # Should use type name fallback
  end

  def test_that_options_remain_unchanged_after_yaml_processing
    # Test that @options hash is never mutated during YAML frontmatter processing.
    # The immutable pattern creates temporary renderers instead of modifying shared state.
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:output_dir] = @output_dir
    options[:landing_pages][:index] = File.join(fixtures_dir, "landing_pages", "whitespace_template.md")

    generator = GraphQLDocs::Generator.new(@tiny_results, options)
    generator_options = generator.instance_variable_get(:@options)

    # Snapshot of options before generation
    generator_options.dup
    has_title_before = generator_options.key?(:title)

    generator.generate

    # After generation, @options should not have been modified
    refute generator_options.key?(:title), "Options should not contain :title from YAML frontmatter"
    assert_equal has_title_before, generator_options.key?(:title),
      "Options keys should not change after generation"
  end

  def test_that_empty_html_lines_not_interpreted_by_markdown
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:output_dir] = @output_dir

    generator = GraphQLDocs::Generator.new(@tiny_results, options)
    generator.generate

    contents = File.read File.join(@output_dir, "query", "codeofconduct", "index.html")

    assert_match(%r{<p>The code of conduct's key</p>}, contents)
  end

  def test_that_non_empty_html_lines_not_interpreted_by_markdown
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:output_dir] = @output_dir

    generator = GraphQLDocs::Generator.new(@results, options)
    generator.generate

    contents = File.read File.join(@output_dir, "input_object", "projectorder", "index.html")

    assert_match %r{<div class="description-wrapper">\n   <p>The direction in which to order projects by the specified field.</p>\s+</div>},
      contents
  end
end
