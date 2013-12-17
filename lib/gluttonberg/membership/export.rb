module Gluttonberg
  module Membership
    module Export
      extend ActiveSupport::Concern
     
      module ClassMethods
        #export to a csv
        def exportCSV
          all_records = self.order("id asc").all
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
                other_columns[key] = index + fix_columns_count
                index += 1
              end
            end
            other_columns
          end

          def fix_columns_count
            count = 1
            count+= 1 unless Rails.configuration.member_csv_metadata[:first_name].blank? 
            count+= 1 unless Rails.configuration.member_csv_metadata[:last_name].blank? 
            count+= 1 unless Rails.configuration.member_csv_metadata[:email].blank? 
            count+= 1 unless Rails.configuration.member_csv_metadata[:groups].blank? 
            count
          end

          def prepare_header_row
            header_row = [
              "DATABASE ID"
            ]

            header_row << Rails.configuration.member_csv_metadata[:first_name] unless Rails.configuration.member_csv_metadata[:first_name].blank? 
            header_row << Rails.configuration.member_csv_metadata[:last_name] unless Rails.configuration.member_csv_metadata[:last_name].blank? 
            header_row << Rails.configuration.member_csv_metadata[:email] unless Rails.configuration.member_csv_metadata[:email].blank? 
            header_row << Rails.configuration.member_csv_metadata[:groups] unless Rails.configuration.member_csv_metadata[:groups].blank? 
             
            Rails.configuration.member_csv_metadata.each do |key , val|
              if ![:first_name, :last_name , :email , :groups].include?(key)
                header_row << val
              end
            end
            header_row
          end

          def prepare_row(record, other_columns)
            data_row = [record.id]
            data_row << record.first_name unless Rails.configuration.member_csv_metadata[:first_name].blank? 
            data_row << record.last_name unless Rails.configuration.member_csv_metadata[:last_name].blank? 
            data_row << record.email unless Rails.configuration.member_csv_metadata[:email].blank? 
            data_row << record.groups_name("; ") unless Rails.configuration.member_csv_metadata[:groups].blank? 
            


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