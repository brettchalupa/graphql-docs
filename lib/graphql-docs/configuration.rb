# frozen_string_literal: true
module GraphQLDocs
  module Configuration
    GRAPHQLDOCS_DEFAULTS = {
      # initialize
      filename: nil,
      schema: nil,

      # Generating
      delete_output: false,
      output_dir: './output/',
      pipeline_config: {
        pipeline:
          %i(ExtendedMarkdownFilter
           EmojiFilter
           TableOfContentsFilter),
        context: {
          gfm: false,
          unsafe: true, # necessary for layout needs, given that it's all HTML templates
          asset_root: 'https://a248.e.akamai.net/assets.github.com/images/icons'
        }
      },
      renderer: GraphQLDocs::Renderer,
      use_default_styles: true,
      base_url: '',

      templates: {
        default: "#{File.dirname(__FILE__)}/layouts/default.html",

        includes: "#{File.dirname(__FILE__)}/layouts/includes",

        operations: "#{File.dirname(__FILE__)}/layouts/graphql_operations.html",
        objects: "#{File.dirname(__FILE__)}/layouts/graphql_objects.html",
        mutations: "#{File.dirname(__FILE__)}/layouts/graphql_mutations.html",
        interfaces: "#{File.dirname(__FILE__)}/layouts/graphql_interfaces.html",
        enums: "#{File.dirname(__FILE__)}/layouts/graphql_enums.html",
        unions: "#{File.dirname(__FILE__)}/layouts/graphql_unions.html",
        input_objects: "#{File.dirname(__FILE__)}/layouts/graphql_input_objects.html",
        scalars: "#{File.dirname(__FILE__)}/layouts/graphql_scalars.html",
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
        scalar: "#{File.dirname(__FILE__)}/landing_pages/scalar.md"
      },

      classes: {
        field_entry: '',
        deprecation_notice: '',
        notice: '',
        notice_title: '',
      }
    }.freeze
  end
end
