require 'html/pipeline'
require 'extended-markdown-filter'
require 'page-toc-filter'

module GraphQLDocs
  class Renderer
    def initialize(options)
      @options = options

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

    def render(string)
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
