require 'erb'
require 'graphql-docs/generator/helpers'

module GraphQLDocs
  class Generator
    include Helpers

    def initialize(parsed_schema, options)
      @parsed_schema = parsed_schema
      @options = options

      @renderer = Renderer.new(@options)

      @graphql_object_template = ERB.new(File.read(@options[:templates][:objects]))
      @graphql_mutations_template = ERB.new(File.read(@options[:templates][:mutations]))
      @graphql_interfaces_template = ERB.new(File.read(@options[:templates][:interfaces]))
      @graphql_enums_template = ERB.new(File.read(@options[:templates][:enums]))
      @graphql_unions_template = ERB.new(File.read(@options[:templates][:unions]))
      @graphql_input_objects_template = ERB.new(File.read(@options[:templates][:input_objects]))
      @graphql_scalars_template = ERB.new(File.read(@options[:templates][:scalars]))
    end

    def generate
      FileUtils.rm_rf(@options[:output_dir])

      create_graphql_object_pages
      create_graphql_mutation_pages
      create_graphql_interface_pages
      create_graphql_enum_pages
      create_graphql_union_pages
      create_graphql_input_object_pages
      create_graphql_scalar_pages

      true
    end

    def create_graphql_object_pages
      graphql_object_types.each do |object_type|
        next if object_type['name'].start_with?('__')
        opts = { type: object_type }.merge(helper_methods)
        contents = @graphql_object_template.result(OpenStruct.new(opts).instance_eval { binding })
        write_file('object', object_type['name'], contents)
      end
    end

    def create_graphql_mutation_pages
      graphql_mutation_types.each do |mutation|
        input = graphql_input_object_types.find { |t| t['name'] = mutation['args'].first['type']['ofType']['name'] }
        payload = graphql_object_types.find { |t| t['name'] == mutation['type']['name'] }

        opts = { type: mutation, input_fields: input, return_fields: payload }.merge(helper_methods)

        contents = @graphql_mutations_template.result(OpenStruct.new(opts).instance_eval { binding })
        write_file('mutation', mutation['name'], contents)
      end
    end

    def create_graphql_interface_pages
      graphql_interface_types.each do |interface_type|
        opts = { type: interface_type }.merge(helper_methods)

        contents = @graphql_interfaces_template.result(OpenStruct.new(opts).instance_eval { binding })
        write_file('interface', interface_type['name'], contents)
      end
    end

    def create_graphql_enum_pages
      graphql_enum_types.each do |enum_type|
        opts = { type: enum_type }.merge(helper_methods)

        contents = @graphql_enums_template.result(OpenStruct.new(opts).instance_eval { binding })
        write_file('enum', enum_type['name'], contents)
      end
    end

    def create_graphql_union_pages
      graphql_union_types.each do |union_type|
        opts = { type: union_type }.merge(helper_methods)

        contents = @graphql_unions_template.result(OpenStruct.new(opts).instance_eval { binding })
        write_file('union', union_type['name'], contents)
      end
    end

    def create_graphql_input_object_pages
      graphql_input_object_types.each do |input_object_type|
        opts = { type: input_object_type }.merge(helper_methods)

        contents = @graphql_input_objects_template.result(OpenStruct.new(opts).instance_eval { binding })
        write_file('input_object', input_object_type['name'], contents)
      end
    end

    def create_graphql_scalar_pages
      graphql_scalar_types.each do |scalar_type|
        opts = { type: scalar_type }.merge(helper_methods)

        contents = @graphql_scalars_template.result(OpenStruct.new(opts).instance_eval { binding })
        write_file('scalar', scalar_type['name'], contents)
      end
    end

    private

    def graphql_mutation_types
      graphql_object_types.find { |t| t['name'] == 'Mutation' }['fields']
    end

    def graphql_object_types
      @parsed_schema['object_types']
    end

    def graphql_interface_types
      @parsed_schema['interface_types']
    end

    def graphql_enum_types
      @parsed_schema['enum_types']
    end

    def graphql_union_types
      @parsed_schema['union_types']
    end

    def graphql_input_object_types
      @parsed_schema['input_object_types']
    end

    def graphql_scalar_types
      @parsed_schema['scalar_types']
    end

    def write_file(type, name, contents)
      path = File.join(@options[:output_dir], type, name.downcase)
      FileUtils.mkdir_p(path)
      contents = @renderer.render(contents)
      File.write(File.join(path, 'index.html'), contents)
    end
  end
end
