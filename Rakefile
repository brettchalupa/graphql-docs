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

  assets_dir = File.join(File.dirname(__FILE__), 'lib', 'graphql-docs', 'layouts', 'assets')
  FileUtils.mkdir_p(File.join('output', 'assets'))

  sass = File.join(assets_dir, 'css', 'screen.scss')
  system `sass --sourcemap=none #{sass}:output/assets/style.css`

  FileUtils.cp_r(File.join(assets_dir, 'images'), File.join('output', 'assets'))
  # FileUtils.cp_r(File.join(assets_dir, 'javascripts'), File.join('output', 'assets'))
  FileUtils.cp_r(File.join(assets_dir, 'webfonts'), File.join('output', 'assets'))

  starting_file = File.join('output', 'index.html')

  puts 'Navigate to http://localhost:3000 to see the sample docs'

  server = WEBrick::HTTPServer.new Port: 3000
  server.mount '/', WEBrick::HTTPServlet::FileHandler, 'output'
  trap('INT') { server.stop }
  server.start
end
