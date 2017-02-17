module GraphQLDocs
  module Configuration
    GRAPHQLDOCS_DEFAULTS = {
      # Client
      access_token: nil,
      login: nil,
      password: nil,
      path: nil,
      url: nil,

      # Generating
      output_dir: './output/',
      pipeline_config: {
        pipeline:
          %i(ExtendedMarkdownFilter
           EmojiFilter
           TableOfContentsFilter),
        context: {
          gfm: false,
          asset_root: 'https://a248.e.akamai.net/assets.github.com/images/icons'
        }
      },

      renderer: GraphQLDocs::Renderer,

      templates: {
        includes: "#{File.dirname(__FILE__)}/layouts/includes",
        objects: "#{File.dirname(__FILE__)}/layouts/graphql_objects.html",
        mutations: "#{File.dirname(__FILE__)}/layouts/graphql_mutations.html",
        interfaces: "#{File.dirname(__FILE__)}/layouts/graphql_interfaces.html",
        enums: "#{File.dirname(__FILE__)}/layouts/graphql_enums.html",
        unions: "#{File.dirname(__FILE__)}/layouts/graphql_unions.html",
        input_objects: "#{File.dirname(__FILE__)}/layouts/graphql_input_objects.html",
        scalars: "#{File.dirname(__FILE__)}/layouts/graphql_scalars.html"
      }
    }.freeze
  end
end
