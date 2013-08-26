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

      def self.all_trash
        all_records = []
        Gluttonberg::Content::Trashable.classes.each do |model|
          model = model.constantize
          if model.show_on_trash_page == true
            all_records << model.only_deleted
          end
        end
        all_records = all_records.flatten
        all_records = all_records.sort{|x,y| y.deleted_at <=> x.deleted_at}
      end

      def self.empty_trash
        self.all_trash.each do |item|
          item.destroy!
        end
      end

      module ClassMethods
        def is_trashable(options = {}, &extension)
          @@show_on_trash_page = options[:hidden].blank? || options[:hidden] == false
          acts_as_paranoid
          Trashable.register(self.name)
          include TrashableModelHelpers
          self.show_on_trash_page = options[:hidden].blank? || options[:hidden] == false
        end
      end

      module TrashableModelHelpers
        extend ActiveSupport::Concern

        included do
          cattr_accessor :show_on_trash_page
        end

        module ClassMethods
          def trashable?
            self.new.respond_to?(:deleted_at)
          end
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
      end #TrashableHelpers

    end
  end
end