# encoding: utf-8
module Gluttonberg
  module Content
    # This module can be mixed into a class to provide slug management methods
    module SlugManagement

      # This included hook is used to declare the various properties and class
      # ivars we need.
      def self.included(klass)
        klass.class_eval do
          extend ClassMethods
          include InstanceMethods

          before_validation :slug_management
          class << self;  attr_accessor :slug_source_field_name end
          attr_accessor :current_slug

        end
      end

      module ClassMethods

      end

      module InstanceMethods

        def get_slug_source
          if self.class.slug_source_field_name.blank?
            if self.respond_to?(:name)
              self.class.slug_source_field_name= :name
            elsif self.respond_to?(:title)
              self.class.slug_source_field_name= :title
            else
              self.class.slug_source_field_name= :id
            end
          end
          self.class.slug_source_field_name
        end

        def slug=(new_slug)
          #if you're changing this regex, make sure to change the one in /javascripts/slug_management.js too
          # utf-8 special chars are fixed for new ruby 1.9.2
          unless new_slug.blank?
            new_slug = new_slug.to_s.downcase.gsub(/\s/, '-').gsub(/[\!\*'"″′‟‛„‚”“”˝\(\)\;\:\.\@\&\=\+\$\,\/?\%\#\[\]]/, '')
            new_slug = new_slug.gsub(/_$/,'-') # replace underscores with hyphen
            while new_slug.include?("--")
              new_slug = new_slug.gsub('--','-') # remove consective hyphen
            end
            new_slug = new_slug.gsub(/-$/,'') # remove trailing hyphen
          end
          write_attribute(:slug, new_slug)
        end

        protected
        # Checks If slug is blank then tries to set slug using following logic
        # if slug_field_name is set then use its value and make it slug
        # otherwise checks for name column
        # otherwise checks for title column
        # else get id as slug
          def slug_management
            if self.slug.blank?
              if self.class.slug_source_field_name.blank?
                self.get_slug_source
              end
              self.slug= self.send(self.class.slug_source_field_name)
            end #slug.blank
            self.fix_duplicated_slug
          end

          def fix_duplicated_slug
            # check duplication: add id at the end if its duplicated
            already_exist = self.class.where(:slug => self.slug).all
            unless already_exist.blank?
              if already_exist.length > 1 || (already_exist.length == 1 && already_exist.first.id != self.id )
                self.slug= "#{self.slug}-#{already_exist.length+1}"
              end
            end
          end

      end

    end
  end
end
