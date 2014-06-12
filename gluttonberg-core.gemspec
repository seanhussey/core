# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "gluttonberg/version"

Gem::Specification.new do |s|
  s.name        = "gluttonberg-core"
  s.version     = Gluttonberg::VERSION
  s.authors     = ["Nick Crowther", "Yuri Tománek", "Abdul Rauf", "Luke Sutton"]
  s.email       = ["office@freerangefuture.com"]
  s.homepage    = "http://gluttonberg.com"
  s.summary     = "Gluttonberg is an Open Source CMS developed by the team at Freerange Future."
  s.description = "Gluttonberg is an Open Source CMS developed by the team at Freerange Future. As designers and developers, we love the flexibility of Ruby, but got tired of taking care of authentication, asset mangement, page management (and so on...) with every install. We created Gluttonberg to take care of that boring stuff so we could start having fun sooner."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile", "README.md"]
  s.require_paths = ["lib"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency 'authlogic', "3.4.0"
  s.add_dependency 'will_paginate' , '3.0.5'
  s.add_dependency 'rubyzip', '1.1.0'
  s.add_dependency 'acts_as_tree', '1.5.0'
  s.add_dependency 'freerange_acts_as_versioned', '2.0.0'
  s.add_dependency 'acts-as-taggable-on', '3.0.1'
  s.add_dependency 'sidekiq', '2.17.7'
  s.add_dependency 'jeditable-rails', '0.1.1'
  s.add_dependency 'cancan', '1.6.10'
  s.add_dependency 'active_link_to', '1.0.2'
  s.add_dependency 'texticle', '1.0.4.20101004123327'
  s.add_dependency 'ruby-mp3info', '0.8.3'
  s.add_dependency 'paperclip', '4.1.0'
  s.add_dependency 'acl9', '0.12.1'
  s.add_dependency 'sitemap_generator', '5.0.0'
  s.add_dependency 'domainatrix', '0.0.11'
  s.add_dependency 'aws-sdk', '1.34.0'
  s.add_dependency 'highline', '1.6.20'
  s.add_dependency 'haml', '4.0.5'
  s.add_dependency 'sass', '3.2.14'
  s.add_dependency 'unicorn', '4.8.2'
  s.add_dependency 'foreman', '0.63.0'
  s.add_dependency 'rabl', '0.9.3'
  s.add_development_dependency 'rspec-rails', '2.14.1'
  s.add_development_dependency 'fakes3', '0.1.5.2'

end
