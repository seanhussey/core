#encoding: utf-8
# require 'rake/testtask'

# Rake::TestTask.new do |test|
#   test.pattern = 'test/**/*_test.rb'
#   test.libs << 'test'
# end


# begin
#   require "jeweler"
#   Jeweler::Tasks.new do |gem|
#     gem.name = "gluttonberg"
#     gem.summary = "Gluttonberg – An Open Source Content Management System being developed by Freerange Future"
#     gem.email = "office@freerangefuture.com"
#     gem.authors = ["Nick Crowther","Abdul Rauf", "Luke Sutton", "Yuri Tomanek"]
#     gem.files = Dir["{lib}/**/*", "{app}/**/*", "{public}/**/*", "{config}/**/*"]
#   end
#   Jeweler::GemcutterTasks.new
# rescue
#   puts "Jeweler or dependency not available."
# end

#!/usr/bin/env rake

# setup bundler
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Bundler::GemHelper.install_tasks

#setup rdoc

begin
  require 'rdoc/task'
rescue LoadError
  require 'rdoc/rdoc'
  require 'rake/rdoctask'
  RDoc::Task = Rake::RDocTask
end

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Gluttonberg-core'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

# setup dummy app and rspec

APP_RAKEFILE = File.expand_path("../spec/dummy/Rakefile", __FILE__)
load 'rails/tasks/engine.rake'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

# RSpec as default
task :default => :spec
