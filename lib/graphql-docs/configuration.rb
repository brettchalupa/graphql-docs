# frozen_string_literal: true

module GraphQLDocs
  # Configuration module that defines default options for GraphQLDocs.
  #
  # All configuration options can be overridden when calling {GraphQLDocs.build}.
  #
  # @see GraphQLDocs.build
  module Configuration
    # Default configuration options for GraphQLDocs.
    #
    # @return [Hash] Hash of default configuration values
    #
    # @option defaults [String] :filename (nil) Path to GraphQL schema IDL file
    # @option defaults [String, GraphQL::Schema] :schema (nil) GraphQL schema as string or class
    # @option defaults [Boolean] :delete_output (false) Delete output directory before generating
    # @option defaults [String] :output_dir ('./output/') Directory for generated HTML files
    # @option defaults [Hash] :pipeline_config Configuration for html-pipeline rendering
    # @option defaults [Class] :renderer (GraphQLDocs::Renderer) Renderer class to use
    # @option defaults [Boolean] :use_default_styles (true) Include default CSS styles
    # @option defaults [String] :base_url ('') Base URL to prepend to assets and links
    # @option defaults [Hash] :templates Paths to ERB template files for different GraphQL types
    # @option defaults [Hash] :landing_pages Paths to landing page files for each type
    # @option defaults [Hash] :classes Additional CSS class names for styling elements
    GRAPHQLDOCS_DEFAULTS = {
      # initialize
      filename: nil,
      schema: nil,

      # Generating
      delete_output: false,
      output_dir: "./output/",
      pipeline_config: {
        pipeline:
          %i[ExtendedMarkdownFilter
            EmojiFilter
            TableOfContentsFilter],
        context: {
          gfm: false,
          unsafe: true, # necessary for layout needs, given that it's all HTML templates
          asset_root: "https://a248.e.akamai.net/assets.github.com/images/icons"
        }
      },
      renderer: GraphQLDocs::Renderer,
      use_default_styles: true,
      base_url: "",

      templates: {
        default: "#{File.dirname(__FILE__)}/layouts/default.html",

        includes: "#{File.dirname(__FILE__)}/layouts/includes",

        operations: "#{File.dirname(__FILE__)}/layouts/graphql_operations.html",
        objects: "#{File.dirname(__FILE__)}/layouts/graphql_objects.html",
        queries: "#{File.dirname(__FILE__)}/layouts/graphql_queries.html",
        mutations: "#{File.dirname(__FILE__)}/layouts/graphql_mutations.html",
        interfaces: "#{File.dirname(__FILE__)}/layouts/graphql_interfaces.html",
        enums: "#{File.dirname(__FILE__)}/layouts/graphql_enums.html",
        unions: "#{File.dirname(__FILE__)}/layouts/graphql_unions.html",
        input_objects: "#{File.dirname(__FILE__)}/layouts/graphql_input_objects.html",
        scalars: "#{File.dirname(__FILE__)}/layouts/graphql_scalars.html",
        directives: "#{File.dirname(__FILE__)}/layouts/graphql_directives.html"
      },

      landing_pages: {
        index: "#{File.dirname(__FILE__)}/landing_pages/index.md",
        query: "#{File.dirname(__FILE__)}/landing_pages/query.md",
        object: "#{File.dirname(__FILE__)}/landing_pages/object.md",
        mutation: "#{File.dirname(__FILE__)}/landing_pages/mutation.md",
        interface: "#{File.dirname(__FILE__)}/landing_pages/interface.md",
        enum: "#{File.dirname(__FILE__)}/landing_pages/enum.md",
        union: "#{File.dirname(__FILE__)}/landing_pages/union.md",
        input_object: "#{File.dirname(__FILE__)}/landing_pages/input_object.md",
        scalar: "#{File.dirname(__FILE__)}/landing_pages/scalar.md",
        directive: "#{File.dirname(__FILE__)}/landing_pages/directive.md",

        variables: {} # only used for ERB landing pages
      },

      classes: {
        field_entry: "",
        deprecation_notice: "",
        notice: "",
        notice_title: ""
      }
    }.freeze
  end
end
