module Gluttonberg
  module Content
    # A mixin which allows for any arbitrary model to be trashable (soft delete)
    # In reality this is behaving like a wrapper on acts_as_paranoid
    module Trashable
      extend ActiveSupport::Concern
      # A collection of the classes which have this module included in it.
      @classes = []

      def self.setup
        ::ActiveRecord::Base.send :include, Gluttonberg::Content::Trashable
      end

      # register content classes. We can do this inside 
      # included block, but in rails lazyloading behavior 
      # it is not properly working.
      def self.register(klass)
        @classes << klass
        @classes.uniq!
      end

      # An accessor which provides the collection of 
      # classes with mixin this module.
      def self.classes
        @classes
      end

      module ClassMethods

        def is_trashable(options = {}, &extension)
          acts_as_paranoid
          puts "-----#{self.name}"
          Trashable.register(self.name)
          include OverrideActsAsParanoid
        end

        def trashable?
          self.respond_to?(:deleted_at)
        end

      end

      module OverrideActsAsParanoid
        
      end

      def trashable?
        self.class.trashable?
      end

      def title_or_name?
        if self.respond_to?(:title)
          self.title
        elsif self.respond_to?(:name)
          self.name
        else
          id
        end
      end

    end
  end
end