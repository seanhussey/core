module Gluttonberg
  module Content
    # A mixin which allows any arbitrary model to have default validations
    module Validations
      extend ActiveSupport::Concern

      def self.setup
        ::ActiveRecord::Base.send :include, Gluttonberg::Content::Validations
      end

      # it validates all columns values using max limit from database schema
      def max_field_length
        self.class.columns.each do |column|
          if column.type == :string &&  !column.limit.blank?
            val = self.send(column.name)
            if !val.blank? and val.length > column.limit
              errors.add(column.name, "is too long (maximum is #{column.limit} characters)")
            end
          end
        end
      end

      # it validates all integer columns values - database schema
      def integer_values
        self.class.columns.each do |column|
          if column.type == :integer
            before_type_cast = :"#{column.name}_before_type_cast"
            raw_value = self.send(before_type_cast) if self.respond_to?(before_type_cast)
            raw_value ||= self.send(column.name)
            unless raw_value.blank?
              raw_value = raw_value.to_i if raw_value.to_s =~ /\A[+-]?\d+\Z/
              unless raw_value.is_a? Integer
                errors.add(column.name, "is not an integer number")
              end
            end
          end
        end
      end

      # it validates all decimal columns values - database schema
      def decimal_values
        self.class.columns.each do |column|
          if column.type == :decimal && !column.precision.blank? && !column.scale.blank?
            before_type_cast = :"#{column.name}_before_type_cast"
            raw_value = self.send(before_type_cast) if self.respond_to?(before_type_cast)
            raw_value ||= self.send(column.name)
            unless raw_value.blank?
              unless raw_value.to_s =~ /^\A[+-]?\d{1,#{column.precision}}(\.?\d{0,#{column.scale}})?$/
                errors.add(column.name, "is not a decimal number")
              end
            end
          end
        end
      end

    end
  end
end