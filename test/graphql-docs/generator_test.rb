require 'test_helper'

class GeneratorTest < Minitest::Test
  def setup
    @json = File.read(File.join(fixtures_dir, 'gh-api.json'))
    @parser = GraphQLDocs::Parser.new(@json, {})
    @results = @parser.parse
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
    output = File.join(fixtures_dir, 'output')
    options[:output_dir] = output

    generator = GraphQLDocs::Generator.new(@results, options)

    generator.generate

    assert File.join(output, 'enum', 'issuestate', 'index.html')
    assert File.join(output, 'input_object', 'projectorder', 'index.html')
    assert File.join(output, 'interface', 'reactable', 'index.html')
    assert File.join(output, 'mutation', 'addcomment', 'index.html')
    assert File.join(output, 'object', 'repository', 'index.html')
    assert File.join(output, 'scalar', 'boolean', 'index.html')
    assert File.join(output, 'union', 'issuetimelineitem', 'index.html')
  end
end
