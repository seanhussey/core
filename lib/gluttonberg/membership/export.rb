module Gluttonberg
  module Membership
    module Import
      def self.included(klass)
        klass.class_eval do
          extend ClassMethods
        end
      end

      module ClassMethods
        #export to a csv
        def exportCSV
          all_records = self.all
          csv_class = nil
          if RUBY_VERSION >= "1.9"
            require 'csv'
            csv_class = CSV
          else
            csv_class = FasterCSV
          end
          other_columns = {}
          csv_string = csv_class.generate do |csv|
              header_row = ["DATABASE ID",Rails.configuration.member_csv_metadata[:first_name],Rails.configuration.member_csv_metadata[:last_name], Rails.configuration.member_csv_metadata[:email], Rails.configuration.member_csv_metadata[:groups]]

              index = 0
              Rails.configuration.member_csv_metadata.each do |key , val|
                if ![:first_name, :last_name , :email , :groups].include?(key)
                  other_columns[key] = index + 5
                  header_row << val
                  index += 1
                end
              end
              csv << header_row

              all_records.each do |record|
                data_row = [record.id, record.first_name, record.last_name , record.email , record.groups_name("; ")]
                other_columns.each do |key , val|
                  if !val.blank? && val >= 0
                    data_row[val] = record.send(key)
                  end
                end
                csv << data_row
              end
          end

          csv_string
        end

      end #ClassMethods
    end
  end
end