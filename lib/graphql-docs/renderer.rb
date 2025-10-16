# frozen_string_literal: true

require "html_pipeline"
require "gemoji"
require "yaml"
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
      context = @pipeline_config[:context] || {}

      # Convert context for html-pipeline 3
      @pipeline_context = {}
      @pipeline_context[:unsafe] = context[:unsafe] if context.key?(:unsafe)
      @pipeline_context[:asset_root] = context[:asset_root] if context.key?(:asset_root)

      # html-pipeline 3 uses a simplified API - we'll just use text-to-text processing
      # since markdown conversion is handled by commonmarker directly
      @pipeline = nil # We'll handle markdown conversion directly in to_html
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

    # Converts a string to HTML using commonmarker with emoji support.
    #
    # @param string [String] Content to convert
    # @param context [Hash] Additional context (unused, kept for compatibility)
    # @return [String] HTML output
    #
    # @api private
    def to_html(string, context: {})
      return "" if string.nil?
      return "" if string.empty?

      begin
        # Replace emoji shortcodes before markdown processing
        string_with_emoji = emojify(string)

        # Commonmarker 2.x uses parse/render API
        # Parse with GitHub Flavored Markdown extensions enabled by default
        doc = ::Commonmarker.parse(string_with_emoji)

        # Convert to HTML - commonmarker 2.x automatically includes:
        # - GitHub Flavored Markdown (tables, strikethrough, etc.)
        # - Header anchors with IDs
        # - Safe HTML by default (unless unsafe mode is enabled)
        html = if @pipeline_context[:unsafe]
          doc.to_html(options: {render: {unsafe: true}})
        else
          doc.to_html
        end

        # Strip trailing newline that commonmarker adds
        html.chomp
      rescue => e
        # Log error and return safe fallback
        warn "Failed to parse markdown: #{e.message}"
        require "cgi" unless defined?(CGI)
        CGI.escapeHTML(string.to_s)
      end
    end

    # Converts emoji shortcodes like :smile: to emoji characters
    #
    # @param string [String] Text containing emoji shortcodes
    # @return [String] Text with shortcodes replaced by emoji
    # @api private
    def emojify(string)
      string.gsub(/:([a-z0-9_+-]+):/) do |match|
        emoji = Emoji.find_by_alias(Regexp.last_match(1))
        emoji ? emoji.raw : match
      end
    end

    private
  end
end
