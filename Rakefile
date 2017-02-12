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
