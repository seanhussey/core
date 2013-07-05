require "highline"
namespace :gluttonberg do

  desc "Install Gluttonberg"
  task :install => :environment do
    line = HighLine.new
    line.say("<%= color('Preparing to install Gluttonberg!', BOLD) %>\n")
    copy_files
    run_migrations
    bootstrap_data
    setup_admin
    line.say("<%= color('Finished installing Guttonberg.\nEnjoy!', GREEN) %>\n\n")
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
      FileUtils.cp Gluttonberg::Engine.root + "installer/delayed_job_script", Rails.root + "script/delayed_job"
      FileUtils.mkdir_p(File.join(Rails.root, "db", "migrate"))
      FileUtils.mkdir_p(File.join(Rails.root, "app", "views", "pages"))
      FileUtils.cp(File.join(Gluttonberg::Engine.root, "installer", "gluttonberg_migration.rb"), File.join(Rails.root, "db", "migrate", "#{Time.now.utc.strftime("%Y%m%d%H%M%S")}_gluttonberg_migration.rb"))
      FileUtils.cp(File.join(Gluttonberg::Engine.root, "installer", "page_descriptions.rb"), File.join(Rails.root, "config", "page_descriptions.rb"))
      FileUtils.cp(File.join(Gluttonberg::Engine.root, "installer", "sitemap.rb"), File.join(Rails.root, "config", "sitemap.rb"))
      FileUtils.cp(File.join(Gluttonberg::Engine.root, "installer", "gluttonberg_basic_settings.rb"), File.join(Rails.root, "config", "initializers", "gluttonberg_basic_settings.rb"))
      FileUtils.cp(File.join(Gluttonberg::Engine.root, "installer", "gluttonberg_advance_settings.rb"), File.join(Rails.root, "config", "initializers", "gluttonberg_advance_settings.rb"))
      FileUtils.cp(File.join(Gluttonberg::Engine.root, "installer", "public.html.haml"), File.join(Rails.root, "app", "views", "layouts", "public.html.haml"))
      FileUtils.rm(File.join(Rails.root, "public", "index.html"))
      FileUtils.chmod(0755, File.join(Rails.root, "script", "delayed_job"))
    rescue => e
      line.say("<%= color('Failure!', RED) %>")
      line.say(e.to_s)
    end
  end

  def run_migrations
    begin
      line = HighLine.new
      line.say("<%= color('Running migrations..', YELLOW) %>")
      ActiveRecord::Migration.verbose = false
      ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths, nil)
    rescue => e
      line.say("<%= color('Failure!', RED) %>")
      line.say(e.to_s)
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
    rescue => e
      line.say("<%= color('Failure!', RED) %>")
      line.say(e.to_s)
    end
  end

  def add_memory_store_config_in_production
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
  end

  def setup_admin
    begin
      line = HighLine.new
      line.say("<%= color('Setting up admin user..', YELLOW) %>")
      line.say("<%= color('Please answer the following questions..', YELLOW) %>")
      first_name = line.ask("Enter your first name:  ")
      last_name = line.ask("Enter your last name:  ")
      email = line.ask("Enter your email:  ")
      password = line.ask("Enter a password:  ")  { |q| q.echo = "x" }

      user = User.new(:email => email, :password => password, :password_confirmation => password, :first_name => first_name, :last_name => last_name)
      user.role = "super_admin"
      user.save

    rescue => e
      line = HighLine.new
      line.say("<%= color('Failure!', RED) %>")
      line.say(e.to_s)
    end
  end

end
