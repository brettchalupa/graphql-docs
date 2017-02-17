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
  require 'graphql-docs'
  require 'sass'

  options = {}
  options[:output_dir] = 'sample'
  options[:delete_output] = true
  options[:path] = File.join(File.dirname(__FILE__), 'test', 'graphql-docs', 'fixtures', 'gh-api.json')

  GraphQLDocs.build(options)

  assets_dir = File.join('sample', 'assets')
  FileUtils.mkdir_p(assets_dir)

  sass = File.join('sample_assets', 'css', 'screen.scss')
  system `sass --sourcemap=none #{sass}:style.css`

  FileUtils.mv('style.css', File.join('sample', 'assets/style.css'))

  starting_dir = 'sample'
  starting_file = File.join(starting_dir, 'object', 'repository', 'index.html')

  puts 'Navigate to http://localhost:3000 to see the sample docs'
  puts "Launching #{starting_file}"
  system "open #{starting_file}"
  system "ruby -run -e httpd #{starting_dir} -p 3000"
end
