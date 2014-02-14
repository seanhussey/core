module Gluttonberg
  module Content
    # A mixin which allows for any arbitrary model to be localized. It will
    # generate the localization models and add methods for creating and
    # retrieving localized versions of a record.
    module Localization
      extend ActiveSupport::Concern

      included do
        cattr_accessor :localized, :localized_model, :localized_model_name, :localized_fields, :locale, :parent_key;
        self.localized = false
        self.localized_fields = []
      end
      
      module ClassMethods
        def is_localized(opts={}, &blk)
          # Why yes, this is localized.
          self.localized = true
          self.parent_key = (opts[:parent_key] || :parent_id)

          # Create the localization model
          create_localization_model(&blk)
        end

        def localized?
          self.localized
        end

        # Returns a new instance of the model, with a localization instance
        # already assigned to it based on the options passed in.
        #
        # The options include the attributes for the both new model and its localization.
        def new_with_localization(attrs={})
          new_model = new
          default_localization = nil
          # new localization object for all locales.
          Gluttonberg::Locale.all.each do |locale|
            loc = self.localized_model.new(:locale_id => locale.id)
            new_model.instance_variable_set(:@current_localization, loc)
            new_model.localizations << loc
            loc.parent = new_model
            #update current object and current localization
            attrs.each do |name, value|
              new_model.send("#{name}=", value)
            end
            if locale.default?
               default_localization = loc
            end
          end

          # make default localization as default
          default_localization = new_model.localizations.first if default_localization.blank?
          new_model.instance_variable_set(:@current_localization, default_localization)
          new_model
        end

        private

          def create_localization_model(&blk)
            class_name = self.name + "Localization"
            # Check to see if the localization is inside a constant
            target = Object
            if class_name.index("::")
              modules = class_name.split("::")
              # Remove the localization class from the end
              class_name = modules.pop
              # Get each constant in turn
              modules.each { |mod| target = target.const_get(mod) }
            end

            self.localized_model = Class.new(ActiveRecord::Base)
            target.const_set(class_name, self.localized_model)
            self.localized_model_name = class_name
            self.localized_model.table_name = class_name.tableize

            add_code_to_localization_model(&blk)
          end

          def add_code_to_localization_model(&blk)
            # Add the properties declared in the block, and sprinkle in our own mixins
            self.localized_model.class_eval(&blk)
            self.localized_model.send(:include, ModelLocalization)

            self.localized_model.attr_accessible :locale_id , self.parent_key

            create_acccessors_for_localization_model
            set_associations_for_localization_model
            set_hooks_for_localization_model
          end

          def create_acccessors_for_localization_model
            # For each property on the localization model, create an accessor on
            # the parent model, without over-writing any of the existing methods.
            exclusions = [:id, :created_at, :updated_at, :locale_id , self.parent_key]
            localized_properties = self.localized_model.column_names.reject { |p| exclusions.include? p }
            non_localized_properties = self.column_names.reject { |p| exclusions.include? p }

            localized_properties.each do |prop|
              self.localized_fields << prop
              # Create the accessor that points to the localized version
              unless non_localized_properties.include?(prop)
                class_eval %{
                  def #{prop}
                     current_localization.#{prop}
                  end
                  def #{prop}=(val)
                     current_localization.#{prop} = val
                  end
                }
              end
            end
          end

          def set_associations_for_localization_model
            # Associate the model and it’s localization
            has_many  :localizations, :class_name => self.localized_model.name.to_s, :foreign_key => self.parent_key, :dependent => :destroy
            has_one  :default_localization, :class_name => self.localized_model.name.to_s, :foreign_key => self.parent_key, :conditions =>  proc { ["locale_id = ?", Locale.first_default.id] }
            self.localized_model.belongs_to(:parent, :class_name => self.name, :foreign_key => self.parent_key)
          end

          def set_hooks_for_localization_model
            # Set up validations for when we update in the presence of a localization
            after_validation  :validate_current_localization
            after_save    :save_current_localization
          end
        end

        # InstanceMethods
        def localized?
          self.class.localized?
        end

        # returns current localization if current localization does not exist then init it with default localization
        def current_localization
          if @current_localization.blank?
            @current_localization = self.default_localization
            @current_localization.parent = self unless @current_localization.blank?
          end
          @current_localization
        end

        def current_localization=(localization)
          self.instance_variable_set(:@current_localization, localization)
        end

        # load locaization for given locale (locale id or locale objects both are acceptable)
        # if localization for given locale does not exist then create localization for it
        # and if creation of localization failed then return default localization
        def load_localization(locale, fallback = true)
          opts = {}
          opts[:locale_id] = locale.kind_of?(Gluttonberg::Locale) ? locale.id: locale
          opts[self.parent_key] = self.id
          # Go and find the localization
          self.current_localization = nil
          self.current_localization = self.class.localized_model.where(opts).first
          if @current_localization.blank? && !locale.blank?
            self.current_localization = self.create_localization(locale)
          end
          # Check to see if we missed the load and if we also need the fallback
          if self.current_localization.blank? && fallback
            self.current_localization = self.default_localization
          end
          self.current_localization.parent = self unless self.current_localization.blank?
          self.current_localization
        end



        # create localization for given locale (locale id or object both are acceptable) if it does not exist
        def create_localization(locale)
          locale_id = locale.kind_of?(Gluttonberg::Locale) ? locale.id: locale
          unless locale.blank?
            loc = self.class.localized_model.where(:locale_id => locale_id, self.parent_key => self.id).first
            if loc.blank?
              tmp_attributes = {}
              unless self.current_localization.blank?
                tmp_attributes = self.current_localization.attributes
              end
              tmp_attributes[:locale_id] = locale_id
              loc = self.class.localized_model.new(:locale_id => locale_id)
              loc.attributes = tmp_attributes
              if loc.save
                loc
              else
                nil
              end
            end
          end
        end #create_localization


        private

        # Validates the current_localization. If it is invalid, it's errors
        # are appended to the model's own errors.
        def validate_current_localization
          if current_localization
            unless current_localization.valid?
              current_localization.errors.each { |name, error| errors.add(name, error) }
            end
          end
        end

        def save_current_localization
          if current_localization && current_localization.changed?
            current_localization.save
          end
        end
      

      # This module is used when dynamically creating the localization class.
      module ModelLocalization
        extend ActiveSupport::Concern
        included do
          belongs_to :locale,   :class_name => "Gluttonberg::Locale"
        end

        def locale_name
          locale.name
        end
      end
    end # Localization
  end # Content
end # Gluttonberg