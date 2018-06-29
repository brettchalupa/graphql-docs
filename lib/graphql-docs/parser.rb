# frozen_string_literal: true
require 'graphql'

module GraphQLDocs
  class Parser
    include Helpers

    attr_reader :processed_schema

    def initialize(schema, options)
      @options = options

      @options[:notices] ||= -> (schema_member_path) { [] }

      if schema.is_a?(GraphQL::Schema)
        @schema = schema
      else
        @schema = GraphQL::Schema.from_definition(schema)
      end

      @processed_schema = {
        operation_types: [],
        mutation_types: [],
        object_types: [],
        interface_types: [],
        enum_types: [],
        union_types: [],
        input_object_types: [],
        scalar_types: [],
      }
    end

    def parse

      root_types = {}
      ['query', 'mutation'].each do |operation|
        unless @schema.root_type_for_operation(operation).nil?
          root_types[operation] = @schema.root_type_for_operation(operation).name
        end
      end
      @processed_schema[:root_types] = root_types

      @schema.types.each_value do |object|
        data = {}

        data[:notices] = @options[:notices].call(object.name)

        case object
        when ::GraphQL::ObjectType
          if object.name == root_types['query']
            data[:name] = object.name
            data[:description] = object.description

            data[:interfaces] = object.interfaces.map(&:name).sort
            data[:fields], data[:connections] = fetch_fields(object.fields, object.name)

            @processed_schema[:operation_types] << data
          elsif object.name == root_types['mutation']
            data[:name] = object.name
            data[:description] = object.description

            @processed_schema[:operation_types] << data

            object.fields.each_value do |mutation|
              h = {}

              h[:notices] = @options[:notices].call([object.name, mutation.name].join('.'))
              h[:name] = mutation.name
              h[:description] = mutation.description
              h[:input_fields], _ = fetch_fields(mutation.arguments, [object.name, mutation.name].join('.'))

              return_type = mutation.type
              if return_type.unwrap.respond_to?(:fields)
                h[:return_fields], _ = fetch_fields(return_type.unwrap.fields, return_type.name)
              else # it is a scalar return type
                h[:return_fields], _ = fetch_fields({ "#{return_type.name}" => mutation }, return_type.name)
              end

              @processed_schema[:mutation_types] << h
            end
          else
            data[:name] = object.name
            data[:description] = object.description

            data[:interfaces] = object.interfaces.map(&:name).sort
            data[:fields], data[:connections] = fetch_fields(object.fields, object.name)

            @processed_schema[:object_types] << data
          end
        when ::GraphQL::InterfaceType
          data[:name] = object.name
          data[:description] = object.description
          data[:fields], data[:connections] = fetch_fields(object.fields, object.name)

          @processed_schema[:interface_types] << data
        when ::GraphQL::EnumType
          data[:name] = object.name
          data[:description] = object.description

          data[:values] = object.values.values.map do |val|
            h = {}
            h[:notices] = @options[:notices].call([object.name, val.name].join('.'))
            h[:name] = val.name
            h[:description] = val.description
            unless val.deprecation_reason.nil?
              h[:is_deprecated] = true
              h[:deprecation_reason] = val.deprecation_reason
            end
            h
          end

          @processed_schema[:enum_types] << data
        when ::GraphQL::UnionType
          data[:name] = object.name
          data[:description] = object.description
          data[:possible_types] = object.possible_types.map(&:name).sort

          @processed_schema[:union_types] << data
        when ::GraphQL::InputObjectType
          data[:name] = object.name
          data[:description] = object.description

          data[:input_fields], _ = fetch_fields(object.input_fields, object.name)

          @processed_schema[:input_object_types] << data
        when ::GraphQL::ScalarType
          data[:name] = object.name
          data[:description] = object.description

          @processed_schema[:scalar_types] << data
        else
          raise TypeError, "I'm not sure what #{object.class} is!"
        end
      end

      @processed_schema[:mutation_types].sort_by! { |o| o[:name] }
      @processed_schema[:object_types].sort_by! { |o| o[:name] }
      @processed_schema[:interface_types].sort_by! { |o| o[:name] }
      @processed_schema[:enum_types].sort_by! { |o| o[:name] }
      @processed_schema[:union_types].sort_by! { |o| o[:name] }
      @processed_schema[:input_object_types].sort_by! { |o| o[:name] }
      @processed_schema[:scalar_types].sort_by! { |o| o[:name] }

      @processed_schema[:interface_types].each do |interface|
        interface[:implemented_by] = []
        @processed_schema[:object_types].each do |obj|
          if obj[:interfaces].include?(interface[:name])
            interface[:implemented_by] << obj[:name]
          end
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

        hash[:notices] = @options[:notices].call([parent_path, field.name].join('.'))
        hash[:name] = field.name
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
            h[:name] = arg.name
            h[:description] = arg.description
            h[:type] = generate_type(arg.type)
            if arg.default_value?
              h[:default_value] = arg.default_value
            end
            hash[:arguments] << h
          end
        end

        if !argument?(field) && field.connection?
          connections << hash
        else
          fields << hash
        end
      end

      [fields, connections]
    end

    def generate_type(type)
      name = type.unwrap.to_s
      path = case type.unwrap
             when ::GraphQL::ObjectType
               if name == 'Query'
                 'operation'
               else
                 'object'
               end
             when ::GraphQL::ScalarType
               'scalar'
             when ::GraphQL::InterfaceType
               'interface'
             when ::GraphQL::EnumType
               'enum'
             when ::GraphQL::InputObjectType
               'input_object'
             when ::GraphQL::UnionType
               'union'
             else
               raise TypeError, "Unknown type: `#{type.unwrap.class}`"
             end

      {
        name: name,
        path: path + '/' + slugify(name),
        info: type.to_s
      }
    end

    def argument?(field)
      field.is_a?(::GraphQL::Argument)
    end
  end
end
