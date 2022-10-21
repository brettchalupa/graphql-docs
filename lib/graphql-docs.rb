# frozen_string_literal: true

require 'graphql-docs/helpers'
require 'graphql-docs/renderer'
require 'graphql-docs/configuration'
require 'graphql-docs/generator'
require 'graphql-docs/parser'
require 'graphql-docs/version'

module GraphQLDocs
  class << self
    def build(options)
      # do not let user provided values overwrite every single value
      %i[templates landing_pages].each do |opt|
        next unless options.key?(opt)

        GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS[opt].each_pair do |key, value|
          options[opt][key] = value unless options[opt].key?(key)
        end
      end

      options = GraphQLDocs::Configuration::GRAPHQLDOCS_DEFAULTS.merge(options)

      filename = options[:filename]
      schema = options[:schema]

      raise ArgumentError, 'Pass in `filename` or `schema`, but not both!' if !filename.nil? && !schema.nil?

      raise ArgumentError, 'Pass in either `filename` or `schema`' if filename.nil? && schema.nil?

      if filename
        raise TypeError, "Expected `String`, got `#{filename.class}`" unless filename.is_a?(String)

        raise ArgumentError, "#{filename} does not exist!" unless File.exist?(filename)

        schema = File.read(filename)
      else
        raise TypeError, "Expected `String` or `GraphQL::Schema`, got `#{schema.class}`" if !schema.is_a?(String) && !schema_type?(schema)

        schema = schema
      end

      parser = GraphQLDocs::Parser.new(schema, options)
      parsed_schema = parser.parse

      generator = GraphQLDocs::Generator.new(parsed_schema, options)

      generator.generate
    end

    private def schema_type?(object)
      object.respond_to?(:ancestors) && object.ancestors.include?(GraphQL::Schema)
    end
  end
end
