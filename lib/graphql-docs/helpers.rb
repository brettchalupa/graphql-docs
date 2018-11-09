# frozen_string_literal: true

require 'commonmarker'

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

    def markdownify(string)
      return '' if string.nil?
      type = @options[:pipeline_config][:context][:unsafe] ? :UNSAFE : :DEFAULT
      ::CommonMarker.render_html(string, type).strip
    end

    def graphql_root_types
      @parsed_schema[:root_types] || []
    end

    def graphql_operation_types
      @parsed_schema[:operation_types] || []
    end

    def graphql_mutation_types
      @parsed_schema[:mutation_types] || []
    end

    def graphql_object_types
      @parsed_schema[:object_types] || []
    end

    def graphql_interface_types
      @parsed_schema[:interface_types] || []
    end

    def graphql_enum_types
      @parsed_schema[:enum_types] || []
    end

    def graphql_union_types
      @parsed_schema[:union_types] || []
    end

    def graphql_input_object_types
      @parsed_schema[:input_object_types] || []
    end

    def graphql_scalar_types
      @parsed_schema[:scalar_types] || []
    end

    def split_into_metadata_and_contents(contents)
      opts = {}
      pieces = yaml_split(contents)
      if pieces.size < 4
        raise RuntimeError.new(
          "The file '#{content_filename}' appears to start with a metadata section (three or five dashes at the top) but it does not seem to be in the correct format.",
        )
      end
      # Parse
      begin
        meta = YAML.load(pieces[2]) || {}
      rescue Exception => e # rubocop:disable Lint/RescueException
        raise "Could not parse YAML for #{name}: #{e.message}"
      end
      [meta, pieces[4]]
    end

    def has_yaml?(contents)
      contents =~ /\A-{3,5}\s*$/
    end

    def yaml_split(contents)
      contents.split(/^(-{5}|-{3})[ \t]*\r?\n?/, 3)
    end

    private

    def fetch_include(filename)
      @templates ||= {}

      return @templates[filename] unless @templates[filename].nil?

      contents = File.read(File.join(@options[:templates][:includes], filename))

      @templates[filename] = ERB.new(contents)
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
