require 'html/pipeline'
require 'extended-markdown-filter'

module GraphQLDocs
  class Renderer
    include Helpers

    def initialize(options, parsed_schema)
      @options = options
      @parsed_schema = parsed_schema

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

    def render(type, name, contents)
      contents = @pipeline.to_html(contents)
      return contents if @graphql_default_layout.nil?
      opts = { base_url: @options[:base_url] }.merge({ contents: contents, type: type, name: name}).merge(helper_methods)
      @graphql_default_layout.result(OpenStruct.new(opts).instance_eval { binding })
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
