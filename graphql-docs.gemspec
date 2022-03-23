# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'graphql-docs/version'

Gem::Specification.new do |spec|
  spec.name          = 'graphql-docs'
  spec.version       = GraphQLDocs::VERSION
  spec.authors       = ['Garen Torikian']
  spec.email         = ['gjtorikian@gmail.com']

  spec.summary       = 'Easily generate beautiful documentation from your GraphQL schema.'
  spec.homepage      = 'https://github.com/gjtorikian/graphql-docs'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'graphql', '~> 2.0'

  # rendering
  spec.add_dependency 'commonmarker', '~> 0.16'
  spec.add_dependency 'escape_utils', '~> 1.2'
  spec.add_dependency 'extended-markdown-filter', '~> 0.4'
  spec.add_dependency 'gemoji', '~> 3.0'
  spec.add_dependency 'html-pipeline', '~> 2.9'
  spec.add_dependency 'sass', '~> 3.4'

  spec.add_development_dependency 'awesome_print'
  spec.add_development_dependency 'html-proofer', '~> 3.4'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'minitest-focus', '~> 1.1'
  spec.add_development_dependency 'pry-byebug', '~> 3.6'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-performance'
  spec.add_development_dependency 'rubocop-standard'
  spec.add_development_dependency 'webmock', '~> 2.3'
end
