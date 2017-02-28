require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

task default: :test

task :console do
  require 'pry'
  require 'graphql-docs'

  def reload!
    files = $LOADED_FEATURES.select { |feat| feat =~ /\/graphql-docs\// }
    files.each { |file| load file }
  end

  ARGV.clear
  Pry.start
end

task :sample do
  require 'webrick'
  require 'graphql-docs'
  require 'sass'

  options = {}
  options[:delete_output] = true
  options[:path] = File.join(File.dirname(__FILE__), 'test', 'graphql-docs', 'fixtures', 'gh-api.json')

  GraphQLDocs.build(options)

  starting_file = File.join('output', 'index.html')

  puts 'Navigate to http://localhost:3000 to see the sample docs'

  server = WEBrick::HTTPServer.new Port: 3000
  server.mount '/', WEBrick::HTTPServlet::FileHandler, 'output'
  trap('INT') { server.stop }
  server.start
end
