require 'graphql'

module GraphQLDocs
  class Parser
    include Helpers

    attr_reader :processed_schema

    def initialize(schema, options)
      @options = options
      @schema = GraphQL::Schema.from_definition(schema)
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
      @schema.types.values.each do |object|
        data = {}

        case object
        when ::GraphQL::ObjectType
          if object.name == 'Query'
            data[:name] = object.name
            data[:description] = object.description

            data[:interfaces] = object.interfaces.map(&:name).sort
            data[:fields], data[:connections] = fetch_fields(object.fields)

            @processed_schema[:operation_types] << data
          elsif object.name == 'Mutation'
              data[:name] = object.name
              data[:description] = object.description

              @processed_schema[:operation_types] << data

              object.fields.values.each do |mutation|
                h = {}
                h[:name] = mutation.name
                h[:description] = mutation.description
                h[:input_fields], _ = fetch_fields(mutation.arguments.values.first.type.unwrap.input_fields)
                h[:return_fields], _ = fetch_fields(mutation.type.unwrap.fields)

                @processed_schema[:mutation_types] << h
              end
          else
            data[:name] = object.name
            data[:description] = object.description

            data[:interfaces] = object.interfaces.map(&:name).sort
            data[:fields], data[:connections] = fetch_fields(object.fields)

            @processed_schema[:object_types] << data
          end
        when ::GraphQL::InterfaceType
          data[:name] = object.name
          data[:description] = object.description
          data[:fields], data[:connections] = fetch_fields(object.fields)

          @processed_schema[:interface_types] << data
        when ::GraphQL::EnumType
          data[:name] = object.name
          data[:description] = object.description

          data[:values] = object.values.values.map do |val|
            h = {}
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

          data[:input_fields], _ = fetch_fields(object.input_fields)

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
        interface[:possible_types] = []
        @processed_schema[:object_types].each do |obj|
          if obj[:interfaces].include?(interface[:name])
            interface[:possible_types] << obj[:name]
          end
        end
      end

      @processed_schema
    end

    private

    def fetch_fields(object_fields)
      fields = connections = []

      object_fields.values.each do |field|
        hash = {}

        hash[:name] = field.name
        hash[:description] = field.description
        if field.respond_to?(:deprecation_reason) && !field.deprecation_reason.nil?
          hash[:is_deprecated] = true
          hash[:deprecation_reason] = field.deprecation_reason
        end

        hash[:type] = generate_type(field.type)

        if field.respond_to?(:arguments)
          hash[:arguments] = []
          field.arguments.values.each do |arg|
            h = {}
            h[:name] = arg.name
            h[:description] = arg.description
            h[:type] = generate_type(arg.type)

            hash[:arguments] << h
          end
        end

        if field.type.unwrap.name.end_with?('Connection')
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
      name =  type.unwrap.to_s
      {
        name: name,
        path: path + '/' + slugify(name),
        info: type.to_s
      }
    end
  end
end
