module Gluttonberg
  module Content
    # A mixin which allows for any arbitrary model to have multiple versions. It will
    # generate the versioning models and add methods for creating, managing and
    # retrieving different versions of a record.
    # In reality this is behaving like a wrapper on acts_as_versioned
    module Versioning
      extend ActiveSupport::Concern

      included do
        attr_accessor :current_user_id
      end

      def self.setup
        ::ActiveRecord::Base.send :include, Gluttonberg::Content::Versioning
      end

      def versioned?
        self.class.versioned?
      end

      module ClassMethods
        def is_versioned(options = {}, &extension)
          excluded_columns = options.delete(:non_versioned_columns)
          acts_as_versioned( options.merge( :limit => Gluttonberg::Setting.get_setting("number_of_revisions") ) , &extension )
          self.non_versioned_columns << ['state' ,'published_at', 'user_id', 'locale_id', 'position']
          self.non_versioned_columns << excluded_columns
          self.non_versioned_columns.flatten!
          include OverrideActsAsVersioned
        end

        def versioned?
          self.respond_to?(:versioned_class_name)
        end
      end

      module OverrideActsAsVersioned
        
        # Clears old revisions if a limit is set with the :limit option in <tt>acts_as_versioned</tt>.
        # Override this method to set your own criteria for clearing old versions.
        def clear_old_versions
          update_from_gb_versioning_settings
          return if self.class.max_version_limit == 0
          excess_baggage = send(self.class.version_column).to_i - self.class.max_version_limit
          if excess_baggage > 0
            self.class.versioned_class.delete_all ["#{self.class.version_column} <= ? and #{self.class.versioned_foreign_key} = ?", excess_baggage, id]
          end
        end 

        def update_from_gb_versioning_settings
          if self.class.max_version_limit == 0
           tmp_number_of_revisions = Gluttonberg::Setting.get_setting("number_of_revisions")
           self.class.max_version_limit = tmp_number_of_revisions.to_i unless tmp_number_of_revisions.blank?
          end
        end 

      end

    end
  end
end