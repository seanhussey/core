module Gluttonberg
  module Membership
    module Export
      def self.included(klass)
        klass.class_eval do
          extend ClassMethods
        end
      end

      module ClassMethods
        #export to a csv
        def exportCSV
          all_records = self.all
          require 'csv'
          other_columns = {}
          CSV.generate do |csv|
            other_columns = find_other_columns
            csv << prepare_header_row
            all_records.each do |record|
              csv << prepare_row(record, other_columns)
            end
          end
        end

        private

          def find_other_columns
            other_columns = {}
            index = 0
            Rails.configuration.member_csv_metadata.each do |key , val|
              if ![:first_name, :last_name , :email , :groups].include?(key)
                other_columns[key] = index + 5
                index += 1
              end
            end
            other_columns
          end

          def prepare_header_row
            header_row = [
              "DATABASE ID",
              Rails.configuration.member_csv_metadata[:first_name],
              Rails.configuration.member_csv_metadata[:last_name],
              Rails.configuration.member_csv_metadata[:email],
              Rails.configuration.member_csv_metadata[:groups]
            ]

            Rails.configuration.member_csv_metadata.each do |key , val|
              if ![:first_name, :last_name , :email , :groups].include?(key)
                header_row << val
              end
            end
            header_row
          end

          def prepare_row(record, other_columns)
            data_row = [record.id, record.first_name, record.last_name , record.email , record.groups_name("; ")]
            other_columns.each do |key , val|
              if !val.blank? && val >= 0
                data_row[val] = record.send(key)
              end
            end
            data_row
          end

      end #ClassMethods
    end
  end
end