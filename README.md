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
client = GraphQLDocs.generate(url: "http://graphql.org/swapi-graphql/")
```

If your GraphQL endpoint requires authentication, you can provide a username or password, or an access token:

``` ruby
options = {
  url: "http://graphql.org/swapi-graphql/"
  login: "gjtorikian",
  password: "lolnowai"
}
client = GraphQLDocs.generate(options)

options = {
  url: "http://graphql.org/swapi-graphql/"
  access_token: "something123"
}

client = GraphQLDocs.generate(options)
```

Then, call `fetch`:

``` ruby
client.fetch
```

## Development

After checking out the repo, run `script/bootstrap` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.
