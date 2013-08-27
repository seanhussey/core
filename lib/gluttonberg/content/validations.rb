module Gluttonberg
  module Content
    # A mixin which allows for any arbitrary model to have multiple versions. It will
    # generate the versioning models and add methods for creating, managing and
    # retrieving different versions of a record.
    # In reality this is behaving like a wrapper on acts_as_versioned
    module Validations
      extend ActiveSupport::Concern

      def self.setup
        ::ActiveRecord::Base.send :include, Gluttonberg::Content::Validations
      end

      # it validates all columns values using max limit from database schema
      def max_field_length
        self.class.columns.each do |column|
          unless column.limit.blank?
            val = self.send(column.name)
            if !val.blank? and val.length > column.limit
              errors.add(column.name, "is too long (maximum is #{column.limit} characters)")
            end
          end
        end
      end
    end
  end
end