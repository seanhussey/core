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
          class << self;  attr_accessor :slug_source_field_name, :slug_scope end
          attr_accessor :current_slug

        end
      end

      module ClassMethods
        def self.check_for_duplication(slug, object, potential_duplicates)
          unless potential_duplicates.blank?
            if potential_duplicates.length > 1 || (potential_duplicates.length == 1 && potential_duplicates.first.id != object.id )
              number = potential_duplicates.length+1
              begin
                slug = "#{self.slug_without_postfix(slug)}-#{number}"
                number += 1
              end while object.find_potential_duplicates(slug).map{|o| o.slug}.include?(slug)
            end
          end
          slug
        end

        def self.slug_without_postfix(slug)
          temp_slug = slug

          unless temp_slug.blank?
            slug_tokens = temp_slug.split("-")
            if slug_tokens.last.to_i.to_s == slug_tokens.last && slug_tokens.length > 1
              slug_tokens = slug_tokens[0..-2]
              temp_slug = slug_tokens.join("-")
            end
          end
          temp_slug
        end
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
          current_slug = self.slug
          new_slug = new_slug.to_s.sluglize unless new_slug.blank?
          new_slug = unique_slug(new_slug)
          write_attribute(:slug, new_slug)
          if self.respond_to?(:previous_slug) && self.slug_changed? && self.slug != current_slug
            write_attribute(:previous_slug, current_slug)
          end
          new_slug
        end

        #protected
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
            potential_duplicates = find_potential_duplicates(self.slug)

            unless potential_duplicates.blank?
              if potential_duplicates.length > 1 || (potential_duplicates.length == 1 && potential_duplicates.first.id != self.id )
                number = potential_duplicates.length+1
                begin
                  self.slug = "#{slug_without_postfix(self.slug)}-#{number}"
                  number += 1
                end while find_potential_duplicates(slug).map{|o| o.slug}.include?(slug)
              end
            end
          end

          def unique_slug(slug)
            # check duplication: add id at the end if its duplicated
            potential_duplicates = find_potential_duplicates(slug)
            Content::SlugManagement::ClassMethods.check_for_duplication(slug, self, potential_duplicates)
          end

          def slug_without_postfix(slug)
            Content::SlugManagement::ClassMethods.slug_without_postfix(slug)
          end

          def find_potential_duplicates(slug)
            unless self.class.where(["slug = ? ", slug]).first.blank?
              temp_slug = slug_without_postfix(slug)
              potential_duplicates = self.class.where(["slug = ? OR slug = ? OR slug like ? ", slug, temp_slug, "#{temp_slug}-%"])
              
              unless self.class.slug_scope.blank?
                potential_duplicates = potential_duplicates.where(self.class.slug_scope => self.send(self.class.slug_scope) )
              end
              potential_duplicates = potential_duplicates.all
              potential_duplicates = potential_duplicates.find_all{|obj| obj.id != self.id}
              potential_duplicates
            else
              []
            end
          end

      end

    end
  end
end
