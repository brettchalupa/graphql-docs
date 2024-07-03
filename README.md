# GraphQLDocs

Ruby library and CLI for easily generating beautiful documentation from your GraphQL schema.

![sample](https://cloud.githubusercontent.com/assets/64050/23438604/6a23add0-fdc7-11e6-8852-ef41e8451033.png)

## Installation

Add the gem to your project with this command:

```console
bundle add graphql-docs
```

Or install it yourself as:

```console
gem install graphql-docs
```

## Usage

GraphQLDocs can be used as a Ruby library to build the documentation website. Using it as a Ruby library allows for more control and using every supported option. Here's an example:

```ruby
# pass in a filename
GraphQLDocs.build(filename: filename)

# or pass in a string
GraphQLDocs.build(schema: contents)

# or a schema class
schema = GraphQL::Schema.define do
  query query_type
end
GraphQLDocs.build(schema: schema)
```

GraphQLDocs also has a simplified CLI (`graphql-docs`) that gets installed with the gem:

```console
graphql-docs schema.graphql
```

That will generate the output in the `output` dir.

See all of the supported CLI options with:

```console
graphql-docs -h
```

## Breakdown

There are several phases going on the single `GraphQLDocs.build` call:

- The GraphQL IDL file is read (if you passed `filename`) through `GraphQL::Client` (or simply read if you passed a string through `schema`).
- `GraphQL::Parser` manipulates the IDL into a slightly saner format.
- `GraphQL::Generator` takes that saner format and begins the process of applying items to the HTML templates.
- `GraphQL::Renderer` technically runs as part of the generation phase. It passes the contents of each page and converts it into HTML.

If you wanted to, you could break these calls up individually. For example:

```ruby
options = {}
options[:filename] = "#{File.dirname(__FILE__)}/../data/graphql/schema.idl"
options[:renderer] = MySuperCoolRenderer

options = GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS.merge(options)

response = File.read(options[:filename])

parser = GraphQLDocs::Parser.new(response, options)
parsed_schema = parser.parse

generator = GraphQLDocs::Generator.new(parsed_schema, options)

generator.generate
```

## Generating output

By default, the HTML generation process uses ERB to layout the content. There are a bunch of default options provided for you, but feel free to override any of these. The _Configuration_ section below has more information on what you can change.

It also uses [html-pipeline](https://github.com/jch/html-pipeline) to perform the rendering by default. You can override this by providing a custom rendering class.You must implement two methods:

- `initialize` - Takes two arguments, the parsed `schema` and the configuration `options`.
- `render` Takes the contents of a template page. It also takes two optional kwargs, the GraphQL `type` and its `name`. For example:

```ruby
class CustomRenderer
  def initialize(parsed_schema, options)
    @parsed_schema = parsed_schema
    @options = options
  end

  def render(contents, type: nil, name: nil)
    contents.sub(/Repository/i, '<strong>Meow Woof!</strong>')

    opts[:content] = contents
    @graphql_default_layout.result(OpenStruct.new(opts).instance_eval { binding })
  end
end

options[:filename] = 'location/to/sw-api.graphql'
options[:renderer] = CustomRenderer

GraphQLDocs.build(options)
```

If your `render` method returns `nil`, the `Generator` will not attempt to write any HTML file.

### Templates

The layouts for the individual GraphQL pages are ERB templates, but you can also use ERB templates for your static landing pages.

If you want to add additional variables for your landing pages, you can add define a `variables` hash within the `landing_pages` option.

### Helper methods

In your ERB layouts, there are several helper methods you can use. The helper methods are:

- `slugify(str)` - This slugifies the given string.
- `include(filename, opts)` - This embeds a template from your `includes` folder, passing along the local options provided.
- `markdownify(string)` - This converts a string into HTML via CommonMarker.
- `graphql_operation_types`, `graphql_mutation_types`, `graphql_object_types`, `graphql_interface_types`, `graphql_enum_types`, `graphql_union_types`, `graphql_input_object_types`, `graphql_scalar_types`, `graphql_directive_types` - Collections of the various GraphQL types.

To call these methods within templates, you must use the dot notation, such as `<%= slugify.(text) %>`.

## Configuration

The following options are available:

| Option               | Description                                                                                                                                                                                                                    | Default                                                                                                                                               |
| :------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `filename`           | The location of your schema's IDL file.                                                                                                                                                                                        | `nil`                                                                                                                                                 |
| `schema`             | A string representing a schema IDL file.                                                                                                                                                                                       | `nil`                                                                                                                                                 |
| `output_dir`         | The location of the output HTML.                                                                                                                                                                                               | `./output/`                                                                                                                                           |
| `use_default_styles` | Indicates if you want to use the default styles.                                                                                                                                                                               | `true`                                                                                                                                                |
| `base_url`           | Indicates the base URL to prepend for assets and links.                                                                                                                                                                        | `""`                                                                                                                                                  |
| `delete_output`      | Deletes `output_dir` before generating content.                                                                                                                                                                                | `false`                                                                                                                                               |
| `pipeline_config`    | Defines two sub-keys, `pipeline` and `context`, which are used by `html-pipeline` when rendering your output.                                                                                                                  | `pipeline` has `ExtendedMarkdownFilter`, `EmojiFilter`, and `TableOfContentsFilter`. `context` has `gfm: false` and `asset_root` set to GitHub's CDN. |
| `renderer`           | The rendering class to use.                                                                                                                                                                                                    | `GraphQLDocs::Renderer`                                                                                                                               |
| `templates`          | The templates to use when generating HTML. You may override any of the following keys: `default`, `includes`, `operations`, `objects`, `mutations`, `interfaces`, `enums`, `unions`, `input_objects`, `scalars`, `directives`. | The defaults are found in _lib/graphql-docs/layouts/_.                                                                                                |
| `landing_pages`      | The landing page to use when generating HTML for each type. You may override any of the following keys: `index`, `query`, `object`, `mutation`, `interface`, `enum`, `union`, `input_object`, `scalar`, `directive`.           | The defaults are found in _lib/graphql-docs/landing_pages/_.                                                                                          |
| `classes`            | Additional class names you can provide to certain elements.                                                                                                                                                                    | The full list is available in _lib/graphql-docs/configuration.rb_.                                                                                    |
| `notices`            | A proc used to add notices to schema members. See _Customizing Notices_ section below.                                                                                                                                         | `nil`                                                                                                                                                 |

### Customizing Notices

A notice is a block of CommonMark text that optionally has a title which is displayed above a schema member's description. The
look of a notice block can be controlled by specifying a custom class for it and then styled via CSS.

The `notices` option allows you to customize the notices that appear for a specific schema member using a proc.

The proc will be called for each schema member and needs to return an array of notices or an empty array if there are none.

A `notice` has the following options:

| Option        | Description                                               |
| :------------ | :-------------------------------------------------------- |
| `body`        | CommonMark body of the notice                             |
| `title`       | Optional title of the notice                              |
| `class`       | Optional CSS class for the wrapper `<div>` of the notice  |
| `title_class` | Optional CSS class for the `<span>` of the notice's title |

Example of a `notices` proc that adds a notice to the `TeamDiscussion` type:

```ruby
options[:notices] = ->(schema_member_path) {
  notices = []

  if schema_member_path == "TeamDiscussion"
    notices << {
      class: "preview-notice",
      body: "Available via the [Team Discussion](/previews/team-discussion) preview.",
    }
  end

  notices
}
```

The format of `schema_member_path` is a dot delimited path to the schema member. For example:

```ruby
"Author", # an object
"ExtraInfo" # an interface,
"Author.socialSecurityNumber" # a field
"Book.author.includeMiddleInitial" # an argument
"Likeable" # a union,
"Cover" # an enum
"Cover.DIGITAL" # an enum value
"BookOrder" # an input object
"Mutation.addLike" # a mutation
```

## Supported Ruby Versions

The gem officially supports **Ruby 3.1 and newer**.

Any dropping of Ruby version support is considered a breaking change and means a major release for the gem.

## Upgrading

This project aims to strictly follow [Semantic Versioning](https://semver.org/).
Minor and patch level updates can be done with pretty high confidence that your usage won't break.

Review the
[Changelog](https://github.com/brettchalupa/graphql-docs/blob/main/CHANGELOG.md)
for detailed changes for each release. The intent is to make upgrading as
painless as possible.

## Roadmap

Upcoming work for the project is organized publicly via [GitHub
Projects](https://github.com/users/brettchalupa/projects/7/views/1).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`bin/rake test` to run the tests. You can also run `bin/console` for
an interactive prompt that will allow you to experiment.

## Sample Site

Clone this repository and run:

```
bin/rake sample:generate
```

to see some sample output in the `output` dir.

Boot up a server to view it:

```
bin/rake sample:serve
```

## Credits

Originally built by [gjtorikian](https://github.com/gjtorikian). Actively maintained by [brettchalupa](https://github.com/brettchalupa).
