module Gluttonberg
  # This module allows custom controllers to be registered wtih Gluttonberg’s
  # administration.
  module Components
    @@components  = {}
    @@routes      = {}
    @@nav_entries = nil
    @@main_nav_entries = []
    @@registered  = nil
    Component     = Struct.new(:name, :label , :admin_url, :only_for_super_admin )

    # Registers a controller
    def self.register(name, opts = {})
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
        [v[:label], k, url , v[:only_for_super_admin]]
      end
    end

    def self.section_name_for_controller(controllername)
      component = @@components[controllername.to_sym]
      component.blank? ? nil : component[:section_name]
    end

    def self.clear_main_nav
      @@main_nav_entries = []
    end

    def self.init_main_nav
      Gluttonberg::Components.register_for_main_nav("Dashboard", "/admin")
      Gluttonberg::Components.register_for_main_nav("Content", "/admin/pages")
      Gluttonberg::Components.register_for_main_nav("Library", "/admin/assets/all/page/1")
      Gluttonberg::Components.register_for_main_nav("Members", "/admin/membership/members")
      Gluttonberg::Components.register_for_main_nav("Settings", "/admin/configurations")
    end

    def self.register_for_main_nav(name , url, opts = {})
      opts[:enabled] = true if opts[:enabled].blank?
      opts[:only_for_super_admin] = false if opts[:only_for_super_admin].blank?
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


  end
end