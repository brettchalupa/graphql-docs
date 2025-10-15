# frozen_string_literal: true

require "graphql-docs/helpers"
require "graphql-docs/renderer"
require "graphql-docs/configuration"
require "graphql-docs/generator"
require "graphql-docs/parser"
require "graphql-docs/version"

# Lazy-load the Rack app - only loads if Rack is available
begin
  require "graphql-docs/app" if defined?(Rack)
rescue LoadError
  # Rack not available, App class won't be loaded
end

# GraphQLDocs is a library for generating beautiful HTML documentation from GraphQL schemas.
# It parses GraphQL schema files or schema objects and generates a complete documentation website
# with customizable templates and styling.
#
# @example Generate docs from a file
#   GraphQLDocs.build(filename: 'schema.graphql')
#
# @example Generate docs from a schema string
#   GraphQLDocs.build(schema: schema_string)
#
# @example Generate docs from a schema class
#   schema = GraphQL::Schema.define { query query_type }
#   GraphQLDocs.build(schema: schema)
#
# @see Configuration For available configuration options
module GraphQLDocs
  class << self
    # Builds HTML documentation from a GraphQL schema.
    #
    # This is the main entry point for generating documentation. It accepts either a schema file path
    # or a schema string/object, parses it, and generates a complete HTML documentation website.
    #
    # @param options [Hash] Configuration options for generating the documentation
    # @option options [String] :filename Path to GraphQL schema IDL file
    # @option options [String, GraphQL::Schema] :schema GraphQL schema as string or schema class
    # @option options [String] :output_dir ('./output/') Directory where HTML will be generated
    # @option options [Boolean] :use_default_styles (true) Whether to include default CSS styles
    # @option options [String] :base_url ('') Base URL to prepend for assets and links
    # @option options [Boolean] :delete_output (false) Delete output directory before generating
    # @option options [Hash] :pipeline_config Configuration for html-pipeline rendering
    # @option options [Class] :renderer (GraphQLDocs::Renderer) Custom renderer class
    # @option options [Hash] :templates Custom template file paths
    # @option options [Hash] :landing_pages Custom landing page file paths
    # @option options [Hash] :classes Additional CSS class names for elements
    # @option options [Proc] :notices Proc for adding notices to schema members
    #
    # @return [Boolean] Returns true on successful generation
    #
    # @raise [ArgumentError] If both filename and schema are provided, or if neither is provided
    # @raise [ArgumentError] If the specified filename does not exist
    # @raise [TypeError] If filename is not a String
    # @raise [TypeError] If schema is not a String or GraphQL::Schema
    #
    # @example Basic usage with file
    #   GraphQLDocs.build(filename: 'schema.graphql')
    #
    # @example With custom options
    #   GraphQLDocs.build(
    #     filename: 'schema.graphql',
    #     output_dir: './docs',
    #     base_url: '/api-docs',
    #     delete_output: true
    #   )
    #
    # @example With custom renderer
    #   class MyRenderer < GraphQLDocs::Renderer
    #     def render(contents, type: nil, name: nil)
    #       # Custom rendering logic
    #     end
    #   end
    #   GraphQLDocs.build(filename: 'schema.graphql', renderer: MyRenderer)
    #
    # @see Configuration::GRAPHQLDOCS_DEFAULTS For all available options
    def build(options)
      # do not let user provided values overwrite every single value
      %i[templates landing_pages].each do |opt|
        next unless options.key?(opt)

        GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS[opt].each_pair do |key, value|
          options[opt][key] = value unless options[opt].key?(key)
        end
      end

      options = GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS.merge(options)

      filename = options[:filename]
      schema = options[:schema]

      raise ArgumentError, "Pass in `filename` or `schema`, but not both!" if !filename.nil? && !schema.nil?

      raise ArgumentError, "Pass in either `filename` or `schema`" if filename.nil? && schema.nil?

      if filename
        raise TypeError, "Expected `String`, got `#{filename.class}`" unless filename.is_a?(String)

        raise ArgumentError, "#{filename} does not exist!" unless File.exist?(filename)

        schema = File.read(filename)
      elsif !schema.is_a?(String) && !schema_type?(schema)
        raise TypeError, "Expected `String` or `GraphQL::Schema`, got `#{schema.class}`"
      end

      parser = GraphQLDocs::Parser.new(schema, options)
      parsed_schema = parser.parse

      generator = GraphQLDocs::Generator.new(parsed_schema, options)

      generator.generate
    end

    private def schema_type?(object)
      object.respond_to?(:ancestors) && object.ancestors.include?(GraphQL::Schema)
    end
  end
end
