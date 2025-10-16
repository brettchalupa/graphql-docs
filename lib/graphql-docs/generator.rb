# frozen_string_literal: true

require "erb"
require "fileutils"
require "sass-embedded"
require "ostruct"

module GraphQLDocs
  # Generates HTML documentation files from a parsed GraphQL schema.
  #
  # The Generator takes the parsed schema structure and creates individual HTML pages
  # for each GraphQL type, along with landing pages and static assets. It uses ERB
  # templates for layout and the Renderer for converting content to HTML.
  #
  # @example Basic usage
  #   generator = GraphQLDocs::Generator.new(parsed_schema, options)
  #   generator.generate
  #
  # @see Parser
  # @see Renderer
  class Generator
    include Helpers

    # @!attribute [rw] parsed_schema
    #   @return [Hash] The parsed schema structure from {Parser}
    attr_accessor :parsed_schema

    # Initializes a new Generator instance.
    #
    # Sets up ERB templates for all GraphQL types and landing pages. Validates that
    # all required template files exist before generation begins.
    #
    # @param parsed_schema [Hash] The parsed schema from {Parser#parse}
    # @param options [Hash] Configuration options
    # @option options [Hash] :templates Paths to ERB template files
    # @option options [Hash] :landing_pages Paths to landing page files
    # @option options [Class] :renderer Renderer class to use
    #
    # @raise [IOError] If any required template or landing page file is not found
    def initialize(parsed_schema, options)
      @parsed_schema = parsed_schema
      @options = options

      @renderer = @options[:renderer].new(@parsed_schema, @options)

      %i[operations objects queries mutations interfaces enums unions input_objects scalars directives].each do |sym|
        raise IOError, "`#{sym}` template #{@options[:templates][sym]} was not found" unless File.exist?(@options[:templates][sym])

        instance_variable_set("@graphql_#{sym}_template", ERB.new(File.read(@options[:templates][sym])))
      end

      %i[index object query mutation interface enum union input_object scalar directive].each do |sym|
        if @options[:landing_pages][sym].nil?
          instance_variable_set("@#{sym}_landing_page", nil)
        elsif !File.exist?(@options[:landing_pages][sym])
          raise IOError, "`#{sym}` landing page #{@options[:landing_pages][sym]} was not found"
        end

        landing_page_contents = File.read(@options[:landing_pages][sym])
        metadata = ""

        if File.extname(@options[:landing_pages][sym]) == ".erb"
          opts = @options.merge(@options[:landing_pages][:variables]).merge(helper_methods)
          if yaml?(landing_page_contents)
            metadata, landing_page = split_into_metadata_and_contents(landing_page_contents, parse: false)
            erb_template = ERB.new(landing_page)
          else
            erb_template = ERB.new(landing_page_contents)
          end

          landing_page_contents = erb_template.result(OpenStruct.new(opts).instance_eval { binding })
        end

        instance_variable_set("@graphql_#{sym}_landing_page", metadata + landing_page_contents)
      end
    end

    # Generates all HTML documentation files.
    #
    # This is the main generation method that creates:
    # - Individual pages for each GraphQL type
    # - Landing pages for type categories
    # - Static assets (CSS, fonts, images) if using default styles
    #
    # @return [Boolean] Returns true on successful generation
    #
    # @example
    #   generator.generate # Creates all docs in output directory
    def generate
      FileUtils.rm_rf(@options[:output_dir]) if @options[:delete_output]

      has_query = create_graphql_operation_pages
      create_graphql_object_pages
      create_graphql_query_pages
      create_graphql_mutation_pages
      create_graphql_interface_pages
      create_graphql_enum_pages
      create_graphql_union_pages
      create_graphql_input_object_pages
      create_graphql_scalar_pages
      create_graphql_directive_pages

      write_file("static", "index", @graphql_index_landing_page, trim: false) unless @graphql_index_landing_page.nil?

      write_file("static", "object", @graphql_object_landing_page, trim: false) unless @graphql_object_landing_page.nil?

      write_file("operation", "query", @graphql_query_landing_page, trim: false) if !@graphql_query_landing_page.nil? && !has_query

      write_file("operation", "mutation", @graphql_mutation_landing_page, trim: false) unless @graphql_mutation_landing_page.nil?

      write_file("static", "interface", @graphql_interface_landing_page, trim: false) unless @graphql_interface_landing_page.nil?

      write_file("static", "enum", @graphql_enum_landing_page, trim: false) unless @graphql_enum_landing_page.nil?

      write_file("static", "union", @graphql_union_landing_page, trim: false) unless @graphql_union_landing_page.nil?

      write_file("static", "input_object", @graphql_input_object_landing_page, trim: false) unless @graphql_input_object_landing_page.nil?

      write_file("static", "scalar", @graphql_scalar_landing_page, trim: false) unless @graphql_scalar_landing_page.nil?

      write_file("static", "directive", @graphql_directive_landing_page, trim: false) unless @graphql_directive_landing_page.nil?

      if @options[:use_default_styles]
        assets_dir = File.join(File.dirname(__FILE__), "layouts", "assets")
        FileUtils.mkdir_p(File.join(@options[:output_dir], "assets"))

        css = Sass.compile(File.join(assets_dir, "css", "screen.scss")).css
        File.write(File.join(@options[:output_dir], "assets", "style.css"), css)

        FileUtils.cp_r(File.join(assets_dir, "images"), File.join(@options[:output_dir], "assets"))
      end

      true
    end

    # Creates HTML pages for GraphQL operation types (Query, Mutation).
    #
    # @return [Boolean] Returns true if Query type was found and generated
    # @api private
    def create_graphql_operation_pages
      graphql_operation_types.each do |query_type|
        metadata = ""
        next unless query_type[:name] == graphql_root_types["query"]

        unless @options[:landing_pages][:query].nil?
          query_landing_page = @options[:landing_pages][:query]
          query_landing_page = File.read(query_landing_page)
          if yaml?(query_landing_page)
            pieces = yaml_split(query_landing_page)
            pieces[2] = pieces[2].chomp
            metadata = pieces[1, 3].join("\n")
            query_landing_page = pieces[4]
          end
          query_type[:description] = query_landing_page
        end
        opts = default_generator_options(type: query_type)
        contents = @graphql_operations_template.result(OpenStruct.new(opts).instance_eval { binding })
        write_file("operation", "query", metadata + contents)
        return true
      end
      false
    end

    # Creates HTML pages for GraphQL object types.
    # @return [void]
    # @api private
    def create_graphql_object_pages
      graphql_object_types.each do |object_type|
        opts = default_generator_options(type: object_type)

        contents = @graphql_objects_template.result(OpenStruct.new(opts).instance_eval { binding })
        write_file("object", object_type[:name], contents)
      end
    end

    # Creates HTML pages for GraphQL query fields.
    # @return [void]
    # @api private
    def create_graphql_query_pages
      graphql_query_types.each do |query|
        opts = default_generator_options(type: query)

        contents = @graphql_queries_template.result(OpenStruct.new(opts).instance_eval { binding })
        write_file("query", query[:name], contents)
      end
    end

    # Creates HTML pages for GraphQL mutation fields.
    # @return [void]
    # @api private
    def create_graphql_mutation_pages
      graphql_mutation_types.each do |mutation|
        opts = default_generator_options(type: mutation)

        contents = @graphql_mutations_template.result(OpenStruct.new(opts).instance_eval { binding })
        write_file("mutation", mutation[:name], contents)
      end
    end

    # Creates HTML pages for GraphQL interface types.
    # @return [void]
    # @api private
    def create_graphql_interface_pages
      graphql_interface_types.each do |interface_type|
        opts = default_generator_options(type: interface_type)

        contents = @graphql_interfaces_template.result(OpenStruct.new(opts).instance_eval { binding })
        write_file("interface", interface_type[:name], contents)
      end
    end

    # Creates HTML pages for GraphQL enum types.
    # @return [void]
    # @api private
    def create_graphql_enum_pages
      graphql_enum_types.each do |enum_type|
        opts = default_generator_options(type: enum_type)

        contents = @graphql_enums_template.result(OpenStruct.new(opts).instance_eval { binding })
        write_file("enum", enum_type[:name], contents)
      end
    end

    # Creates HTML pages for GraphQL union types.
    # @return [void]
    # @api private
    def create_graphql_union_pages
      graphql_union_types.each do |union_type|
        opts = default_generator_options(type: union_type)

        contents = @graphql_unions_template.result(OpenStruct.new(opts).instance_eval { binding })
        write_file("union", union_type[:name], contents)
      end
    end

    # Creates HTML pages for GraphQL input object types.
    # @return [void]
    # @api private
    def create_graphql_input_object_pages
      graphql_input_object_types.each do |input_object_type|
        opts = default_generator_options(type: input_object_type)

        contents = @graphql_input_objects_template.result(OpenStruct.new(opts).instance_eval { binding })
        write_file("input_object", input_object_type[:name], contents)
      end
    end

    # Creates HTML pages for GraphQL scalar types.
    # @return [void]
    # @api private
    def create_graphql_scalar_pages
      graphql_scalar_types.each do |scalar_type|
        opts = default_generator_options(type: scalar_type)

        contents = @graphql_scalars_template.result(OpenStruct.new(opts).instance_eval { binding })
        write_file("scalar", scalar_type[:name], contents)
      end
    end

    # Creates HTML pages for GraphQL directives.
    # @return [void]
    # @api private
    def create_graphql_directive_pages
      graphql_directive_types.each do |directive_type|
        opts = default_generator_options(type: directive_type)

        contents = @graphql_directives_template.result(OpenStruct.new(opts).instance_eval { binding })
        write_file("directive", directive_type[:name], contents)
      end
    end

    private

    def default_generator_options(opts = {})
      @options.merge(opts).merge(helper_methods)
    end

    def write_file(type, name, contents, trim: true)
      if type == "static"
        if name == "index"
          path = @options[:output_dir]
        else
          path = File.join(@options[:output_dir], name)
          FileUtils.mkdir_p(path)
        end
      else
        path = File.join(@options[:output_dir], type, name.downcase)
        FileUtils.mkdir_p(path)
      end

      metadata = {}
      if yaml?(contents)
        # Split data
        metadata, contents = split_into_metadata_and_contents(contents)
      end

      if trim
        # normalize spacing so that CommonMarker doesn't treat it as `pre`
        contents.gsub!(/^\s+$/, "")
        contents.gsub!(/^\s{4}/m, "  ")
      end

      filename = File.join(path, "index.html")
      contents = render_with_metadata(contents, metadata, type: type, name: name, filename: filename)
      File.write(filename, contents) unless contents.nil?
    end

    # Renders content with optional metadata, without polluting @options.
    #
    # File Isolation:
    # This method ensures that YAML frontmatter metadata from one file doesn't
    # pollute or leak into other files during batch generation. It achieves this
    # through an immutable options pattern:
    #
    # 1. When metadata is present (from YAML frontmatter), a NEW temporary renderer
    #    is created with merged options, keeping @options and @renderer unchanged.
    # 2. When no metadata is present, the shared @renderer is used directly
    #    (safe because @options and @renderer remain unchanged throughout generation).
    #
    # This prevents a bug where title or other metadata from file1.md would
    # persist and incorrectly appear in file2.md if they were processed sequentially.
    #
    # Example:
    #   # file1.md has "title: Custom Title"
    #   # file2.md has no YAML frontmatter
    #   # Without this isolation, file2.md would incorrectly get "Custom Title"
    #
    # @param contents [String] Content to render
    # @param metadata [Hash] Metadata extracted from YAML frontmatter
    # @param type [String] Type category
    # @param name [String] Type name
    # @param filename [String] Output filename
    # @return [String, nil] Rendered HTML content
    #
    # @api private
    def render_with_metadata(contents, metadata, type:, name:, filename:)
      if metadata.is_a?(Hash) && metadata.any?
        temp_options = @options.merge(metadata)
        temp_renderer = @options[:renderer].new(@parsed_schema, temp_options)
        temp_renderer.render(contents, type: type, name: name, filename: filename)
      else
        @renderer.render(contents, type: type, name: name, filename: filename)
      end
    end
  end
end
