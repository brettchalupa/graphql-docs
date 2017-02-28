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
      opts = { base_url: @options[:base_url] }.merge(opts)
      template.result(OpenStruct.new(opts.merge(helper_methods)).instance_eval { binding })
    end

    def markdown(string)
      GitHub::Markdown.render(string || 'n/a')
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
