# frozen_string_literal: true

require 'erb'

# Lazy-load Rack when the App class is first instantiated
begin
  require 'rack'
rescue LoadError => e
  # Define a stub that will raise a better error message
  module Rack
    def self.const_missing(name)
      raise LoadError, "The GraphQLDocs::App feature requires the 'rack' gem. " \
                       "Please add it to your Gemfile: gem 'rack', '~> 2.0' or gem 'rack', '~> 3.0'"
    end
  end
end

module GraphQLDocs
  # Rack application for serving GraphQL documentation on-demand.
  #
  # This provides an alternative to the static site generator approach, allowing
  # documentation to be served dynamically from a Rack-compatible web server.
  # Pages are generated on-demand and can be cached for performance.
  #
  # @example Standalone usage
  #   app = GraphQLDocs::App.new(
  #     schema: 'type Query { hello: String }',
  #     options: { base_url: '' }
  #   )
  #   run app
  #
  # @example Mount in Rails
  #   mount GraphQLDocs::App.new(schema: MySchema) => '/docs'
  #
  # @example With caching
  #   app = GraphQLDocs::App.new(
  #     schema: schema_string,
  #     options: { cache: true }
  #   )
  class App
    include Helpers

    # @!attribute [r] parsed_schema
    #   @return [Hash] The parsed GraphQL schema structure
    attr_reader :parsed_schema

    # @!attribute [r] options
    #   @return [Hash] Configuration options for the app
    attr_reader :options

    # @!attribute [r] base_options
    #   @return [Hash] Base configuration options (immutable)
    attr_reader :base_options

    # Initializes a new Rack app instance.
    #
    # @param schema [String, GraphQL::Schema] GraphQL schema as IDL string or schema class
    # @param filename [String, nil] Path to GraphQL schema file (alternative to schema param)
    # @param options [Hash] Configuration options
    # @option options [String] :base_url ('') Base URL prefix for all routes
    # @option options [Boolean] :cache (true) Enable page caching
    # @option options [Boolean] :use_default_styles (true) Serve default CSS
    # @option options [Hash] :templates Custom template paths
    # @option options [Class] :renderer Custom renderer class
    #
    # @raise [ArgumentError] If neither schema nor filename is provided
    def initialize(schema: nil, filename: nil, options: {})
      raise ArgumentError, 'Must provide either schema or filename' if schema.nil? && filename.nil?

      @base_options = Configuration::GRAPHQLDOCS_DEFAULTS.merge(options).freeze
      @options = @base_options.dup

      # Load schema from file if filename provided
      if filename
        raise ArgumentError, "#{filename} does not exist!" unless File.exist?(filename)
        schema = File.read(filename)
      end

      # Parse schema once at initialization
      parser = Parser.new(schema, @options)
      @parsed_schema = parser.parse

      @renderer = @options[:renderer].new(@parsed_schema, @options)

      # Initialize cache
      @cache_enabled = @options.fetch(:cache, true)
      @cache = {} if @cache_enabled

      # Load templates
      load_templates

      # Pre-compile assets if using default styles
      compile_assets if @options[:use_default_styles]
    end

    # Rack interface method.
    #
    # @param env [Hash] Rack environment hash
    # @return [Array] Rack response tuple [status, headers, body]
    def call(env)
      request = Rack::Request.new(env)
      path = clean_path(request.path_info)

      route(path)
    rescue StandardError => e
      [500, { 'content-type' => 'text/html' }, [error_page(e)]]
    end

    # Clears the page cache.
    #
    # @return [void]
    def clear_cache!
      @cache&.clear
    end

    # Reloads the schema and clears cache.
    #
    # @param new_schema [String, GraphQL::Schema] New schema to parse
    # @return [void]
    def reload_schema!(new_schema)
      parser = Parser.new(new_schema, @options)
      @parsed_schema = parser.parse
      @renderer = @options[:renderer].new(@parsed_schema, @options)
      clear_cache!
    end

    private

    def clean_path(path)
      # Remove base_url prefix if present
      base = @options[:base_url]
      path = path.sub(/^#{Regexp.escape(base)}/, '') if base && !base.empty?

      # Normalize path
      path = '/' if path.empty?
      path.sub(/\/$/, '') # Remove trailing slash
    end

    def route(path)
      case path
      when '', '/', '/index.html', '/index'
        serve_landing_page(:index)
      when '/operation/query', '/operation/query/index.html', '/operation/query/index'
        serve_operation_page
      when '/operation/mutation', '/operation/mutation/index.html', '/operation/mutation/index'
        serve_mutation_operation_page
      when %r{^/object/([^/]+)(?:/index(?:\.html)?)?$}
        serve_type_page(:object, $1)
      when %r{^/query/([^/]+)(?:/index(?:\.html)?)?$}
        serve_type_page(:query, $1)
      when %r{^/mutation/([^/]+)(?:/index(?:\.html)?)?$}
        serve_type_page(:mutation, $1)
      when %r{^/interface/([^/]+)(?:/index(?:\.html)?)?$}
        serve_type_page(:interface, $1)
      when %r{^/enum/([^/]+)(?:/index(?:\.html)?)?$}
        serve_type_page(:enum, $1)
      when %r{^/union/([^/]+)(?:/index(?:\.html)?)?$}
        serve_type_page(:union, $1)
      when %r{^/input_object/([^/]+)(?:/index(?:\.html)?)?$}
        serve_type_page(:input_object, $1)
      when %r{^/scalar/([^/]+)(?:/index(?:\.html)?)?$}
        serve_type_page(:scalar, $1)
      when %r{^/directive/([^/]+)(?:/index(?:\.html)?)?$}
        serve_type_page(:directive, $1)
      when %r{^/assets/(.+)$}
        serve_asset($1)
      else
        [404, { 'content-type' => 'text/html' }, [not_found_page(path)]]
      end
    end

    def serve_landing_page(page_type)
      cache_key = "landing:#{page_type}"

      content = fetch_from_cache(cache_key) do
        generate_landing_page(page_type)
      end

      return [404, { 'content-type' => 'text/html' }, ['Landing page not found']] if content.nil?

      [200, { 'content-type' => 'text/html; charset=utf-8' }, [content]]
    end

    def serve_operation_page
      cache_key = 'operation:query'

      content = fetch_from_cache(cache_key) do
        query_type = graphql_operation_types.find { |qt| qt[:name] == graphql_root_types['query'] }
        return nil unless query_type

        generate_type_content(:operations, query_type, 'operation', 'query')
      end

      return [404, { 'content-type' => 'text/html' }, ['Query type not found']] if content.nil?

      [200, { 'content-type' => 'text/html; charset=utf-8' }, [content]]
    end

    def serve_mutation_operation_page
      cache_key = 'operation:mutation'

      content = fetch_from_cache(cache_key) do
        mutation_type = graphql_operation_types.find { |mt| mt[:name] == graphql_root_types['mutation'] }
        return nil unless mutation_type

        generate_type_content(:operations, mutation_type, 'operation', 'mutation')
      end

      return [404, { 'content-type' => 'text/html' }, ['Mutation type not found']] if content.nil?

      [200, { 'content-type' => 'text/html; charset=utf-8' }, [content]]
    end

    def serve_type_page(type, name)
      name_lower = name.downcase
      cache_key = "#{type}:#{name_lower}"

      content = fetch_from_cache(cache_key) do
        generate_page_for_type(type, name)
      end

      return [404, { 'content-type' => 'text/html' }, ["#{type.capitalize} '#{name}' not found"]] if content.nil?

      [200, { 'content-type' => 'text/html; charset=utf-8' }, [content]]
    end

    def serve_asset(asset_path)
      # Serve compiled CSS
      if asset_path == 'style.css' && @compiled_css
        return [200, { 'content-type' => 'text/css; charset=utf-8' }, [@compiled_css]]
      end

      # Serve static assets from layouts/assets directory
      asset_file = File.join(File.dirname(__FILE__), 'layouts', 'assets', asset_path)

      if File.exist?(asset_file) && File.file?(asset_file)
        content = File.read(asset_file)
        content_type = mime_type_for(asset_path)
        [200, { 'content-type' => content_type }, [content]]
      else
        [404, { 'content-type' => 'text/plain' }, ['Asset not found']]
      end
    end

    def generate_landing_page(page_type)
      landing_page_var = instance_variable_get("@#{page_type}_landing_page")
      return nil if landing_page_var.nil?

      render_content(landing_page_var, type_category: 'static', type_name: page_type.to_s)
    end

    def generate_page_for_type(type, name)
      collection = case type
                   when :object then graphql_object_types
                   when :query then graphql_query_types
                   when :mutation then graphql_mutation_types
                   when :interface then graphql_interface_types
                   when :enum then graphql_enum_types
                   when :union then graphql_union_types
                   when :input_object then graphql_input_object_types
                   when :scalar then graphql_scalar_types
                   when :directive then graphql_directive_types
                   else return nil
                   end

      # Find the type (case-insensitive)
      type_data = collection.find { |t| t[:name].downcase == name.downcase }
      return nil unless type_data

      template_key = case type
                     when :object then :objects
                     when :query then :queries
                     when :mutation then :mutations
                     when :interface then :interfaces
                     when :enum then :enums
                     when :union then :unions
                     when :input_object then :input_objects
                     when :scalar then :scalars
                     when :directive then :directives
                     end

      generate_type_content(template_key, type_data, type.to_s, name)
    end

    def generate_type_content(template_key, type_data, type_category, type_name)
      template = instance_variable_get("@#{template_key}_template")
      return nil unless template

      opts = @options.merge(type: type_data).merge(helper_methods)
      contents = template.result(OpenStruct.new(opts).instance_eval { binding })

      # Normalize spacing
      contents.gsub!(/^\s+$/, '')
      contents.gsub!(/^\s{4}/m, '  ')

      render_content(contents, type_category: type_category, type_name: type_name)
    end

    def render_content(contents, type_category:, type_name:)
      # Parse YAML frontmatter if present (similar to generator.rb write_file)
      if yaml?(contents)
        meta, contents = split_into_metadata_and_contents(contents)
        # Temporarily merge metadata into options for this render
        # Need to mutate in place so renderer sees the changes
        @options.merge!(meta)
        result = @renderer.render(contents, type: type_category, name: type_name, filename: nil)
        # Reset options by clearing and repopulating from base (in place)
        @options.clear
        @options.merge!(@base_options)
        result
      else
        @renderer.render(contents, type: type_category, name: type_name, filename: nil)
      end
    end

    def fetch_from_cache(key)
      return yield unless @cache_enabled

      if @cache.key?(key)
        @cache[key]
      else
        result = yield
        @cache[key] = result if result
        result
      end
    end

    def load_templates
      # Load type templates
      %i[operations objects queries mutations interfaces enums unions input_objects scalars directives].each do |sym|
        template_file = @options[:templates][sym]
        next unless File.exist?(template_file)

        instance_variable_set("@#{sym}_template", ERB.new(File.read(template_file)))
      end

      # Load landing pages
      %i[index object query mutation interface enum union input_object scalar directive].each do |sym|
        landing_page_file = @options[:landing_pages][sym]
        next if landing_page_file.nil? || !File.exist?(landing_page_file)

        landing_page_contents = File.read(landing_page_file)
        metadata = ''

        if File.extname(landing_page_file) == '.erb'
          opts = @options.merge(@options[:landing_pages][:variables]).merge(helper_methods)
          if yaml?(landing_page_contents)
            metadata, landing_page = split_into_metadata_and_contents(landing_page_contents, parse: false)
            erb_template = ERB.new(landing_page)
          else
            erb_template = ERB.new(landing_page_contents)
          end
          landing_page_contents = erb_template.result(OpenStruct.new(opts).instance_eval { binding })
        end

        instance_variable_set("@#{sym}_landing_page", metadata + landing_page_contents)
      end
    end

    def compile_assets
      return unless @options[:use_default_styles]

      assets_dir = File.join(File.dirname(__FILE__), 'layouts', 'assets')
      scss_file = File.join(assets_dir, 'css', 'screen.scss')

      if File.exist?(scss_file)
        require 'sass-embedded'
        @compiled_css = Sass.compile(scss_file).css
      end
    end

    def mime_type_for(path)
      ext = File.extname(path).downcase
      case ext
      when '.css' then 'text/css'
      when '.js' then 'application/javascript'
      when '.png' then 'image/png'
      when '.jpg', '.jpeg' then 'image/jpeg'
      when '.gif' then 'image/gif'
      when '.svg' then 'image/svg+xml'
      when '.woff' then 'font/woff'
      when '.woff2' then 'font/woff2'
      when '.ttf' then 'font/ttf'
      when '.eot' then 'application/vnd.ms-fontobject'
      else 'application/octet-stream'
      end
    end

    def not_found_page(path)
      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>404 Not Found</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif; padding: 40px; max-width: 600px; margin: 0 auto; }
            h1 { color: #de4f4f; }
            code { background: #f5f5f5; padding: 2px 6px; border-radius: 3px; }
          </style>
        </head>
        <body>
          <h1>404 Not Found</h1>
          <p>The requested path <code>#{Rack::Utils.escape_html(path)}</code> was not found.</p>
          <p><a href="#{@options[:base_url]}/">← Back to documentation home</a></p>
        </body>
        </html>
      HTML
    end

    def error_page(error)
      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>500 Internal Server Error</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif; padding: 40px; max-width: 800px; margin: 0 auto; }
            h1 { color: #de4f4f; }
            pre { background: #f5f5f5; padding: 15px; border-radius: 5px; overflow-x: auto; }
          </style>
        </head>
        <body>
          <h1>500 Internal Server Error</h1>
          <p>An error occurred while generating the documentation page.</p>
          <h2>Error Details:</h2>
          <pre>#{Rack::Utils.escape_html(error.class.name)}: #{Rack::Utils.escape_html(error.message)}

#{Rack::Utils.escape_html(error.backtrace.first(10).join("\n"))}</pre>
        </body>
        </html>
      HTML
    end
  end
end
