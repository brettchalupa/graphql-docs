# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
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

  spec.add_dependency 'faraday', '< 0.10'#'~> 0.9'
  spec.add_dependency 'graphql', '~> 1.4'

  # rendering
  spec.add_dependency 'html-pipeline', '~> 2.2'
  spec.add_dependency 'github-markdown', '0.6.9'
  spec.add_dependency 'extended-markdown-filter', '~> 0.4'
  spec.add_dependency 'gemoji', '2.1.0'
  spec.add_dependency 'sass', '~> 3.4'

  spec.add_development_dependency 'awesome_print'
  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'html-proofer', '~> 3.4'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'minitest-focus', '~> 1.1'
  spec.add_development_dependency 'pry', '~> 0.10.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rubocop-github'
  spec.add_development_dependency 'webmock', '~> 2.3'
end
