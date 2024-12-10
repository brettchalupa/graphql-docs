# frozen_string_literal: true

require 'graphql'

module GraphQLDocs
  class Parser
    include Helpers

    attr_reader :processed_schema

    def initialize(schema, options)
      @options = options

      @options[:notices] ||= ->(_schema_member_path) { [] }

      @schema = if schema.is_a?(String)
                  GraphQL::Schema.from_definition(schema)
                elsif schema < GraphQL::Schema
                  schema
                end

      @processed_schema = {
        operation_types: [],
        query_types: [],
        mutation_types: [],
        object_types: [],
        interface_types: [],
        enum_types: [],
        union_types: [],
        input_object_types: [],
        scalar_types: [],
        directive_types: []
      }
    end

    def parse
      root_types = {}
      %w[query mutation].each do |operation|
        root_types[operation] = @schema.root_type_for_operation(operation).graphql_name unless @schema.root_type_for_operation(operation).nil?
      end
      @processed_schema[:root_types] = root_types

      @schema.types.each_value do |object|
        data = {}

        data[:notices] = @options[:notices].call(object.graphql_name)

        if object < ::GraphQL::Schema::Object
          data[:name] = object.graphql_name
          data[:description] = object.description

          if data[:name] == root_types['query']
            data[:interfaces] = object.interfaces.map(&:graphql_name).sort
            data[:fields], data[:connections] = fetch_fields(object.fields, object.graphql_name)
            @processed_schema[:operation_types] << data

            object.fields.each_value do |query|
              h = {}

              h[:notices] = @options[:notices].call([object.graphql_name, query.graphql_name].join('.'))
              h[:name] = query.graphql_name
              h[:description] = query.description
              h[:arguments], = fetch_fields(query.arguments, [object.graphql_name, query.graphql_name].join('.'))

              return_type = query.type
              if return_type.unwrap.respond_to?(:fields)
                h[:return_fields], = fetch_fields(return_type.unwrap.fields, return_type.graphql_name)
              else # it is a scalar return type
                h[:return_fields], = fetch_fields({ return_type.graphql_name => query }, return_type.graphql_name)
              end

              @processed_schema[:query_types] << h
            end
          elsif data[:name] == root_types['mutation']
            @processed_schema[:operation_types] << data

            object.fields.each_value do |mutation|
              h = {}

              h[:notices] = @options[:notices].call([object.graphql_name, mutation.graphql_name].join('.'))
              h[:name] = mutation.graphql_name
              h[:description] = mutation.description
              h[:input_fields], = fetch_fields(mutation.arguments, [object.graphql_name, mutation.graphql_name].join('.'))

              return_type = mutation.type
              if return_type.unwrap.respond_to?(:fields)
                h[:return_fields], = fetch_fields(return_type.unwrap.fields, return_type.graphql_name)
              else # it is a scalar return type
                h[:return_fields], = fetch_fields({ return_type.graphql_name => mutation }, return_type.graphql_name)
              end

              @processed_schema[:mutation_types] << h
            end
          else
            data[:interfaces] = object.interfaces.map(&:graphql_name).sort
            data[:fields], data[:connections] = fetch_fields(object.fields, object.graphql_name)

            @processed_schema[:object_types] << data
          end
        elsif object < ::GraphQL::Schema::Interface
          data[:name] = object.graphql_name
          data[:description] = object.description
          data[:fields], data[:connections] = fetch_fields(object.fields, object.graphql_name)

          @processed_schema[:interface_types] << data
        elsif object < ::GraphQL::Schema::Enum
          data[:name] = object.graphql_name
          data[:description] = object.description

          data[:values] = object.values.values.map do |val|
            h = {}
            h[:notices] = @options[:notices].call([object.graphql_name, val.graphql_name].join('.'))
            h[:name] = val.graphql_name
            h[:description] = val.description
            unless val.deprecation_reason.nil?
              h[:is_deprecated] = true
              h[:deprecation_reason] = val.deprecation_reason
            end
            h
          end

          @processed_schema[:enum_types] << data
        elsif object < ::GraphQL::Schema::Union
          data[:name] = object.graphql_name
          data[:description] = object.description
          data[:possible_types] = object.possible_types.map(&:graphql_name).sort

          @processed_schema[:union_types] << data
        elsif object < GraphQL::Schema::InputObject
          data[:name] = object.graphql_name
          data[:description] = object.description

          data[:input_fields], = fetch_fields(object.arguments, object.graphql_name)

          @processed_schema[:input_object_types] << data
        elsif object < GraphQL::Schema::Scalar
          data[:name] = object.graphql_name
          data[:description] = object.description

          @processed_schema[:scalar_types] << data
        else
          raise TypeError, "I'm not sure what #{object.class} < #{object.superclass.name} is!"
        end
      end

      @schema.directives.each_value do |directive|
        data = {}
        data[:notices] = @options[:notices].call(directive.graphql_name)

        data[:name] = directive.graphql_name
        data[:description] = directive.description
        data[:locations] = directive.locations

        data[:arguments], = fetch_fields(directive.arguments, directive.graphql_name)

        @processed_schema[:directive_types] << data
      end

      sort_by_name!

      @processed_schema[:interface_types].each do |interface|
        interface[:implemented_by] = []
        @processed_schema[:object_types].each do |obj|
          interface[:implemented_by] << obj[:name] if obj[:interfaces].include?(interface[:name])
        end
      end

      @processed_schema
    end

    private

    def fetch_fields(object_fields, parent_path)
      fields = []
      connections = []

      object_fields.each_value do |field|
        hash = {}

        hash[:notices] = @options[:notices].call([parent_path, field.graphql_name].join('.'))
        hash[:name] = field.graphql_name
        hash[:description] = field.description
        if field.respond_to?(:deprecation_reason) && !field.deprecation_reason.nil?
          hash[:is_deprecated] = true
          hash[:deprecation_reason] = field.deprecation_reason
        end

        hash[:type] = generate_type(field.type)

        hash[:arguments] = []
        if field.respond_to?(:arguments)
          field.arguments.each_value do |arg|
            h = {}
            h[:name] = arg.graphql_name
            h[:description] = arg.description
            h[:type] = generate_type(arg.type)
            h[:default_value] = arg.default_value if arg.default_value?
            if arg.respond_to?(:deprecation_reason) && arg.deprecation_reason
              h[:is_deprecated] = true
              h[:deprecation_reason] = arg.deprecation_reason
            end
            hash[:arguments] << h
          end
        end

        if !argument?(field) && connection?(field)
          connections << hash
        else
          fields << hash
        end
      end

      [fields, connections]
    end

    def generate_type(type)
      name = type.unwrap.graphql_name

      path = if type.unwrap < GraphQL::Schema::Object
               if name == 'Query'
                 'operation'
               else
                 'object'
               end
             elsif type.unwrap < GraphQL::Schema::Scalar
               'scalar'
             elsif type.unwrap < GraphQL::Schema::Interface
               'interface'
             elsif type.unwrap < GraphQL::Schema::Enum
               'enum'
             elsif type.unwrap < GraphQL::Schema::InputObject
               'input_object'
             elsif type.unwrap < GraphQL::Schema::Union
               'union'
             else
               raise TypeError, "Unknown type for `#{name}`: `#{type.unwrap.class}`"
             end

      {
        name: name,
        path: "#{path}/#{slugify(name)}",
        info: type.to_type_signature
      }
    end

    def argument?(field)
      field.is_a?(::GraphQL::Schema::Argument)
    end

    def connection?(field)
      field.respond_to?(:connection?) && field.connection?
    end

    def sort_by_name!
      @processed_schema.each_pair do |key, value|
        next if value.empty?
        next if %i[operation_types root_types].include?(key)

        value.sort_by! { |o| o[:name] }
      end
    end
  end
end
