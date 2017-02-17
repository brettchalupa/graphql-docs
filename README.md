# GraphQLDocs

Easily generate beautiful documentation from your GraphQL schema.

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

Simple! Call `GraphQLDocs.generate`, taking care to pass in the GraphQL endpoint:

``` ruby
GraphQLDocs.build(url: "http://graphql.org/swapi-graphql/")
```

If your GraphQL endpoint requires authentication, you can provide a username or password, or an access token:

``` ruby
options = {
  url: "http://graphql.org/swapi-graphql/"
  login: "gjtorikian",
  password: "lolnowai"
}
GraphQLDocs.build(options)

options = {
  url: "http://graphql.org/swapi-graphql/"
  access_token: "something123"
}

GraphQLDocs.build(options)
```

If you already have the JSON locally, great! Call the same method with `path` instead:

``` ruby
GraphQLDocs.build(path: 'location/to/sw-api.json')
```

## Breakdown

There are several phaseses going on in one little `GraphQLDocs.build` call:

* The GraphQL JSON is _fetched_ (if you passed `url`) through `GraphQL::Client` (or simply read if you passed `path`).
* `GraphQL::Parser` manipulates that JSON into a slightly saner format.
* `GraphQL::Generator` takes that JSON and converts it into HTML.
* `GraphQL::Parser` technically runs as part of the generation phase. It passes the contents of each page through a Markdown renderer.

If you wanted to, you could break these calls up individually. For example:

``` ruby
options = {}
options[:path] = "#{File.dirname(__FILE__)}/../data/graphql/docs.json"
my_renderer = MySuperCoolRenderer(options)
options[:renderer] = my_renderer

options = GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS.merge(options)

response = File.read(options[:path])

parser = GraphQLDocs::Parser.new(response, options)
parsed_schema = parser.parse

generator = GraphQLDocs::Generator.new(parsed_schema, options)

generator.generate
```

## Generating output

By default, the HTML generation process uses ERB to layout the content. There are a bunch of default options provided for you, but feel free to override any of these. The *Configuration* section below has more information on what you can change.

It also uses [html-pipeline](https://github.com/jch/html-pipeline) to perform the Markdown rendering by default. You can override this by providing a custom rendering class. The initialize must take at least one argument, which are the configuration options, and must implement one method, `render`, which takes a string, the GraphQL type, and the name. For example:

``` ruby
class CustomRenderer
  def initialize(options)
    @options = options
  end

  def render(string, type, name)
    string.sub(/Repository/i, 'Meow Woof!')
  end
end

options[:path] = 'location/to/sw-api.json'
options[:renderer] = CustomRenderer

GraphQLDocs.build(options)
```

### Helper methods

In your ERB layouts, there are several helper methods you can use. The helper methods are:

* `slugify(str)` - This slugifies the given string.
* `include(filename, opts)` - This embeds a template from your `includes` folder, passing along the local options provided.
* `markdown(string)` - This converts a string from Markdown to HTML.

To call these methods, you must use the dot notation, such as `<%= slugify.(text) %>`.

## Configuration

The following options are available:


| Option | Description | Default |
| :----- | :---------- | :------ |
| `access_token` | Uses this token while making requests through `GraphQLDocs::Client`. | `nil` |
| `login` | Uses this login while making requests through `GraphQLDocs::Client`. | `nil` |
| `password` | Uses this password while making requests through `GraphQLDocs::Client`. | `nil` |
| `path` | `GraphQLDocs::Client` loads a JSON file found at this location, representing the response from an introspection query. | `nil` |
| `url` | `GraphQLDocs::Client` makes a `POST` request to this URL, passing along the introspection query. | `nil` |
| `output_dir` | The location of the output HTML. | `./output/` |
| `pipeline_config` | Defines two sub-keys, `pipeline` and `context`, which are used by `html-pipeline` when rendering your output. | `pipeline` has `ExtendedMarkdownFilter`, `EmojiFilter`, and `PageTocFilter`. `context` has `gfm: false` and `asset_root` set to GitHub's CDN. |
| `renderer` | The rendering class to use. | `GraphQLDocs::Renderer`
| `templates` | The templates to use when generating HTML. You may override any of the following keys: `includes`, `objects`, `mutations`, `interfaces`, `enums`, `unions`, `input_objects`, `scalars`. | The default gem ones are found in _layouts/_.

## Development

After checking out the repo, run `script/bootstrap` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Sample site

Clone this repository and run:

```
bundle exec rake sample
```

to see some sample output.
