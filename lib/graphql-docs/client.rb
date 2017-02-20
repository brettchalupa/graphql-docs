require 'faraday'
require 'graphql'

module GraphQLDocs
  class Client
    attr_accessor :faraday

    def initialize(options)
      @login = options[:login]
      @password = options[:password]

      if @login.nil? && !@password.nil?
        fail ArgumentError, 'Client provided a login, but no password!'
      end

      if !@login.nil? && @password.nil?
        fail ArgumentError, 'Client provided a password, but no login!'
      end

      @access_token = options[:access_token]

      @url = options[:url]
      @faraday = Faraday.new(url: @url)

      if @login && @password
        @faraday.basic_auth(@login, @password)
      elsif  @access_token
        @faraday.authorization('token', @access_token)
      end
    end

    def fetch
      res = @faraday.post do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = "{ \"query\": \"#{GraphQL::Introspection::INTROSPECTION_QUERY.gsub("\n", '')}\" }"
      end
      res.body
    end

    def inspect
      inspected = super

      # mask password
      inspected = inspected.gsub! @password, '*******' if @password

      # Only show last 4 of token, secret
      if @access_token
        inspected = inspected.gsub! @access_token, "#{'*'*36}#{@access_token[36..-1]}"
      end

      inspected
    end
  end
end
