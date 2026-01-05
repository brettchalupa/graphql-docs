# frozen_string_literal: true

require "commonmarker"
require "gemoji"
require "ostruct"

module GraphQLDocs
  # Helper methods module for use in ERB templates.
  #
  # This module provides utility methods that can be called from within ERB templates
  # when generating documentation. Methods are available via dot notation in templates,
  # such as `<%= slugify.(text) %>`.
  #
  # @example Using helper methods in templates
  #   <%= slugify.("My Type Name") %> # => "my-type-name"
  #   <%= markdownify.("**bold text**") %> # => "<strong>bold text</strong>"
  module Helpers
    # Regular expression for slugifying strings in a URL-friendly way.
    # Matches all characters that are not alphanumeric or common URL-safe characters.
    SLUGIFY_PRETTY_REGEXP = Regexp.new("[^[:alnum:]._~!$&'()+,;=@]+").freeze

    # @!attribute [rw] templates
    #   @return [Hash] Cache of loaded ERB templates for includes
    attr_accessor :templates

    # Converts a string into a URL-friendly slug.
    #
    # @param str [String] The string to slugify
    # @return [String] Lowercase slug with hyphens instead of spaces
    #
    # @example
    #   slugify("My Type Name") # => "my-type-name"
    #   slugify("Author.firstName") # => "author.firstname"
    def slugify(str)
      slug = str.gsub(SLUGIFY_PRETTY_REGEXP, "-")
      slug.gsub!(/^-|-$/i, "")
      slug.downcase
    end

    # Includes and renders a partial template file.
    #
    # This method loads an ERB template from the includes directory and renders it
    # with the provided options. Useful for reusing template fragments.
    #
    # @param filename [String] Name of the template file in the includes directory
    # @param opts [Hash] Options to pass to the template
    # @return [String] Rendered HTML content from the template
    #
    # @example In an ERB template
    #   <%= include.("field_table.html", fields: type[:fields]) %>
    def include(filename, opts = {})
      template = fetch_include(filename)
      opts = {base_url: @options[:base_url], classes: @options[:classes]}.merge(opts)
      template.result(OpenStruct.new(opts.merge(helper_methods)).instance_eval { binding })
    end

    # Converts a Markdown string to HTML.
    #
    # @param string [String] Markdown content to convert
    # @return [String] HTML output from the Markdown, empty string if input is nil
    #
    # @example
    #   markdownify("**bold**") # => "<strong>bold</strong>"
    #   markdownify(nil) # => ""
    def markdownify(string)
      return "" if string.nil?

      begin
        # Replace emoji shortcodes before markdown processing
        string_with_emoji = emojify(string)

        doc = ::Commonmarker.parse(string_with_emoji)
        html = if @options[:pipeline_config][:context][:unsafe]
          doc.to_html(options: {render: {unsafe: true}})
        else
          doc.to_html
        end
        html.strip
      rescue => e
        # Log error and return safe fallback
        warn "Failed to parse markdown: #{e.message}"
        require "cgi" unless defined?(CGI)
        CGI.escapeHTML(string)
      end
    end

    # Converts emoji shortcodes like :smile: to emoji characters
    def emojify(string)
      string.gsub(/:([a-z0-9_+-]+):/) do |match|
        emoji = Emoji.find_by_alias(Regexp.last_match(1))
        emoji ? emoji.raw : match
      end
    end

    # Returns the root types (query, mutation) from the parsed schema.
    #
    # @return [Hash] Hash containing 'query' and 'mutation' keys with type names
    def graphql_root_types
      @parsed_schema[:root_types] || []
    end

    # Returns all operation types (Query, Mutation) from the parsed schema.
    #
    # @return [Array<Hash>] Array of operation type hashes
    def graphql_operation_types
      @parsed_schema[:operation_types] || []
    end

    # Returns all query types from the parsed schema.
    #
    # @return [Array<Hash>] Array of query hashes with fields and arguments
    def graphql_query_types
      @parsed_schema[:query_types] || []
    end

    # Returns all mutation types from the parsed schema.
    #
    # @return [Array<Hash>] Array of mutation hashes with input and return fields
    def graphql_mutation_types
      @parsed_schema[:mutation_types] || []
    end

    # Returns all object types from the parsed schema.
    #
    # @return [Array<Hash>] Array of object type hashes
    def graphql_object_types
      @parsed_schema[:object_types] || []
    end

    # Returns all interface types from the parsed schema.
    #
    # @return [Array<Hash>] Array of interface type hashes
    def graphql_interface_types
      @parsed_schema[:interface_types] || []
    end

    # Returns all enum types from the parsed schema.
    #
    # @return [Array<Hash>] Array of enum type hashes with values
    def graphql_enum_types
      @parsed_schema[:enum_types] || []
    end

    # Returns all union types from the parsed schema.
    #
    # @return [Array<Hash>] Array of union type hashes with possible types
    def graphql_union_types
      @parsed_schema[:union_types] || []
    end

    # Returns all input object types from the parsed schema.
    #
    # @return [Array<Hash>] Array of input object type hashes
    def graphql_input_object_types
      @parsed_schema[:input_object_types] || []
    end

    # Returns all scalar types from the parsed schema.
    #
    # @return [Array<Hash>] Array of scalar type hashes
    def graphql_scalar_types
      @parsed_schema[:scalar_types] || []
    end

    # Returns all directive types from the parsed schema.
    #
    # @return [Array<Hash>] Array of directive hashes with locations and arguments
    def graphql_directive_types
      @parsed_schema[:directive_types] || []
    end

    # Splits content into YAML front matter metadata and body content.
    #
    # @param contents [String] Content string potentially starting with YAML front matter
    # @param parse [Boolean] Whether to parse the YAML (true) or return it as a string (false)
    # @return [Array<(Hash, String), (String, String)>] Tuple of [metadata, content]
    #
    # @raise [RuntimeError] If YAML front matter format is invalid
    # @raise [RuntimeError] If YAML parsing fails
    # @raise [TypeError] If parsed YAML is not a Hash
    def split_into_metadata_and_contents(contents, parse: true)
      pieces = yaml_split(contents)
      raise "The file '#{content_filename}' appears to start with a metadata section (three or five dashes at the top) but it does not seem to be in the correct format." if pieces.size < 4

      # Parse
      begin
        meta = if parse
          YAML.safe_load(pieces[2]) || {}
        else
          pieces[2]
        end
      rescue Exception => e # rubocop:disable Lint/RescueException
        raise "Could not parse YAML for #{name}: #{e.message}"
      end

      # Validate that parsed YAML is a Hash when parsing is enabled
      if parse && !meta.is_a?(Hash)
        raise TypeError, "Expected YAML front matter to be a hash, got #{meta.class}"
      end

      [meta, pieces[4]]
    end

    # Checks if content starts with YAML front matter.
    #
    # @param contents [String] Content to check
    # @return [Boolean] True if content starts with YAML front matter delimiters
    def yaml?(contents)
      contents =~ /\A-{3,5}\s*$/
    end

    # Splits content by YAML front matter delimiters.
    #
    # @param contents [String] Content to split
    # @return [Array<String>] Array of content pieces split by YAML delimiters
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
