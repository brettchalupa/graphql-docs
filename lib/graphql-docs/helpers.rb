module GraphQLDocs
  module Helpers
    SLUGIFY_PRETTY_REGEXP = Regexp.new("[^[:alnum:]._~!$&'()+,;=@]+").freeze

    attr_accessor :templates

    def slugify(str)
      slug = str.gsub(SLUGIFY_PRETTY_REGEXP, '-')
      slug.gsub!(%r!^\-|\-$!i, '')
      slug.downcase
    end

    def include(filename, opts = {})
      template = fetch_include(filename)
      opts = { base_url: @options[:base_url], classes: @options[:classes] }.merge(opts)
      template.result(OpenStruct.new(opts.merge(helper_methods)).instance_eval { binding })
    end

    def markdown(string)
      GitHub::Markdown.render(string || 'n/a')
    end

    # Do you think I am proud of this? I am not.
    def format_type(field)
      type_path = name_slug = nil
      type_name = ''

      if field['type']['kind'] == 'NON_NULL'
        type_name << '!'

        if !field['type']['ofType']['ofType'].nil?
          # we're going to be a list...but what kind?!
          type_name << '['
          if !field['type']['ofType']['ofType']['ofType'].nil?
            # A required list of required items: ![!Blah]
            if field['type']['ofType']['ofType']['kind'] == 'NON_NULL'
              type_name << '!'
            end
            type_path = field['type']['ofType']['ofType']['ofType']['kind']
            type_name << field['type']['ofType']['ofType']['ofType']['name']
            name_slug = field['type']['ofType']['ofType']['ofType']['name']
          else
            # A required list of non-required items: ![Blah]
            type_path = field['type']['ofType']['ofType']['kind']
            type_name << field['type']['ofType']['ofType']['name']
            name_slug = field['type']['ofType']['ofType']['name']
          end
          type_name << ']'
        else
          # Simple non-null item: !Blah
          type_path = field['type']['ofType']['kind']
          type_name << field['type']['ofType']['name']
          name_slug = field['type']['ofType']['name']
        end
      elsif field['type']['kind'] == 'LIST'
        type_name << '['
        if field['type']['ofType']['kind'] == 'NON_NULL'
          # Nullable list of non-null items: [!Blah]
          type_name << '!'
          type_path = field['type']['ofType']['ofType']['kind']
          type_name << field['type']['ofType']['ofType']['name']
          name_slug = field['type']['ofType']['ofType']['name']
        else
          # Nullable list of nullable items: [Blah]
          type_path = field['type']['ofType']['kind']
          type_name << field['type']['ofType']['name']
          name_slug = field['type']['ofType']['name']
        end
        type_name << ']'
      else
        # Simple nullable item: Blah
        type_path = field['type']['kind']
        type_name << field['type']['name']
        name_slug = field['type']['name']
      end

      [type_path.downcase, type_name, name_slug.downcase]
    end

    def graphql_mutation_types
      @parsed_schema['mutation_types']
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

    private

    def fetch_include(filename)
      @templates ||= {}

      return @templates[filename] unless @templates[filename].nil?

      @templates[filename] = ERB.new(File.read(File.join(@options[:templates][:includes], filename)))
      @templates[filename]
    end

    def helper_methods
      return @helper_methods if defined?(@helper_methods)

      @helper_methods = {}

      Helpers.instance_methods.each do |name|
        next if name == :helper_methods
        @helper_methods[name] = method(name)
      end

      @helper_methods
    end
  end
end
