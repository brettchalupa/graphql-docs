# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

require "standard/rake"

# Load graphql-docs rake tasks
Dir.glob("lib/tasks/**/*.rake").each { |r| load r }

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.warning = false
  t.test_files = FileList["test/**/*_test.rb"]
end

task default: [:standard, :test]

desc "Invoke HTML-Proofer"
task :html_proofer do
  Rake::Task["sample:generate"]
  require "html-proofer"
  output_dir = File.join(File.dirname(__FILE__), "output")

  proofer_options = {ignore_urls: [/^https?:\/\//], assume_extension: ".html"}
  HTMLProofer.check_directory(output_dir, proofer_options).run
end

desc "Set up a console"
task :console do
  require "graphql-docs"

  def reload!
    files = $LOADED_FEATURES.select { |feat| feat =~ %r{/graphql-docs/} }
    files.each { |file| load file }
  end

  require "irb"
  ARGV.clear
  IRB.start
end

namespace :yard do
  desc "Generate YARD documentation"
  task :doc do
    sh "bundle exec yard doc"
  end

  desc "Run YARD documentation server"
  task :server do
    puts "Starting YARD server at http://localhost:8808"
    puts "Press Ctrl+C to stop"
    sh "bundle exec yard server --reload --bind 0.0.0.0 --port 8808"
  end
end

# Alias for convenience
desc "Generate YARD documentation"
task yard: "yard:doc"

namespace :sample do
  desc "Generate the sample documentation"
  task :generate do
    require "graphql-docs"

    options = {}
    options[:delete_output] = true
    options[:base_url] = ENV.fetch("GQL_DOCS_BASE_URL", "")
    options[:filename] = File.join(File.dirname(__FILE__), "test", "graphql-docs", "fixtures", "gh-schema.graphql")

    puts "Generating sample docs"
    GraphQLDocs.build(options)
  end

  desc "Generate the documentation and run a web server"
  task serve: [:generate] do
    require "webrick"
    port = "5050"
    puts "Navigate to http://localhost:#{port} to view the sample docs"
    server = WEBrick::HTTPServer.new Port: port
    server.mount "/", WEBrick::HTTPServlet::FileHandler, "output"
    trap("INT") { server.stop }
    server.start
  end
  task server: :serve

  desc "Run the sample docs as a Rack application (dynamic, on-demand generation)"
  task :rack do
    require "rack"
    require "graphql-docs"

    schema_path = File.join(File.dirname(__FILE__), "test", "graphql-docs", "fixtures", "gh-schema.graphql")
    schema = File.read(schema_path)

    GraphQLDocs::App.new(
      schema: schema,
      options: {
        base_url: "",
        use_default_styles: true,
        cache: true
      }
    )

    port = ENV.fetch("PORT", "9292")
    puts "Starting Rack server in dynamic mode (on-demand generation)"
    puts "Navigate to http://localhost:#{port} to view the sample docs"
    puts "Press Ctrl+C to stop"
    puts ""
    puts "NOTE: This serves documentation dynamically - pages are generated on request"
    puts "      Compare with 'rake sample:serve' which serves pre-generated static files"
    puts ""

    # Use rackup for Rack 3.x compatibility
    sh "rackup config.ru -p #{port}"
  end
end
