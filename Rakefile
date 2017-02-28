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

task :generate_sample, [:base_url] do |task, args|
  require 'graphql-docs'

  options = {}
  options[:delete_output] = true
  options[:base_url] = args.base_url || ''
  options[:path] = File.join(File.dirname(__FILE__), 'test', 'graphql-docs', 'fixtures', 'gh-api.json')

  GraphQLDocs.build(options)
end

task :sample => [:generate_sample] do
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
