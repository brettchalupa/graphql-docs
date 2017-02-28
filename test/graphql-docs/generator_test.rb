require 'test_helper'

class GeneratorTest < Minitest::Test
  class CustomRenderer
    def initialize(_, _)
    end

    def render(type, name, contents)
      contents.sub(/Repository/i, 'Meow Woof!')
    end
  end

  def setup
    @json = File.read(File.join(fixtures_dir, 'gh-api.json'))
    @parser = GraphQLDocs::Parser.new(@json, {})
    @results = @parser.parse
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
  end

  def test_that_turning_off_styles_works
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:output_dir] = @output_dir
    options[:delete_output] = true
    options[:use_default_styles] = false

    generator = GraphQLDocs::Generator.new(@results, options)
    generator.generate

    refute File.exist? File.join(@output_dir, 'assets', 'style.css')
  end

  def test_that_setting_base_url_works
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:output_dir] = @output_dir
    options[:delete_output] = true
    options[:base_url] = 'wowzers'

    generator = GraphQLDocs::Generator.new(@results, options)
    generator.generate

    contents = File.read File.join(@output_dir, 'index.html')
    assert_match %r{<link rel="stylesheet" href="wowzers/assets/style.css">}, contents

    contents = File.read File.join(@output_dir, 'object', 'repository', 'index.html')
    assert_match %r{href="wowzers/object/mutation" class="sidebar-link">}, contents
  end

  def test_that_custom_renderer_can_be_used
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:output_dir] = @output_dir

    options[:renderer] = CustomRenderer

    generator = GraphQLDocs::Generator.new(@results, options)
    generator.generate

    contents = File.read(File.join(@output_dir, 'object', 'repository', 'index.html'))

    assert_match /Meow Woof!/, contents
  end

  def test_ensure_no_broken_links
    require 'html-proofer'
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:output_dir] = @output_dir
    options[:delete_output] = true

    generator = GraphQLDocs::Generator.new(@results, options)
    generator.generate

    proofer_options = { disable_external: true, assume_extension: true }
    HTMLProofer.check_directory(@output_dir, proofer_options).run
  end
end
