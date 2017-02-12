require 'html/pipeline'
require 'liquid'

module GraphQLDocs
  class Generator
    def initialize(parsed_schema, options)
      @parsed_schema = parsed_schema
      @options = options
      @pipeline_config = @options[:pipeline_config]
      @pipeline = HTML::Pipeline.new @pipeline_config[:pipeline], @pipeline_config[:context]

      @graphql_page_template = Liquid::Template.parse(File.read(@options[:templates][:objects]))
      Liquid::Template.file_system = Liquid::LocalFileSystem.new(File.join(@options[:templates][:includes]), '%s.html')
    end

    def generate
      create_graphql_object_pages

      true
    end

    def create_graphql_object_pages
      graphql_object_types.each do |object_type|
        next if object_type['name'].start_with?('__')
        contents = @graphql_page_template.render('type' => object_type)
        path = File.join(@options[:output_dir], 'object', object_type['name'].downcase)
        FileUtils.mkdir_p(path)
        File.write(File.join(path, 'index.html'), contents)
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
  end
end
