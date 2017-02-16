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
          %w(ExtendedMarkdownFilter
           HTTPSFilter
           RougeFilter
           EmojiFilter
           PageTocFilter),
        context: {
          gfm: false,
          http_url: 'https://github.com',
          base_url: '/',
          asset_root: 'https://a248.e.akamai.net/assets.github.com/images/icons'
        }
      },
      templates: {
        includes: "#{File.dirname(__FILE__)}/layouts/includes",
        objects: "#{File.dirname(__FILE__)}/layouts/graphql_objects.html",
        mutations: "#{File.dirname(__FILE__)}/layouts/graphql_mutations.html"
      }
    }
  end
end
