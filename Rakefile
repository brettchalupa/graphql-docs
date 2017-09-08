require 'bundler/gem_tasks'
require 'rake/testtask'

require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop)

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.warning = false
  t.test_files = FileList['test/**/*_test.rb']
end

task default: :test

Rake::Task[:test].enhance { Rake::Task[:html_proofer].invoke }

desc 'Invoke HTML-Proofer'
task html_proofer: [:generate_sample] do
  require 'html-proofer'
  output_dir = File.join(File.dirname(__FILE__), 'output')

  proofer_options = { disable_external: true, assume_extension: true }
  HTMLProofer.check_directory(output_dir, proofer_options).run
end

desc 'Set up a console'
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

desc 'Generate the documentation'
task :generate_sample do
  require 'pry'
  require 'graphql-docs'

  options = {}
  options[:delete_output] = true
  options[:filename] = File.join(File.dirname(__FILE__), 'test', 'graphql-docs', 'fixtures', 'gh-schema.graphql')

  GraphQLDocs.build(options)
end

desc 'Generate the documentation and run a web server'
task sample: [:generate_sample] do
  require 'webrick'

  puts 'Navigate to http://localhost:3000 to see the sample docs'

  server = WEBrick::HTTPServer.new Port: 3000
  server.mount '/', WEBrick::HTTPServlet::FileHandler, 'output'
  trap('INT') { server.stop }
  server.start
end

desc 'Generate and publish docs to gh-pages'
task :publish do
  Rake::Task[:generate_sample].invoke('https://www.gjtorikian.com/graphql-docs')
  Dir.mktmpdir do |tmp|
    system "mv output/* #{tmp}"
    system 'git checkout gh-pages'
    system 'rm -rf *'
    system "mv #{tmp}/* ."
    message = "Site updated at #{Time.now.utc}"
    system 'git add .'
    system "git commit -am #{message.shellescape}"
    system 'git push origin gh-pages --force'
    system 'git checkout master'
    system 'echo yolo'
  end
end
