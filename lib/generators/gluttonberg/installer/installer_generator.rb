require 'rails/generators'
require 'rails/generators/migration'

class Gluttonberg::InstallerGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  def self.source_root
    @source_root ||= File.join(File.dirname(__FILE__), 'templates')
  end

  def self.next_migration_number(dirname)
    if ActiveRecord::Base.timestamped_migrations
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    else
      "%.3d" % (current_migration_number(dirname) + 1)
    end
  end

  def create_delayed_job_script_file
    template 'delayed_job_script', 'script/delayed_job'
    chmod 'script/delayed_job', 0755
  end

  def create_migration_file
    migration_template 'gluttonberg_migration.rb', 'db/migrate/gluttonberg_migration.rb'
    rake("gluttonberg_engine:install:migrations")
  end

  def create_page_descriptions_file
    copy_file 'page_descriptions.rb', 'config/page_descriptions.rb'
  end

  def create_sitemaprb_file
    copy_file 'sitemap.rb', 'config/sitemap.rb'
  end

  def create_default_public_layout
    #create pages folder
    path = File.join(Rails.root, "app", "views" , "pages" )
    FileUtils.mkdir(path) unless File.exists?(path)
    #copy layout into host app
    template "public.html.haml", File.join('app/views/layouts', "public.html.haml")
  end

  def run_migration
    rake("db:migrate")
  end

  def bootstrap_data
    rake("gluttonberg:library:bootstrap")
    rake("gluttonberg:generate_default_locale")
    rake("gluttonberg:generate_or_update_default_settings")
  end

  def create_initializer_file
    copy_file "gluttonberg_basic_settings.rb", "config/initializers/gluttonberg_basic_settings.rb"
    copy_file "gluttonberg_advance_settings.rb", "config/initializers/gluttonberg_advance_settings.rb"
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

end

