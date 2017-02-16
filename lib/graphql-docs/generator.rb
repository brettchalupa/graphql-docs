require 'html/pipeline'
require 'liquid'

module GraphQLDocs
  class Generator
    def initialize(parsed_schema, options)
      @parsed_schema = parsed_schema
      @options = options
      @pipeline_config = @options[:pipeline_config]
      @pipeline = HTML::Pipeline.new @pipeline_config[:pipeline], @pipeline_config[:context]

      @graphql_object_template = Liquid::Template.parse(File.read(@options[:templates][:objects]))
      @graphql_mutations_template = Liquid::Template.parse(File.read(@options[:templates][:mutations]))

      Liquid::Template.file_system = Liquid::LocalFileSystem.new(File.join(@options[:templates][:includes]), '%s.html')
    end

    def generate
      FileUtils.rm_rf(@options[:output_dir])
      create_graphql_object_pages
      create_graphql_mutation_pages

      true
    end

    def create_graphql_object_pages
      graphql_object_types.each do |object_type|
        next if object_type['name'].start_with?('__')
        contents = @graphql_object_template.render('type' => object_type)
        write_file('object', object_type['name'], contents)
      end
    end

    def create_graphql_mutation_pages
      graphql_mutation_types.each do |mutation|
        payload = graphql_object_types.find { |t| t['name'] == mutation['type']['name'] }
        input = graphql_input_object_types.find { |t| t['name'] = mutation['args'].first['type']['ofType']['name'] }
        contents = @graphql_mutations_template.render('type' => mutation, 'input' => input, 'return' => payload)
        write_file('mutation', mutation['name'], contents)
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
      path = File.join(@options[:output_dir], type, name)
      FileUtils.mkdir_p(path)
      File.write(File.join(path, 'index.html'), contents)
    end
  end
end
