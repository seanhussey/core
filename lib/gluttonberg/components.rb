module Gluttonberg
  # This module allows a developer to configure backend main and sub menues
  module Components
    @@components  = {}
    @@routes      = {}
    @@nav_entries = nil
    @@main_nav_entries = []
    @@registered  = nil
    @@cleared = false
    @@can_custom_model_list  = []
    Component     = Struct.new(:name, :label , :admin_url, :only_for_super_admin )

    def self.clear_main_nav
      @@main_nav_entries = []
      @@cleared = true
    end

    def self.init_main_nav
      unless @@cleared
        Gluttonberg::Components.register_for_main_nav("Dashboard", "/admin", :can_model_name => "Gluttonberg::Page")
        Gluttonberg::Components.register_for_main_nav("Content", "/admin/pages", :can_model_name => "Gluttonberg::Page")
        Gluttonberg::Components.register_for_main_nav("Library", "/admin/assets/all/page/1", :can_model_name => "Gluttonberg::Asset")
        Gluttonberg::Components.register_for_main_nav("Members", "/admin/membership/members", :can_model_name => "Gluttonberg::Member")
        Gluttonberg::Components.register_for_main_nav("Settings", "/admin/configurations", :can_model_name => "Gluttonberg::Setting")
      end
    end

    def self.register_for_main_nav(name , url, opts = {})
      opts[:enabled] = true if opts[:enabled].blank?
      opts[:only_for_super_admin] = false if opts[:only_for_super_admin].blank?
      self.add_to_can_model_list(opts[:can_model_name])
      if @@main_nav_entries.index{|entry| entry[0] == name}.blank?
        @@main_nav_entries << [name , url, opts]
      end
    end

    # Returns an array of components that have been given a nav_label —
    # the label implicitly registers them as nav entries. Components without
    # a label won’t turn up.
    def self.main_nav_entries
      @@main_nav_entries
    end

    def self.can_custom_model_list
      @@can_custom_model_list
    end

    # Registers a controller
    def self.register(name, opts = {})
      self.add_to_can_model_list(opts[:can_model_name])
      @@components[name] = opts
    end

    # Returns a hash of the registered components, keyed to their label.
    def self.registered
      @@registered ||= @@components.collect {|k, v| Component.new(k.to_s, v[:label] , v[:only_for_super_admin])}
    end

    # Returns an array of components that have been given a nav_label —
    # the label implicitly registers them as nav entries. Components without
    # a label won’t turn up.
    def self.nav_entries(section_name="")
      temp = @@components.find_all{|k,v| (section_name.blank? && (!v.has_key?(:section_name) || v[:section_name].blank?)) || (!section_name.blank? && v[:section_name] == section_name) }
      nav_entries = temp.collect do |k, v|
        url = if v[:admin_url]
          if v[:admin_url].is_a? Symbol
            v[:admin_url]
          else
            v[:admin_url]
          end
        end
        [v[:label], k, url , v[:only_for_super_admin], v[:can_model_name]]
      end
    end

    def self.section_name_for_controller(controllername)
      component = @@components[controllername.to_sym]
      component.blank? ? nil : component[:section_name]
    end

    def self.add_to_can_model_list(model_name)
      @@can_custom_model_list << model_name if !model_name.blank? && !["Gluttonberg::Page", "Gluttonberg::Asset", "Gluttonberg::Member", "Gluttonberg::Setting", "Gluttonberg::Gallery", ].include?(model_name)
    end

  end
end
