# frozen_string_literal: true

begin
  require "graphql-docs"

  namespace :"graphql-docs" do
    desc "Generate GraphQL documentation from schema"
    task :generate, [:schema_file, :output_dir, :base_url, :delete_output] do |_t, args|
      options = {}

      # Prefer task arguments over environment variables
      options[:filename] = args[:schema_file] || ENV["GRAPHQL_SCHEMA_FILE"]
      options[:output_dir] = args[:output_dir] || ENV["GRAPHQL_OUTPUT_DIR"]
      options[:base_url] = args[:base_url] || ENV["GRAPHQL_BASE_URL"]

      # Handle delete_output as a boolean
      delete_output_arg = args[:delete_output] || ENV["GRAPHQL_DELETE_OUTPUT"]
      options[:delete_output] = delete_output_arg == "true" if delete_output_arg

      # Check if a schema file is specified
      if options[:filename].nil?
        puts "Please specify a GraphQL schema file:"
        puts ""
        puts "Using task arguments:"
        puts "  rake graphql-docs:generate[path/to/schema.graphql]"
        puts "  rake graphql-docs:generate[schema.graphql,./docs]"
        puts "  rake graphql-docs:generate[schema.graphql,./docs,/api-docs,true]"
        puts ""
        puts "Or using environment variables:"
        puts "  GRAPHQL_SCHEMA_FILE=path/to/schema.graphql rake graphql-docs:generate"
        puts ""
        puts "Available arguments (in order):"
        puts "  1. schema_file     - Path to GraphQL schema file (required)"
        puts "  2. output_dir      - Output directory (default: ./output/)"
        puts "  3. base_url        - Base URL for assets and links (default: '')"
        puts "  4. delete_output   - Delete output directory before generating (true/false, default: false)"
        puts ""
        puts "Available environment variables:"
        puts "  GRAPHQL_SCHEMA_FILE    - Path to GraphQL schema file (required)"
        puts "  GRAPHQL_OUTPUT_DIR     - Output directory (default: ./output/)"
        puts "  GRAPHQL_BASE_URL       - Base URL for assets and links (default: '')"
        puts "  GRAPHQL_DELETE_OUTPUT  - Delete output directory before generating (true/false)"
        exit 1
      end

      puts "Generating GraphQL documentation..."
      puts "  Schema: #{options[:filename]}"
      puts "  Output: #{options[:output_dir] || "./output/"}"

      GraphQLDocs.build(options)

      puts "Documentation generated successfully!"
    end
  end
rescue LoadError
  # graphql-docs not available, skip task definition
end
