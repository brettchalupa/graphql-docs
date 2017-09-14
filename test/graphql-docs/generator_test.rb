require 'test_helper'

class GeneratorTest < Minitest::Test
  class CustomRenderer
    def initialize(_, _)
    end

    def render(contents, type: nil, name: nil)
      to_html(contents)
    end

    def to_html(contents)
      return '' if contents.nil?
      contents.sub(/CodeOfConduct/i, 'CoC!!!!!')
    end
  end

  def setup
    schema = File.read(File.join(fixtures_dir, 'gh-schema.graphql'))
    @parser = GraphQLDocs::Parser.new(schema, {})
    @results = @parser.parse

    tiny_schema = File.read(File.join(fixtures_dir, 'tiny-schema.graphql'))
    @tiny_parser = GraphQLDocs::Parser.new(tiny_schema, {})
    @tiny_results = @tiny_parser.parse

    @output_dir = File.join(fixtures_dir, 'output')
  end

  def deep_copy(hash)
    Marshal.load(Marshal.dump(hash))
  end

  def test_that_it_requires_templates
    config = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    config[:templates][:objects] = 'BOGUS'

    assert_raises Errno::ENOENT do
      GraphQLDocs::Generator.new(@results, config)
    end
  end

  def test_that_it_does_not_require_default
    config = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    config[:templates][:default] = nil

    GraphQLDocs::Generator.new(@results, config)
  end

  def test_that_it_works
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:output_dir] = @output_dir
    options[:delete_output] = true

    generator = GraphQLDocs::Generator.new(@results, options)
    generator.generate

    assert File.exist? File.join(@output_dir, 'index.html')
    assert File.exist? File.join(@output_dir, 'assets', 'style.css')
    assert File.exist? File.join(@output_dir, 'enum', 'issuestate', 'index.html')
    assert File.exist? File.join(@output_dir, 'input_object', 'projectorder', 'index.html')
    assert File.exist? File.join(@output_dir, 'interface', 'reactable', 'index.html')
    assert File.exist? File.join(@output_dir, 'mutation', 'addcomment', 'index.html')
    assert File.exist? File.join(@output_dir, 'object', 'repository', 'index.html')
    assert File.exist? File.join(@output_dir, 'scalar', 'boolean', 'index.html')
    assert File.exist? File.join(@output_dir, 'union', 'issuetimelineitem', 'index.html')

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

    refute File.exist? File.join(@output_dir, 'assets', 'style.css')
  end

  def test_that_setting_base_url_works
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:output_dir] = @output_dir
    options[:delete_output] = true
    options[:base_url] = 'wowzers'

    generator = GraphQLDocs::Generator.new(@tiny_results, options)
    generator.generate

    contents = File.read File.join(@output_dir, 'index.html')
    assert_match %r{<link rel="stylesheet" href="wowzers/assets/style.css">}, contents

    contents = File.read File.join(@output_dir, 'object', 'codeofconduct', 'index.html')
    assert_match %r{href="wowzers/object/codeofconduct/"}, contents
  end

  def test_that_custom_renderer_can_be_used
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:output_dir] = @output_dir

    options[:renderer] = CustomRenderer

    generator = GraphQLDocs::Generator.new(@tiny_results, options)
    generator.generate

    contents = File.read(File.join(@output_dir, 'object', 'codeofconduct', 'index.html'))

    assert_match /CoC!!!!!/, contents
  end

  def test_that_it_sets_classes
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:output_dir] = @output_dir
    options[:delete_output] = true
    options[:classes][:field_entry] = 'my-4'

    generator = GraphQLDocs::Generator.new(@tiny_results, options)
    generator.generate

    object = File.read File.join(@output_dir, 'object', 'codeofconduct', 'index.html')

    assert_match /<div class="field-entry my-4">/, object
  end

  def test_that_broken_yaml_is_caught
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:landing_pages][:index] = File.join(fixtures_dir, 'landing_pages', 'broken_yaml.md')
    generator = GraphQLDocs::Generator.new(@tiny_results, options)

    assert_raises TypeError do
      generator.generate
    end
  end
end
