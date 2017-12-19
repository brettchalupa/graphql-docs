# GraphQLDocs

Easily generate beautiful documentation from your GraphQL schema.

![sample](https://cloud.githubusercontent.com/assets/64050/23438604/6a23add0-fdc7-11e6-8852-ef41e8451033.png)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'graphql-docs'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install graphql-docs

## Usage

``` ruby
# pass in a filename
GraphQLDocs.build(filename: filename)

# or pass in a string
GraphQLDocs.build(schema: contents)
```

## Breakdown

There are several phases going on the single `GraphQLDocs.build` call:

* The GraphQL IDL file is read (if you passed `filename`) through `GraphQL::Client` (or simply read if you passed a string through `schema`).
* `GraphQL::Parser` manipulates the IDL into a slightly saner format.
* `GraphQL::Generator` takes that saner format and begins the process of applying items to the HTML templates.
* `GraphQL::Renderer` technically runs as part of the generation phase. It passes the contents of each page and converts it into HTML.

If you wanted to, you could break these calls up individually. For example:

``` ruby
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

By default, the HTML generation process uses ERB to layout the content. There are a bunch of default options provided for you, but feel free to override any of these. The *Configuration* section below has more information on what you can change.

It also uses [html-pipeline](https://github.com/jch/html-pipeline) to perform the rendering by default. You can override this by providing a custom rendering class.You must implement two methods:

* `initialize` - Takes two arguments, the parsed `schema` and the configuration `options`.
* `render` Takes the contents of a template page. It also takes two optional kwargs, the GraphQL `type` and its `name`. For example:

``` ruby
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

### Helper methods

In your ERB layouts, there are several helper methods you can use. The helper methods are:

* `slugify(str)` - This slugifies the given string.
* `include(filename, opts)` - This embeds a template from your `includes` folder, passing along the local options provided.
* `markdownify(string)` - This converts a string into HTML via CommonMarker.
* `graphql_operation_types`, `graphql_mutation_types`, `graphql_object_types`, `graphql_interface_types`, `graphql_enum_types`, `graphql_union_types`, `graphql_input_object_types`, `graphql_scalar_types` - Collections of the various GraphQL types.

To call these methods within templates, you must use the dot notation, such as `<%= slugify.(text) %>`.

For `markdownify`, `CommonMarker` is not enabled by default (because it relies on native code). You will need to add `require 'commonmarker'` if you wish to use it.
## Configuration

The following options are available:

| Option | Description | Default |
| :----- | :---------- | :------ |
| `filename` | The location of your schema's IDL file. | `nil` |
| `schema` | A string representing a schema IDL file. | `nil` |
| `output_dir` | The location of the output HTML. | `./output/` |
| `use_default_styles` | Indicates if you want to use the default styles. | `true` |
| `base_url` | Indicates the base URL to prepend for assets and links. | `""` |
| `delete_output` | Deletes `output_dir` before generating content. | `false` |
| `pipeline_config` | Defines two sub-keys, `pipeline` and `context`, which are used by `html-pipeline` when rendering your output. | `pipeline` has `ExtendedMarkdownFilter`, `EmojiFilter`, and `TableOfContentsFilter`. `context` has `gfm: false` and `asset_root` set to GitHub's CDN. |
| `renderer` | The rendering class to use. | `GraphQLDocs::Renderer`
| `templates` | The templates to use when generating HTML. You may override any of the following keys: `default`, `includes`, `operations`, `objects`, `mutations`, `interfaces`, `enums`, `unions`, `input_objects`, `scalars`. | The defaults are found in _lib/graphql-docs/layouts/_.
| `landing_pages` | The landing page to use when generating HTML for each type. You may override any of the following keys: `index`, `query`, `object`, `mutation`, `interface`, `enum`, `union`, `input_object`, `scalar`. | The defaults are found in _lib/graphql-docs/layouts/_.
| `classes` | Additional class names you can provide to certain elements. | The full list is available in _lib/graphql-docs/configuration.rb/_.

## Development

After checking out the repo, run `script/bootstrap` to install dependencies. Then, run `rake test` to run the tests. You can also run `bundle exec rake console` for an interactive prompt that will allow you to experiment.

## Sample site

Clone this repository and run:

```
bundle exec rake sample
```

to see some sample output.
