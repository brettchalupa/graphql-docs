require 'test_helper'

class ClientTest < Minitest::Test
  def setup
    @url = 'http://graphql.org/swapi-graphql/'
    @client = GraphQLDocs::Client.new(url: @url)
    stub_request(:post, @url)
  end

  def test_that_it_requires_a_url
    assert_raises ArgumentError do
      GraphQLDocs::Client.new
    end
  end

  def test_that_it_requires_both_the_basic_auth_params
    assert_raises ArgumentError do
      GraphQLDocs::Client.new(url: @url, login: 'Biscotto')
    end

    assert_raises ArgumentError do
      GraphQLDocs::Client.new(url: @url, password: '1234')
    end
  end

  def test_that_it_masks_passwords_on_inspect
    client = GraphQLDocs::Client.new(url: @url, login: 'Biscotto', password: '1234')
    inspected = client.inspect
    refute_match inspected, '1234'
  end

  def test_that_it_masks_tokens_on_inspect
    client = GraphQLDocs::Client.new(url: @url, access_token: '87614b09dd141c22800f96f11737ade5226d7ba8')
    inspected = client.inspect
    refute_match inspected, '87614b09dd141c22800f96f11737ade5226d7ba8'
  end

  def test_that_it_makes_requests_with_login
    client = GraphQLDocs::Client.new(url: @url, login: 'Biscotto', password: '1234')
    client.fetch
    assert_requested :post, @url,
                      headers: {'Accept'=>'*/*', \
                                'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', \
                                'Authorization'=>'Basic QmlzY290dG86MTIzNA==',
                                'Content-Type'=>'application/json',
                                'User-Agent'=>'Faraday v0.11.0' },
                      body: "{ \"query\": \"#{GraphQL::Introspection::INTROSPECTION_QUERY.gsub("\n", '')}\" }"
  end

  def test_that_it_makes_requests_with_token
    client = GraphQLDocs::Client.new(url: @url, access_token: '87614b09dd141c22800f96f11737ade5226d7ba8')
    client.fetch
    assert_requested :post, @url,
                      headers: {'Accept'=>'*/*', \
                                'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', \
                                'Authorization'=>'token 87614b09dd141c22800f96f11737ade5226d7ba8',
                                'Content-Type'=>'application/json',
                                'User-Agent'=>'Faraday v0.11.0' },
                      body: "{ \"query\": \"#{GraphQL::Introspection::INTROSPECTION_QUERY.gsub("\n", '')}\" }"
  end
end
