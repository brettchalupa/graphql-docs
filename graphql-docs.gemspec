# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'graphql-docs/version'

Gem::Specification.new do |spec|
  spec.name          = 'graphql-docs'
  spec.version       = GraphQLDocs::VERSION
  spec.authors       = ['Brett Chalupa', 'Garen Torikian']
  spec.email         = ['brettchalupa@gmail.com']

  spec.summary       = 'Easily generate beautiful documentation from your GraphQL schema.'
  spec.description   = <<-EOF
    Library and CLI for generating a website from a GraphQL API's schema
    definition. With ERB templating support and a plethora of configuration
    options, you can customize the output to your needs. The library easily
    integrates with your Ruby deployment toolchain to ensure the docs for your
    API are up to date.
  EOF
  spec.homepage      = 'https://github.com/brettchalupa/graphql-docs'
  spec.license       = 'MIT'
  spec.metadata      = {
    "bug_tracker_uri"   => "https://github.com/brettchalupa/graphql-docs/issues",
    "changelog_uri"     => "https://github.com/brettchalupa/graphql-docs/blob/main/CHANGELOG.md",
    "wiki_uri"          => "https://github.com/brettchalupa/graphql-docs/wiki",
  }

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.1'

  spec.add_dependency 'graphql', '~> 2.0'

  # rendering
  spec.add_dependency 'commonmarker', '>= 0.23.6', '~> 0.23'
  spec.add_dependency 'escape_utils', '~> 1.2'
  spec.add_dependency 'extended-markdown-filter', '~> 0.4'
  spec.add_dependency 'gemoji', '~> 3.0'
  spec.add_dependency 'html-pipeline', '>= 2.14.3', '~> 2.14'
  spec.add_dependency 'sass-embedded', '~> 1.58'
  spec.add_dependency 'ostruct', '~> 0.6'
  spec.add_dependency 'logger', '~> 1.6'

  spec.add_development_dependency 'html-proofer', '~> 3.4'
  spec.add_development_dependency 'minitest', '~> 5.24'
  spec.add_development_dependency 'minitest-focus', '~> 1.1'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rubocop', '~> 1.37'
  spec.add_development_dependency 'rubocop-performance', '~> 1.15'
  spec.add_development_dependency 'webmock', '~> 2.3'
  spec.add_development_dependency 'webrick', '~> 1.7'
end
