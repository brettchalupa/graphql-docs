require 'graphql-docs/client'
require 'graphql-docs/renderer'
require 'graphql-docs/configuration'
require 'graphql-docs/generator'
require 'graphql-docs/parser'
require 'graphql-docs/version'

begin
  require 'awesome_print'
rescue LoadError; end

module GraphQLDocs
  class << self
    def build(options)
      options = GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS.merge(options)

      if options[:url].nil? && options[:path].nil?
        fail ArgumentError, 'No :url or :path provided!'
      end

      if !options[:url].nil? && !options[:path].nil?
        fail ArgumentError, 'You can\'t pass both :url and :path!'
      end

      if options[:url]
        client = GraphQLDocs::Client.new(options)
        response = client.fetch
      else
        response = File.read(options[:path])
      end

      parser = GraphQLDocs::Parser.new(response, options)
      parsed_schema = parser.parse

      generator = Generator.new(parsed_schema, options)

      generator.generate
    end
  end
end
