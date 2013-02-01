# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "gluttonberg/version"

Gem::Specification.new do |s|
  s.name        = "gluttonberg-core"
  s.version     = Gluttonberg::VERSION
  s.authors     = ["Nick Crowther","Abdul Rauf", "Luke Sutton", "Yuri Tomanek"]
  s.email       = ["office@freerangefuture.com"]
  s.homepage    = "http://gluttonberg.com"
  s.summary     = "Gluttonberg - An Open Source Content Management System being developed by Freerange Future"
  s.description = "The Gluttonberg goal has always been to create a Content Management System that's great for users, content manager and developers. The focus of Gluttonberg 2.5 has been two-fold: a refined management user interface to make maintaining your website even easier and a change in the architecture of the system to support our new functionality modules: Events, TV, Mobile and soon eCommerce."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile", "README.md"]
  s.require_paths = ["lib"]
  s.test_files = ["spec"]

  s.add_dependency "authlogic", '3.1.3'
  s.add_dependency "will_paginate" , '3.0.3'
  s.add_dependency "rubyzip", '0.9.9'
  s.add_dependency "acts_as_tree", '1.1.0'
  s.add_dependency "acts_as_list", '0.1.8'
  s.add_dependency "acts-as-taggable-on", '2.3.3'
  s.add_dependency "delayed_job", '2.1.4'         ###3.0.3
  s.add_dependency 'jeditable-rails', '0.1.1'
  s.add_dependency 'cancan', '1.6.4'
  s.add_dependency 'active_link_to', '1.0.0'
  s.add_dependency 'texticle' , '1.0.4.20101004123327'
  s.add_dependency 'ruby-mp3info', '0.6.14'       ####0.7.1
  s.add_dependency 'paperclip', '3.3.0'
  s.add_dependency 'acl9', '0.12.0'
  s.add_dependency "sitemap_generator", '3.1.1'
  s.add_development_dependency "rspec-rails", "2.0.1"
  s.add_dependency 'domainatrix'

end
