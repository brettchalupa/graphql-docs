# rubocop:disable Style/FileName
require 'graphql-docs/helpers'
require 'graphql-docs/renderer'
require 'graphql-docs/configuration'
require 'graphql-docs/generator'
require 'graphql-docs/parser'
require 'graphql-docs/version'

begin
  require 'awesome_print'
  require 'pry'
rescue LoadError; end

module GraphQLDocs
  class << self
    def build(options)
      options = GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS.merge(options)

      filename = options[:filename]
      schema = options[:schema]

      if !filename.nil? && !schema.nil?
        raise ArgumentError, 'Pass in `filename` or `schema`, but not both!'
      end

      if filename.nil? && schema.nil?
        raise ArgumentError, 'Pass in either `filename` or `schema`'
      end

      if filename
        unless filename.is_a?(String)
          raise TypeError, "Expected `String`, got `#{filename.class}`"
        end

        unless File.exist?(filename)
          raise ArgumentError, "#{filename} does not exist!"
        end

        schema = File.read(filename)
      else
        unless schema.is_a?(String)
          raise TypeError, "Expected `String`, got `#{schema.class}`"
        end

        schema = schema
      end

      parser = GraphQLDocs::Parser.new(schema, options)
      parsed_schema = parser.parse

      generator = GraphQLDocs::Generator.new(parsed_schema, options)

      generator.generate
    end
  end
end
