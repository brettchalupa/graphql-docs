require 'html/pipeline'
require 'yaml'
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
      opts = { base_url: @options[:base_url] }.merge({ type: type, name: name}).merge(helper_methods)

      if has_yaml?(contents)
        # Split data
        meta, contents = split_into_metadata_and_contents(contents)
        opts = opts.merge(meta)
      end

      contents = @pipeline.to_html(contents)
      return contents if @graphql_default_layout.nil?
      opts[:content] = contents
      @graphql_default_layout.result(OpenStruct.new(opts).instance_eval { binding })
    end

    def has_yaml?(contents)
      contents =~ /\A-{3,5}\s*$/
    end

    def yaml_split(contents)
      contents.split(/^(-{5}|-{3})[ \t]*\r?\n?/, 3)
    end

    def split_into_metadata_and_contents(contents)
      opts = {}
      pieces = yaml_split(contents)
      if pieces.size < 4
        raise RuntimeError.new(
          "The file '#{content_filename}' appears to start with a metadata section (three or five dashes at the top) but it does not seem to be in the correct format.",
        )
      end
      # Parse
      begin
        meta = YAML.load(pieces[2]) || {}
      rescue Exception => e # rubocop:disable Lint/RescueException
        raise "Could not parse YAML for #{name}: #{e.message}"
      end
      [meta, pieces[4]]
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
