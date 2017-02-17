require 'test_helper'

class GeneratorTest < Minitest::Test
  class CustomRenderer
    def initialize(options)
      @options = options
    end

    def render(contents, type, name)
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

  def test_that_it_works
    options = deep_copy(GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS)
    options[:output_dir] = @output_dir

    generator = GraphQLDocs::Generator.new(@results, options)
    generator.generate

    assert File.join(@output_dir, 'enum', 'issuestate', 'index.html')
    assert File.join(@output_dir, 'input_object', 'projectorder', 'index.html')
    assert File.join(@output_dir, 'interface', 'reactable', 'index.html')
    assert File.join(@output_dir, 'mutation', 'addcomment', 'index.html')
    assert File.join(@output_dir, 'object', 'repository', 'index.html')
    assert File.join(@output_dir, 'scalar', 'boolean', 'index.html')
    assert File.join(@output_dir, 'union', 'issuetimelineitem', 'index.html')
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
end
