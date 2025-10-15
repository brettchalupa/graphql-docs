# frozen_string_literal: true

require 'test_helper'
require 'rack/test'
require 'graphql-docs/app'

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    schema = File.read(File.join(__dir__, 'fixtures', 'tiny-schema.graphql'))
    GraphQLDocs::App.new(schema: schema, options: { cache: false })
  end

  def test_index_page
    get '/'
    assert last_response.ok?
    assert_includes last_response.body, 'Query'
  end

  def test_index_with_html_extension
    get '/index.html'
    assert last_response.ok?
  end

  def test_object_page
    get '/object/codeofconduct'
    assert last_response.ok?
    assert_includes last_response.body, 'CodeOfConduct'
  end

  def test_query_operation_page
    get '/operation/query'
    assert last_response.ok?
    assert_includes last_response.body, 'Query'
  end

  def test_scalar_page
    get '/scalar/uri'
    assert last_response.ok?
    assert_includes last_response.body, 'URI'
  end

  def test_assets_css
    get '/assets/style.css'
    assert last_response.ok?
    assert_equal 'text/css; charset=utf-8', last_response.content_type
    assert_includes last_response.body, 'body'
  end

  def test_404_for_missing_type
    get '/object/nonexistent'
    assert_equal 404, last_response.status
    assert_includes last_response.body, 'not found'
  end

  def test_404_for_invalid_path
    get '/invalid/path'
    assert_equal 404, last_response.status
    assert_includes last_response.body, '404'
  end

  def test_caching_enabled
    cached_app = GraphQLDocs::App.new(
      schema: File.read(File.join(__dir__, 'fixtures', 'tiny-schema.graphql')),
      options: { cache: true }
    )

    # Make two requests
    env = Rack::MockRequest.env_for('/')
    response1 = cached_app.call(env)
    response2 = cached_app.call(env)

    assert_equal response1, response2
  end

  def test_schema_reload
    schema1 = 'type Query { hello: String }'
    schema2 = 'type Query { goodbye: String }'

    rack_app = GraphQLDocs::App.new(schema: schema1)

    # Test first schema
    env = Rack::MockRequest.env_for('/')
    response = rack_app.call(env)
    body = response[2].join

    assert_includes body, 'Query'

    # Reload with new schema
    rack_app.reload_schema!(schema2)
    rack_app.clear_cache!

    # Cache should be cleared
    response2 = rack_app.call(env)
    body2 = response2[2].join

    # Should have new schema content
    refute_equal body, body2
  end

  def test_base_url_prefix
    schema = File.read(File.join(__dir__, 'fixtures', 'tiny-schema.graphql'))
    prefixed_app = GraphQLDocs::App.new(
      schema: schema,
      options: { base_url: '/docs', cache: false }
    )

    env = Rack::MockRequest.env_for('/docs/')
    response = prefixed_app.call(env)
    assert_equal 200, response[0]
  end

  def test_yaml_frontmatter_title_renders_in_index
    schema = File.read(File.join(__dir__, 'fixtures', 'tiny-schema.graphql'))
    # Use a landing page with YAML frontmatter
    yaml_app = GraphQLDocs::App.new(
      schema: schema,
      options: {
        cache: false,
        landing_pages: {
          index: File.join(__dir__, 'fixtures', 'landing_pages', 'whitespace_template.md')
        }
      }
    )

    env = Rack::MockRequest.env_for('/')
    response = yaml_app.call(env)
    body = response[2].join

    assert_equal 200, response[0]

    # Should render title from YAML frontmatter, not "index"
    assert_includes body, '<title>GraphQL documentation</title>'
    refute_includes body, '<title>index</title>'

    # YAML frontmatter should not appear in page content
    refute_includes body, '---'
    refute_includes body, 'title: GraphQL documentation'
  end

  def test_yaml_frontmatter_options_reset_after_render
    # Test that options are properly reset after each render to prevent pollution
    schema = File.read(File.join(__dir__, 'fixtures', 'tiny-schema.graphql'))
    yaml_app = GraphQLDocs::App.new(
      schema: schema,
      options: {
        cache: false,
        landing_pages: {
          index: File.join(__dir__, 'fixtures', 'landing_pages', 'whitespace_template.md')
        }
      }
    )

    # Make first request with YAML frontmatter
    env1 = Rack::MockRequest.env_for('/')
    response1 = yaml_app.call(env1)
    body1 = response1[2].join

    assert_includes body1, '<title>GraphQL documentation</title>'

    # Make second request to a different page without YAML frontmatter
    env2 = Rack::MockRequest.env_for('/object/codeofconduct')
    response2 = yaml_app.call(env2)
    body2 = response2[2].join

    # Second page should use 'name' fallback (lowercased), not the title from first request
    assert_includes body2, '<title>codeofconduct</title>'
    # Should NOT have the title from the index page
    refute_includes body2, '<title>GraphQL documentation</title>'
  end

  def test_yaml_frontmatter_with_caching
    # Test that YAML metadata works correctly even with caching enabled
    schema = File.read(File.join(__dir__, 'fixtures', 'tiny-schema.graphql'))
    cached_app = GraphQLDocs::App.new(
      schema: schema,
      options: {
        cache: true,
        landing_pages: {
          index: File.join(__dir__, 'fixtures', 'landing_pages', 'whitespace_template.md')
        }
      }
    )

    # Make two requests to the same page
    env = Rack::MockRequest.env_for('/')
    response1 = cached_app.call(env)
    response2 = cached_app.call(env)

    body1 = response1[2].join
    body2 = response2[2].join

    # Both should have the YAML frontmatter title
    assert_includes body1, '<title>GraphQL documentation</title>'
    assert_includes body2, '<title>GraphQL documentation</title>'

    # Responses should be identical
    assert_equal body1, body2
  end

  private

  def app
    @app ||= begin
      schema = File.read(File.join(__dir__, 'fixtures', 'tiny-schema.graphql'))
      GraphQLDocs::App.new(schema: schema, options: { cache: false })
    end
  end
end
