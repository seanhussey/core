# Gluttonberg Core

[![Gem Version](https://badge.fury.io/rb/gluttonberg-core.png)](http://badge.fury.io/rb/gluttonberg-core)
[![Build Status](https://travis-ci.org/Gluttonberg/core.png?branch=master)](https://travis-ci.org/Gluttonberg/core)
[![Dependency Status](https://gemnasium.com/Gluttonberg/core.png)](https://gemnasium.com/Gluttonberg/core)
[![Code Climate](https://codeclimate.com/github/Gluttonberg/core.png)](https://codeclimate.com/github/Gluttonberg/core)

## About

The **Gluttonberg** goal has always been to create a Content Management System that's great for users, content manager and developers. The focus of **Gluttonberg 2.5** has been two-fold: a refined management user interface to make maintaining your website even easier and a change in the architecture of the system to support our new functionality modules: *Events*, *TV*, *Mobile* and soon *eCommerce*.

## Setup

Setting up **Gluttonberg** is easy.
The following setups will get you up and running.

1. Create a new **Rails** app.
`rails new gluttonberg_app  --skip-bundle --database=postgresql`
2. Add **Gluttonberg** to the *Gemfile* and then bundle install.
`gem 'gluttonberg-core', :git => 'git://github.com/Gluttonberg/core.git', :require => 'gluttonberg'`
`bundle install`
3. Double check the username and password in the *database.yml* and then create the database.
`bundle exec rake db:create`
4. Run the **Gluttonberg** installer rake task, the task will move all required files into place, migrate the database and then ask you for admin user details. `bundle exec rake gluttonberg:install`
5. Start the server. `foreman start`
6. Login to the [admin page](http://localhost:5000/admin) and start building. `http://localhost:5000/admin`
