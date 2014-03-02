require 'rails/generators'
require 'rails/generators/migration'
require 'rails/generators/generated_attribute'

class Gluttonberg::ResourceGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  attr_accessor :name, :type

  argument :resource_name, :type => :string, :required => true
  argument :attributes, :type => :array, :default => [], :banner => "field:type field:type"

  class_option :draggable, :aliases => "-d" , :type => :boolean
  class_option :importable, :aliases => "-i" , :type => :boolean
  class_option :localized, :aliases => "-l" , :type => :boolean
  class_option :without_versioning, :aliases => "-w" , :type => :boolean

  def initialize(args, *options)
    super(args, *options)
    parse_attributes!
  end

  def self.source_root
    @source_root ||= File.join(File.dirname(__FILE__), 'templates')
  end

  def generate_migration
    migration_template "migration.rb", "db/migrate/create_#{file_name}.rb"
  end

  def generate_model
    template "model.rb", "app/models/#{file_name}.rb"
  end

  def generate_controller
    template 'admin_controller.rb', File.join('app/controllers/admin', "#{plural_name}_controller.rb")
    template 'public_controller.rb', File.join('app/controllers', "#{plural_name}_controller.rb")
  end

  def generate_views
    build_views
  end

  def add_route
    route_str = "namespace :admin do"
    route_str << draggable_move_route if draggable?
    route_str << import_export_routes if importable?
    route_str << resource_admin_routes
    route_str << "end"
    route(route_str)
    route("resources :#{plural_name}")
  end

  def add_config
    menu_config_filename = "config/initializers/gluttonberg_menu_settings.rb"
    code =  "Gluttonberg::Components.register(:#{plural_name}, :label => '#{plural_class_name}', :admin_url => :admin_#{plural_name}, :can_model_name => '#{class_name}')\n"
    if File.exist?(menu_config_filename)
      append_file(menu_config_filename, code)
    else
      File.open(menu_config_filename, "a+") { |file| file.write(code) }
    end
  end

  protected

    def build_views
      views = {
        'backend_view_index.html.haml' => File.join('app/views/admin', plural_name, "index.html.haml"),
        'backend_view_new.html.haml' => File.join('app/views/admin', plural_name, "new.html.haml"),
        'backend_view_edit.html.haml' => File.join('app/views/admin', plural_name, "edit.html.haml"),
        'backend_view_form.html.haml' => File.join('app/views/admin', plural_name, "_form.html.haml"),
        'backend_view_show.html.haml' => File.join('app/views/admin', plural_name, "show.html.haml"),
        'backend_view_import.html.haml' => File.join('app/views/admin', plural_name, "import.html.haml"),
        'public_view_index.html.haml' => File.join('app/views', plural_name, "index.html.haml"),
        'public_view_show.html.haml' => File.join('app/views', plural_name, "show.html.haml")
      }
      copy_views(views)
    end

    def copy_views(views)
      views.each do |template_name, output_path|
        template template_name, output_path
      end
    end

    def self.next_migration_number(dirname)
      Gluttonberg.next_migration_number(dirname)
    end

    def file_name
      resource_name.underscore
    end

    def class_name
      ([file_name]).map!{ |m| m.camelize }.join('::')
    end

    def versioned_class_name
      localized? ? class_name + "Localization" : class_name
    end

    def plural_class_name
      ([plural_name]).map!{ |m| m.camelize }.join('::')
    end

    def table_name
      @table_name ||= begin
        base = pluralize_table_names? ? plural_name : singular_name
      end
    end

    def parse_attributes!
      self.attributes = (attributes || []).map do |key_value|
        name, type = key_value.split(':')
        Rails::Generators::GeneratedAttribute.new(name, type)
      end
    end

    def pluralize_table_names?
      !defined?(ActiveRecord::Base) || ActiveRecord::Base.pluralize_table_names
    end

    def singular_name
      file_name
    end

    def plural_name
      @plural_name ||= singular_name.pluralize
    end

    def draggable?
      !(options[:draggable].blank?)
    end

    def importable?
      !(options[:importable].blank?)
    end

    def localized?
      !(options[:localized].blank?)
    end

    # by default models are versioned
    def versioned?
      options[:without_versioning].blank?
    end

    def attr_db_type_wrapper(attr)
      if ['asset', 'image','video','document', 'audio'].include?(attr.type.to_s)
        'integer'
      else
        attr.type.to_s
      end
    end

    def asset_filter_value(attr)
      if ['image','video','document', 'audio'].include?(attr.type.to_s)
        attr.type.to_s
      end
    end

    def attr_name_wrapper(attr)
      if ['asset', 'image','video','document', 'audio'].include?(attr.type.to_s)
        if attr.name.to_s.end_with?("_id")
          attr.name.slice(0,attr.name.length-3)
        else
          attr.name
        end
      else
        attr.name
      end
    end

    def attr_db_name_wrapper(attr)
      if ['asset', 'image','video','document', 'audio'].include?(attr.type.to_s)
        if attr.name.to_s.end_with?("_id")
          attr.name
        else
          "#{attr.name}_id"
        end
      else
        attr.name
      end
    end

    def resource_admin_routes
  %{
    resources :#{plural_name} do
      member do
        get 'delete'
        get 'duplicate'
      end
    end
  }
    end

    def draggable_move_route      
  %{
    post \"/#{plural_name}/move(.:format)\" => \"#{plural_name}#move_node\" , :as => :#{singular_name}_move
  }
    end

    def import_export_routes
  %{
    match \"/#{plural_name}/import(.:format)\" => \"#{plural_name}#import\" , :as => :#{plural_name}_import
    get \"/#{plural_name}/export(.:format)\" => \"#{plural_name}#export\" , :as => :#{plural_name}_export
  }
    end

end