require 'commonmarker'

module GraphQLDocs
  class Generator
    module Helpers
      SLUGIFY_PRETTY_REGEXP = Regexp.new("[^[:alnum:]._~!$&'()+,;=@]+").freeze

      attr_accessor :templates

      def slugify(str)
        slug = str.gsub(SLUGIFY_PRETTY_REGEXP, '-')
        slug.gsub!(%r!^\-|\-$!i, '')
        slug.downcase
      end

      def include(filename, opts)
        template = fetch_include(filename)
        template.result(OpenStruct.new(opts.merge(helper_methods)).instance_eval { binding })
      end

      def fetch_include(filename)
        @templates ||= {}

        return @templates[filename] unless @templates[filename].nil?

        @templates[filename] = ERB.new(File.read(File.join(@options[:templates][:includes], filename)))
        @templates[filename]
      end

      def markdown(string)
        CommonMarker.render_html(string || 'n/a')
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
end
