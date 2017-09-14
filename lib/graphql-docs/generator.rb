require 'erb'
require 'sass'

module GraphQLDocs
  class Generator
    include Helpers

    attr_accessor :parsed_schema

    def initialize(parsed_schema, options)
      @parsed_schema = parsed_schema
      @options = options

      @renderer = @options[:renderer].new(@parsed_schema, @options)

      @graphql_operation_template = ERB.new(File.read(@options[:templates][:operations]))
      @graphql_object_template = ERB.new(File.read(@options[:templates][:objects]))
      @graphql_mutations_template = ERB.new(File.read(@options[:templates][:mutations]))
      @graphql_interfaces_template = ERB.new(File.read(@options[:templates][:interfaces]))
      @graphql_enums_template = ERB.new(File.read(@options[:templates][:enums]))
      @graphql_unions_template = ERB.new(File.read(@options[:templates][:unions]))
      @graphql_input_objects_template = ERB.new(File.read(@options[:templates][:input_objects]))
      @graphql_scalars_template = ERB.new(File.read(@options[:templates][:scalars]))
    end

    def generate
      FileUtils.rm_rf(@options[:output_dir]) if @options[:delete_output]

      create_graphql_operation_pages
      create_graphql_object_pages
      create_graphql_mutation_pages
      create_graphql_interface_pages
      create_graphql_enum_pages
      create_graphql_union_pages
      create_graphql_input_object_pages
      create_graphql_scalar_pages

      unless @options[:landing_pages][:index].nil?
        write_file('static', 'index', File.read(@options[:landing_pages][:index]))
      end

      unless @options[:landing_pages][:object].nil?
        write_file('static', 'object', File.read(@options[:landing_pages][:object]))
      end

      unless @options[:landing_pages][:mutation].nil?
        write_file('operation', 'mutation', File.read(@options[:landing_pages][:mutation]))
      end

      unless @options[:landing_pages][:interface].nil?
        write_file('static', 'interface', File.read(@options[:landing_pages][:interface]))
      end

      unless @options[:landing_pages][:enum].nil?
        write_file('static', 'enum', File.read(@options[:landing_pages][:enum]))
      end

      unless @options[:landing_pages][:union].nil?
        write_file('static', 'union', File.read(@options[:landing_pages][:union]))
      end

      unless @options[:landing_pages][:input_object].nil?
        write_file('static', 'input_object', File.read(@options[:landing_pages][:input_object]))
      end

      unless @options[:landing_pages][:scalar].nil?
        write_file('static', 'scalar', File.read(@options[:landing_pages][:scalar]))
      end

      if @options[:use_default_styles]
        assets_dir = File.join(File.dirname(__FILE__), 'layouts', 'assets')
        FileUtils.mkdir_p(File.join(@options[:output_dir], 'assets'))

        sass = File.join(assets_dir, 'css', 'screen.scss')
        system `sass --sourcemap=none #{sass}:#{@options[:output_dir]}/assets/style.css`

        FileUtils.cp_r(File.join(assets_dir, 'images'), File.join(@options[:output_dir], 'assets'))
        FileUtils.cp_r(File.join(assets_dir, 'webfonts'), File.join(@options[:output_dir], 'assets'))
      end

      true
    end

    def create_graphql_operation_pages
      graphql_operation_types.each do |query_type|
        metadata = ''
        if query_type[:name] == 'Query'
          unless @options[:landing_pages][:query].nil?
            query_landing_page = @options[:landing_pages][:query]
            query_landing_page = File.read(query_landing_page)
            if has_yaml?(query_landing_page)
              pieces = yaml_split(query_landing_page)
              pieces[2] = pieces[2].chomp
              metadata = pieces[1, 3].join("\n")
              query_landing_page = pieces[4]
            end
            query_type[:description] = query_landing_page
          end
          opts = default_generator_options(type: query_type)
          contents = @graphql_operation_template.result(OpenStruct.new(opts).instance_eval { binding })
          write_file('operation', query_type[:name], metadata + contents)
        end
      end
    end

    def create_graphql_object_pages
      graphql_object_types.each do |object_type|
        opts = default_generator_options(type: object_type)

        contents = @graphql_object_template.result(OpenStruct.new(opts).instance_eval { binding })
        write_file('object', object_type[:name], contents)
      end
    end

    def create_graphql_mutation_pages
      graphql_mutation_types.each do |mutation|
        opts = default_generator_options(type: mutation)

        contents = @graphql_mutations_template.result(OpenStruct.new(opts).instance_eval { binding })
        write_file('mutation', mutation[:name], contents)
      end
    end

    def create_graphql_interface_pages
      graphql_interface_types.each do |interface_type|
        opts = default_generator_options(type: interface_type)

        contents = @graphql_interfaces_template.result(OpenStruct.new(opts).instance_eval { binding })
        write_file('interface', interface_type[:name], contents)
      end
    end

    def create_graphql_enum_pages
      graphql_enum_types.each do |enum_type|
        opts = default_generator_options(type: enum_type)

        contents = @graphql_enums_template.result(OpenStruct.new(opts).instance_eval { binding })
        write_file('enum', enum_type[:name], contents)
      end
    end

    def create_graphql_union_pages
      graphql_union_types.each do |union_type|
        opts = default_generator_options(type: union_type)

        contents = @graphql_unions_template.result(OpenStruct.new(opts).instance_eval { binding })
        write_file('union', union_type[:name], contents)
      end
    end

    def create_graphql_input_object_pages
      graphql_input_object_types.each do |input_object_type|
        opts = default_generator_options(type: input_object_type)

        contents = @graphql_input_objects_template.result(OpenStruct.new(opts).instance_eval { binding })
        write_file('input_object', input_object_type[:name], contents)
      end
    end

    def create_graphql_scalar_pages
      graphql_scalar_types.each do |scalar_type|
        opts = default_generator_options(type: scalar_type)

        contents = @graphql_scalars_template.result(OpenStruct.new(opts).instance_eval { binding })
        write_file('scalar', scalar_type[:name], contents)
      end
    end

    private

    def default_generator_options(opts = {})
      @options.merge(opts).merge(helper_methods)
    end

    def write_file(type, name, contents)
      if type == 'static'
        if name == 'index'
          path = @options[:output_dir]
        else
          path = File.join(@options[:output_dir], name)
          FileUtils.mkdir_p(path)
        end
      else
        path = File.join(@options[:output_dir], type, name.downcase)
        FileUtils.mkdir_p(path)
      end

      if has_yaml?(contents)
        # Split data
        meta, contents = split_into_metadata_and_contents(contents)
        @options = @options.merge(meta)
      end

      # normalize spacing so that CommonMarker doesn't treat it as `pre`
      contents.gsub!(/^\s*$/, '')
      contents.gsub!(/^\s{4}/m, '  ')

      contents = @renderer.render(contents, type: type, name: name)
      File.write(File.join(path, 'index.html'), contents) unless contents.nil?
    end
  end
end
