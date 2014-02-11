require "highline"
namespace :gluttonberg do

  desc "Install Gluttonberg"
  task :install => :environment do
    line = HighLine.new
    status = true
    line.say("<%= color('Preparing to install Gluttonberg!', BOLD) %>\n")
    status = copy_files if status
    status = run_migrations if status
    status = bootstrap_data if status
    status = setup_admin if status
    if status
      line.say("<%= color('Finished installing Guttonberg.\nEnjoy!', GREEN) %>\n\n")
    else
      line.say("<%= color('Sorry, There was an error and Gluttonberg could not be installed.', RED) %>\n\n")
    end
  end


  desc "Cleanup a bad install #TODO"
  task :cleanup => :environment do
    line = HighLine.new
    answer = line.ask("<%= color('This will attempt to clean up Gluttonberg.\nThere are not guarantees this will work properly.\nYou may need to still clean up a few files by hand.\nPlease type', YELLOW) %><%= color(' Gluttonberg ', BOLD) %><%= color('if you agree:  ', YELLOW) %>")
    if answer == "Gluttonberg"
      line.say("<%= color('Attempting to clean...', GREEN) %>")
      line.say("<%= color('Cleaned!\nYou may now try to install', GREEN) %><%= color(' Gluttonberg ', BOLD) %><%= color('again.\nThere may still be a few files left on the system.', GREEN) %>")
    else
      line.say("<%= color('You didnt say the magic word.', RED) %>")
    end
  end

  desc "Generate default locale (en-au)"
  task :generate_default_locale => :environment do
    Gluttonberg::Locale.generate_default_locale
  end

  desc "Generate or update default settings"
  task :generate_or_update_default_settings => :environment do
    Gluttonberg::Setting.generate_common_settings
  end

  desc "Update page descriptions"
  task :update_page_descriptions => :environment do
    Gluttonberg::Page.repair_pages_structure
  end

  desc "Copies missing assets from Railties (e.g. plugins, engines). You can specify Railties to use with FROM=railtie1,railtie2"
  task :copy_assets => :rails_env do
    begin
      Rails.application.initialize!
      app_root_path = Rails.root
      engine_root_path = Gluttonberg::Engine.root

      ["images" , "stylesheets", "javascripts"].each do |assets_dir|
        FileUtils.mkdir_p File.join(app_root_path , "app/assets/")
        FileUtils.cp_r File.join(engine_root_path , "app/assets/#{assets_dir}"), File.join(app_root_path , "vendor/assets")
      end # loop
      puts "Completed"
    rescue => e
      puts "#{e}"
    end
  end #task

  desc "Clean Html for all models"
  task :clean_html_for_all_models => :environment do
    Rails.application.initialize!
    [Gluttonberg::HtmlContentLocalization , Gluttonberg::Page , Gluttonberg::Article , Gluttonberg::Blog , Gluttonberg::Article , Theme , Idea , User , Speaker ].each do |constant|
      if not constant.nil? and constant.is_a? Class and constant.superclass == ActiveRecord::Base
        puts constant
        begin
          constant.all.each do |v|
            v.save
          end
        rescue => e
          puts e
        end

      end
    end

    Gluttonberg::HtmlContentLocalization.all.each do |l|
      l.text = Gluttonberg::HtmlContentLocalization.clean_tags(l.text)
      l.save_without_revision
    end
  end

  def copy_files
    begin
      line = HighLine.new
      line.say("<%= color('Moving files into place...', YELLOW) %>")
      FileUtils.mkdir_p(File.join(Rails.root, "db", "migrate"))
      FileUtils.mkdir_p(File.join(Rails.root, "app", "views", "pages"))
      FileUtils.cp(File.join(Gluttonberg::Engine.root, "installer", "gluttonberg_migration.rb"), File.join(Rails.root, "db", "migrate", "#{Time.now.utc.strftime("%Y%m%d%H%M%S")}_gluttonberg_migration.rb"))
      sleep(1)
      FileUtils.cp(File.join(Gluttonberg::Engine.root, "installer", "gluttonberg_migration2.rb"), File.join(Rails.root, "db", "migrate", "#{Time.now.utc.strftime("%Y%m%d%H%M%S")}_gluttonberg_migration2.rb"))
      sleep(1)
      FileUtils.cp(File.join(Gluttonberg::Engine.root, "installer", "add_artist_and_link_to_assets.rb"), File.join(Rails.root, "db", "migrate", "#{Time.now.utc.strftime("%Y%m%d%H%M%S")}_add_artist_and_link_to_assets.rb"))
      FileUtils.cp(File.join(Gluttonberg::Engine.root, "installer", "page_descriptions.rb"), File.join(Rails.root, "config", "page_descriptions.rb"))
      FileUtils.cp(File.join(Gluttonberg::Engine.root, "installer", "sitemap.rb"), File.join(Rails.root, "config", "sitemap.rb"))
      FileUtils.cp(File.join(Gluttonberg::Engine.root, "installer", "gluttonberg_basic_settings.rb"), File.join(Rails.root, "config", "initializers", "gluttonberg_basic_settings.rb"))
      FileUtils.cp(File.join(Gluttonberg::Engine.root, "installer", "gluttonberg_advance_settings.rb"), File.join(Rails.root, "config", "initializers", "gluttonberg_advance_settings.rb"))
      FileUtils.cp(File.join(Gluttonberg::Engine.root, "installer", "sidekiq.rb"), File.join(Rails.root, "config", "initializers", "sidekiq.rb"))
      FileUtils.cp(File.join(Gluttonberg::Engine.root, "installer", "public.html.haml"), File.join(Rails.root, "app", "views", "layouts", "public.html.haml"))
      FileUtils.cp(File.join(Gluttonberg::Engine.root, "installer", "Procfile"), File.join(Rails.root, "Procfile"))
      FileUtils.cp(File.join(Gluttonberg::Engine.root, "installer", "unicorn.rb"), File.join(Rails.root, "config", "unicorn.rb"))
      FileUtils.cp(File.join(Gluttonberg::Engine.root, "installer", "bootstrap.min.css"), File.join(Rails.root, "app", "assets", "stylesheets", "bootstrap.min.css"))
      FileUtils.cp(File.join(Gluttonberg::Engine.root, "installer", "bootstrap-theme.min.css"), File.join(Rails.root, "app", "assets", "stylesheets", "bootstrap-theme.min.css"))
      FileUtils.cp(File.join(Gluttonberg::Engine.root, "installer", "bootstrap.min.js"), File.join(Rails.root, "app", "assets", "javascripts", "bootstrap.min.js"))
      FileUtils.cp(File.join(Gluttonberg::Engine.root, "app", "models", "ability.rb"), File.join(Rails.root, "app", "models", "ability.rb"))
      FileUtils.rm(File.join(Rails.root, "public", "index.html"))
      return true
    rescue => e
      line.say("<%= color('Failure!', RED) %>")
      line.say(e.to_s)
      return false
    end
  end

  def run_migrations
    begin
      line = HighLine.new
      line.say("<%= color('Running migrations..', YELLOW) %>")
      ActiveRecord::Migration.verbose = false
      ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths, nil)
      return true
    rescue => e
      line.say("<%= color('Failure!', RED) %>")
      line.say(e.to_s)
      return false
    end
  end

  def bootstrap_data
    begin
      line = HighLine.new
      line.say("<%= color('Bootstrapping data..', YELLOW) %>")
      Rake::Task["gluttonberg:library:bootstrap"].invoke
      Rake::Task["gluttonberg:generate_default_locale"].invoke
      Rake::Task["gluttonberg:generate_or_update_default_settings"].invoke
      add_memory_store_config_in_production
      return true
    rescue => e
      line.say("<%= color('Failure!', RED) %>")
      line.say(e.to_s)
      return false
    end
  end

  def add_memory_store_config_in_production
    begin
      data = []
      file_path = File.join(Rails.root, "config", "environments" , "production.rb" )
      file = File.new(file_path)

      file.each_line do |line|
        data << line
      end

      file.close

      file = File.new(file_path , "w" )
      data.reverse.each_with_index do |line, index|
        if line.include?("end")
          data[data.length-index-1] = "  config.cache_store = :memory_store\nend\n"
          break
        end
      end
      file.puts(data.join(""))
      file.close
      return true
    rescue => e
      return false
    end
  end

  def setup_admin
    begin
      line = HighLine.new
      line.say("<%= color('Setting up admin user..', YELLOW) %>")
      line.say("<%= color('Please answer the following questions..', YELLOW) %>")
      first_name = line.ask("Enter your first name:  ") {|q| q.validate = /.{2,}/}
      last_name = line.ask("Enter your last name:  ") {|q| q.validate = /.{2,}/}
      email = line.ask("Enter your email:  ") {|q| q.validate = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i}
      password = ""
      password = line.ask("Enter a password:  ")  { |q| q.validate = /^(?=.*\d)(?=.*[a-zA-Z])(?!.*[^\w\S\s]).{6,}$/; q.echo = "x" }

      user = User.new(:email => email, :password => password, :password_confirmation => password, :first_name => first_name, :last_name => last_name)
      user.role = "super_admin"
      user.save!
      return true
    rescue => e
      line = HighLine.new
      line.say("<%= color('Failure!', RED) %>")
      line.say(e.to_s)
      return false
    end
  end

end
