require 'graphql-docs/client'
require 'graphql-docs/parser'
require 'graphql-docs/version'

begin
  require 'awesome_print'
rescue LoadError; end

module GraphQLDocs
  class << self
    def generate(options)
      client = GraphQLDocs::Client.new(options)
      response = client.fetch
      parser = GraphQLDocs::Parser.new(response)
      parser.parse
    end
  end
end
