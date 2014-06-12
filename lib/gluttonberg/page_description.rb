module Gluttonberg
  # This defines a DSL for for creating page descriptions. Page descriptions
  # are used to declare the page archetypes in an installation.
  #
  # * Name & description
  # * Sections
  #   - Html
  #   - Plain text
  #   - Image
  # * Redirections
  # * Rewrites to controllers
  #
  # It also provides access to any page descriptions that have been declared.
  class PageDescription
    @@_descriptions = {}
    @@_categorised_descriptions = {}
    @@_description_names = {}
    @@_home_page    = nil


    attr_accessor :options

    def initialize(name)
      @position = 0
      @options = {
        :name       => name,
        :home       => false,
        :domain       => :default,
        :behaviour  => :default,
        :layout     => "public",
        :view       => "default",
        :page_options => {},
        :group => nil,
        :contributor_access => false
      }
      @sections = {}
      @@_descriptions[name] = self
    end

    %w(label view layout limit description).each do |opt|
      class_eval %{
        def #{opt}(opt_value)
          @options[:#{opt}] = opt_value
        end
      }
    end

    # This is a destructive method which removes all page definitions. Mainly
    # used for testing and debugging.
    def self.clear!
      @@_descriptions.clear
      @@_categorised_descriptions.clear
      @@_description_names.clear
      @@_home_page = nil
    end

    # This just loads the page_descriptions.rb file from the config dir.
    # The specified file should contain the various page descriptions.
    def self.setup
      path = File.join(Rails.root, "config", "page_descriptions.rb")
      eval(File.read(path)) if File.exists?(path)
    end

    def self.add(&blk)
      class_eval(&blk)
    end

    # Define a page. This can be called directly, but is generally used inside
    # of an #add block.
    def self.page(name, &blk)
      new(name).instance_eval(&blk)
    end

    # Returns the definition for a specific page description.
    def self.[](name)
      self.all[name.to_s.downcase.to_sym]
    end

    # Returns the full list of page descriptions as a hash, keyed to each
    # description’s name.
    def self.all
      @@_descriptions
    end

    # Returns all the descriptions with the matching behaviour in an array.
    def self.behaviour(name)
      @@_categorised_descriptions[name] ||= @@_descriptions.inject([]) do |memo, desc|
        memo << desc[1] if desc[1][:behaviour] == name
        memo
      end
    end

    # Collects all the names of the descriptions which have the specified
    # behaviour.
    def self.names_for(name)
      @@_description_names[name] ||= self.behaviour(name).collect {|d| d[:name]}
    end

    # Returns the value the specified option — label, description etc.
    def [](opt)
      @options[opt]
    end

    # Returns the collection of sections defined for a page description.
    def sections
      @sections
    end

    def contains_section?(sec_name , type_name)
      @sections.each do |name, section|
        return true if sec_name.to_s == name.to_s && section[:type].to_s == type_name.to_s
      end
      false
    end

    # Set a description as the home page.
    def home(bool)
      @options[:home] = bool
      if bool
        @@_home_page = self
        @options[:limit] = 1
      elsif @@_home_page == self
        @@_home_page = nil
        @options.delete(:limit)
      end
    end

    def self.find_home_page_description_for_domain?(domain_name)
      page_desc = PageDescription.all.find{|key , val|  val.home_for_domain?(domain_name) }
      page_desc = page_desc.last unless page_desc.blank?
      page_desc
    end

    # Set a description as the home page.
    def domain(domain_name)
      @options[:domain] = domain_name
    end

    # Sugar for defining a section.
    def section(name, &blk)
      new_section = Section.new(name , @position)
      new_section.instance_eval(&blk)
      @sections[name] = new_section
      @position += 1
    end

    def remove_section(name)
      @sections.delete(name)
    end

    def top_level_page?
       name == :top_level_page
    end

    def name
       @options[:name]
    end

    def redirection_required?
      @options[:behaviour] == :redirect
    end

    def page_options(opts = {})
      @options[:page_options] = opts
    end

    def group(grp)
      @options[:group] = grp
    end

    def contributor_access(access)
      @options[:contributor_access] = access
    end

    def contributor_access?
      @options[:contributor_access]
    end

    # Configures the page to act as a rewrite to named route. This doesn’t
    # work like a rewrite in the traditional sense, since it is intended to be
    # used to redirect requests to a controller. Becuase of this it can't rewrite
    # to a path, it needs to use a named route.
    def rewrite_to(route)
      @rewrite_route = route
      @options[:behaviour] = :rewrite
    end

    # Allows us to check if this page needs to have a path rewritten to point
    # to a controller.
    def rewrite_required?
      @options[:behaviour] == :rewrite
    end

    # Returns the named route to be used when rewriting the request.
    def rewrite_route
      @rewrite_route
    end

    # Declare this description as a redirect. The redirect type can be:
    # :path   - The path to redirect to, hey, simple!
    # :page   - Allows the user to specify which other page they want to
    #           redirect to.
    def redirect_to(path_or_url)
      @redirect_path_or_url  = path_or_url if path_or_url
      @options[:behaviour]  = :redirect
    end

    # Checks to see if this is home. Duh.
    def home?
      @options[:home]
    end

    # Checks to see if this is home for a domain. Duh.
    def home_for_domain?(domain_name)
      if Rails.configuration.multisite == false
        home?
      else
        home? && Rails.configuration.multisite[@options[:domain]] == domain_name
      end
    end

    # Returns the path that this description wants to redirect to. It accepts
    # the current page — from which is extracts the redirect options — and the
    # params for the current request.
    def redirect_url(page, params={})
      @redirect_path_or_url
    end

    private

    # This class is used to define the sections of content in a page
    # description. This class should never be instantiated direction, instead
    # sections should be declared in the description DSL.
    class Section
      def initialize(name , pos)
        @options = {:name => name, :limit => 1 , :position => pos}
        @custom_config = {}
      end

      %w(type limit label select_options_data select_options_default_value).each do |opt|
        class_eval %{
          def #{opt}(opt_value)
            @options[:#{opt}] = opt_value
          end
        }
      end

      # Returns the value for the specified option — name, description etc.
      def [](opt)
        @options[opt]
      end
    end # Section
  end # PageDescription
end # Gluttonberg
