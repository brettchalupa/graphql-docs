require 'html/pipeline'
require 'yaml'
require 'extended-markdown-filter'

module GraphQLDocs
  class Renderer
    include Helpers

    attr_reader :options

    def initialize(parsed_schema, options)
      @parsed_schema = parsed_schema
      @options = options

      unless @options[:templates][:default].nil?
        @graphql_default_layout = ERB.new(File.read(@options[:templates][:default]))
      end

      @pipeline_config = @options[:pipeline_config]

      filters = @pipeline_config[:pipeline].map do |f|
        if filter?(f)
          f
        else
          key = filter_key(f)
          filter = HTML::Pipeline.constants.find { |c| c.downcase == key }
          # possibly a custom filter
          if filter.nil?
            Kernel.const_get(f)
          else
            HTML::Pipeline.const_get(filter)
          end
        end
      end

      @pipeline = HTML::Pipeline.new(filters, @pipeline_config[:context])
    end

    def render(contents, type: nil, name: nil)
      opts = { base_url: @options[:base_url] }.merge({ type: type, name: name}).merge(helper_methods)

      contents = to_html(contents)
      return contents if @graphql_default_layout.nil?
      opts[:content] = contents
      @graphql_default_layout.result(OpenStruct.new(opts).instance_eval { binding })
    end

    def to_html(string)
      @pipeline.to_html(string)
    end

    private

    def filter_key(s)
      s.downcase
    end

    def filter?(f)
      f < HTML::Pipeline::Filter
    rescue LoadError, ArgumentError
      false
    end
  end
end
