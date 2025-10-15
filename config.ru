# frozen_string_literal: true

# Rack configuration file for running GraphQL Docs as a web server
#
# This demonstrates using GraphQLDocs as a Rack application that serves
# documentation dynamically on-demand instead of pre-generating static files.
#
# Run with: rackup config.ru
# Or with specific port: rackup config.ru -p 9292

require_relative "lib/graphql-docs"

# Load the sample GraphQL schema
schema_path = File.join(__dir__, "test", "graphql-docs", "fixtures", "gh-schema.graphql")

unless File.exist?(schema_path)
  puts "Error: Sample schema not found at #{schema_path}"
  puts "Please ensure the schema file exists before starting the server."
  exit 1
end

schema = File.read(schema_path)

# Create the Rack app
app = GraphQLDocs::App.new(
  schema: schema,
  options: {
    base_url: "",
    use_default_styles: true,
    cache: true
  }
)

# Log requests in development
use Rack::CommonLogger

# Add reloader for development (optional, requires 'rack' gem)
if ENV["RACK_ENV"] != "production"
  puts "Running in development mode"
  puts "Visit http://localhost:9292 to view the documentation"
  puts "Press Ctrl+C to stop the server"
end

run app
