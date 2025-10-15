# frozen_string_literal: true

require "html/pipeline"
require "yaml"
require "extended-markdown-filter"
require "ostruct"

module GraphQLDocs
  # Renders documentation content into HTML.
  #
  # The Renderer takes parsed schema content and converts it to HTML using html-pipeline.
  # It applies markdown processing, emoji support, and other filters, then wraps the
  # result in the default layout template.
  #
  # @example Basic usage
  #   renderer = GraphQLDocs::Renderer.new(parsed_schema, options)
  #   html = renderer.render(markdown_content, type: 'object', name: 'User')
  #
  # @example Custom renderer
  #   class MyRenderer < GraphQLDocs::Renderer
  #     def render(contents, type: nil, name: nil, filename: nil)
  #       # Custom rendering logic
  #       super
  #     end
  #   end
  class Renderer
    include Helpers

    # @!attribute [r] options
    #   @return [Hash] Configuration options for the renderer
    attr_reader :options

    # Initializes a new Renderer instance.
    #
    # @param parsed_schema [Hash] The parsed schema from {Parser#parse}
    # @param options [Hash] Configuration options
    # @option options [Hash] :templates Template file paths
    # @option options [Hash] :pipeline_config html-pipeline configuration
    def initialize(parsed_schema, options)
      @parsed_schema = parsed_schema
      @options = options

      @graphql_default_layout = ERB.new(File.read(@options[:templates][:default])) unless @options[:templates][:default].nil?

      @pipeline_config = @options[:pipeline_config] || {}
      pipeline = @pipeline_config[:pipeline] || {}
      context = @pipeline_config[:context] || {}

      filters = pipeline.map do |f|
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

      @pipeline = HTML::Pipeline.new(filters, context)
    end

    # Renders content into complete HTML with layout.
    #
    # This method converts the content through the html-pipeline filters and wraps it
    # in the default layout template. If the method returns nil, no file will be written.
    #
    # @param contents [String] Content to render (typically Markdown)
    # @param type [String, nil] GraphQL type category (e.g., 'object', 'interface')
    # @param name [String, nil] Name of the GraphQL type being rendered
    # @param filename [String, nil] Output filename path
    # @return [String, nil] Rendered HTML content, or nil to skip file generation
    #
    # @example
    #   html = renderer.render(markdown, type: 'object', name: 'User')
    def render(contents, type: nil, name: nil, filename: nil)
      # Include all options (like Generator does) to support YAML frontmatter variables like title
      opts = @options.merge({type: type, name: name, filename: filename}).merge(helper_methods)

      contents = to_html(contents, context: {filename: filename})
      return contents if @graphql_default_layout.nil?

      opts[:content] = contents
      @graphql_default_layout.result(OpenStruct.new(opts).instance_eval { binding })
    end

    # Converts a string to HTML using html-pipeline.
    #
    # @param string [String] Content to convert
    # @param context [Hash] Additional context for pipeline filters
    # @return [String] HTML output from pipeline
    #
    # @api private
    def to_html(string, context: {})
      @pipeline.to_html(string, context)
    end

    private

    def filter_key(str)
      str.downcase
    end

    def filter?(filter)
      filter < HTML::Pipeline::Filter
    rescue LoadError, ArgumentError
      false
    end
  end
end
