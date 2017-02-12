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

If you already have the JSON locally, great! Call the same method with `path` instead:

``` ruby
GraphQLDocs.build(path: "location/to/sw-api.json")
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

## Breakdown

There are three phases going on in one little `GraphQLDocs.build` call:

* The GraphQL JSON is _fetched_ (if you passed `url`) through `GraphQL::Client` (or simply read if you passed `path`).
* `GraphQL::Parser` manipulates that JSON into a slightly saner format.
* `GraphQL::Generator` takes that JSON and converts it into HTML.

If you wanted to, you could break these calls up individually:

``` ruby
client = GraphQLDocs::Client.new(options)
response = client.fetch

# do something

parser = GraphQLDocs::Parser.new(response, options)
parsed_schema = parser.parse

# do something else
generator = Generator.new(parsed_schema, options)

generator.generate
```

## Generating output

The HTML generation process uses [html-pipeline](https://github.com/jch/html-pipeline) and ERB to style the output. There are a bunch of default options provided for you, but feel free to override any of these. The *Configuration* section below has more information on what you can change.

## Development

After checking out the repo, run `script/bootstrap` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.
