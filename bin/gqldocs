#!/usr/bin/env ruby

require "bundler/setup"
require 'thor'
require 'graphql-docs'

class GraphQLDocsCLI < Thor
  include GraphQLDocs

  class_option :verbose, :type => :boolean

  desc "generate", "generate docs for a graphql API"

  option :url, :type => :string, :desc => "The URL of your GraphQL API"
  option :path, :type => :string, :desc => "Path to the JSON that results from the introspection query"

  option :access_token, :type => :string, :desc => "Uses this token while making requests through GraphQLDocs::Client."
  option :login, :type => :string, :desc => "Uses this login while making requests through GraphQLDocs::Client."
  option :password, :type => :string, :desc => "Uses this password while making requests through GraphQLDocs::Client."

  option :output_dir, :type => :string, :desc => "Path to output generated docs", :default => File.join(Dir.pwd, 'output')
  option :delete_output, :type => :boolean, :desc => "Delete the output dir before generating", :default => false
  option :include_assets, :type => :boolean, :desc => "Include CSS and JS assets in the output"



  def generate
    if options[:path].nil? && options[:url].nil?
      puts 'You must provide a url or path'
      exit 1
    end

    GraphQLDocs.build(
        {
            url: options[:url],
            path: options[:path],
            output_dir: options[:output_dir],
            delete_output: options[:delete_output],
            include_assets: options[:include_assets],
            access_token: options[:access_token],
            login: options[:login],
            password: options[:password],
        }
    )

  end
end

GraphQLDocsCLI.start(ARGV)