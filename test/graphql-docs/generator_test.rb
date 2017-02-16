require 'test_helper'

class GeneratorTest < Minitest::Test
  def setup
    @json = File.read("#{fixtures_dir}/gh-api.json")
    @parser = GraphQLDocs::Parser.new(@json, {})
    @results = @parser.parse
  end

  def test_that_it_requires_templates
    config = GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS.dup
    config[:templates][:objects] = 'BOGUS'

    assert_raises Errno::ENOENT do
      GraphQLDocs::Generator.new(@results, config)
    end
  end
end
