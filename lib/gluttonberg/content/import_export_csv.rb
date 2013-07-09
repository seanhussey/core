module Gluttonberg
  module Content
    # A mixin which allows for any arbitrary model to have multiple versions. It will
    # generate the versioning models and add methods for creating, managing and
    # retrieving different versions of a record.
    # In reality this is behaving like a wrapper on acts_as_versioned
    module ImportExportCSV

      def self.setup
        ::ActiveRecord::Base.send :include, Gluttonberg::Content::ImportExportCSV
      end

      def self.included(klass)
        klass.class_eval do
          extend  ClassMethods
          cattr_accessor :import_export_columns , :wysiwyg_columns
        end
      end

      module ClassMethods

        def import_export_csv(import_export_columns=nil,wysiwyg_columns=nil)
          #@@wysiwyg_columns = wysiwyg_columns
          if import_export_columns.blank?
            self.import_export_columns = self.new.attributes.keys
          else
            self.import_export_columns = import_export_columns
          end
        end


        # takes complete path to csv file.
        # if all records are created successfully then return true
        # otherwise returns array of feedback. each value represents the feedback for respective row in csv
        # sample feedback array : [true , true , [active_record error array...] , true]
        def importCSV(file_path , local_options = {})
          begin
            require 'csv'
            csv_table = CSV.read(file_path)
          rescue => e
            return "Please provide a valid CSV file with correct column names."
          end
          ImportUtils.import(file_path, local_options, self, csv_table)
        end

        class GlosentryHelper
          include ActionView::Helpers::TagHelper
          include ActionView::Helpers::TextHelper
        end

        def helper
          @h ||= GlosentryHelper.new
        end

        def exportCSV(all_records , local_options = {})
          ExportUtils.export(all_records, local_options, self)
        end

      end #ClassMethods

      class ExportUtils
        attr_accessor :all_records, :local_options, :klass, :export_column_names
        def initialize(all_records, local_options, klass)
          self.all_records = all_records
          self.local_options = local_options
          self.klass = klass
        end

        def self.export(all_records, local_options, klass)
          export_utils = ExportUtils.new(all_records, local_options, klass)
          export_utils.prepare_export_column_names
          require 'csv'

          csv_string = CSV.generate do |csv|
            csv << export_utils.export_column_names
            export_utils.all_records.each do |record|
              csv << export_utils.prepare_row(record)
            end
          end
          csv_string
        end

        def prepare_export_column_names
          self.export_column_names = klass.import_export_columns
          if self.local_options && self.local_options.has_key?(:export_columns)
            self.export_column_names = self.local_options[:export_columns]
          end

          if self.export_column_names.blank?
            raise "Please define export_column_names property"
          end

          self.export_column_names << "published_at"
          self.export_column_names << "updated_at"
          self.export_column_names
        end

        def prepare_row(record)
          row = []
          self.export_column_names.each do |column|
            row << record.send(column)
          end
          row
        end
      end

      class ImportUtils
        attr_accessor :file_path, :local_options, :klass, :csv_table
        attr_accessor :import_columns, :records, :feedback, :all_valid
        attr_accessor :import_column_names, :wysiwyg_columns_names

        def initialize(file_path , local_options = {}, klass, csv_table )
          self.file_path = file_path
          self.local_options = local_options
          self.klass = klass
          self.csv_table = csv_table
          self.records = []
          self.feedback = []
          self.all_valid = true #assume all records are valid.
        end

        def self.import(file_path , local_options = {}, klass, csv_table)
          import_utils = ImportUtils.new(file_path, local_options, klass, csv_table)
          import_utils.prepare_import_columns

          csv_table.each_with_index do |row , index |
            if index > 0 # ignore first row because its meta data row
              import_utils.import_row(row)
            end # if csv row index > 0

          end #loop
          import_utils.assign_wysiwyg_columns
          import_utils.all_valid ? true : import_utils.feedback
        end

        # csv_table is two dimentional array
        # col_name is a string.
        # if structure is proper and column name found it returns column index from 0 to n-1
        # otherwise nil
        def find_column_position(col_name)
          if csv_table.instance_of?(Array) && csv_table.count > 0 && csv_table.first.count > 0
            csv_table.first.each_with_index do |table_col , index|
              return index if table_col.to_s.upcase == col_name.to_s.upcase
            end
          end
          nil
        end

        def prepare_import_columns
          _prepare_import_column_names
          _prepare_wysiwyg_column_names

          self.import_columns = {}

          self.import_column_names.each do |key|
            self.import_columns[key] = find_column_position(key)
          end
        end

        def _prepare_import_column_names
          self.import_column_names = klass.import_export_columns
          if local_options && local_options.has_key?(:import_columns)
            self.import_column_names = local_options[:import_columns]
          end
          if import_column_names.blank?
            raise "Please define import_export_columns property"
          end
        end

        def _prepare_wysiwyg_column_names
          self.wysiwyg_columns_names = klass.wysiwyg_columns
          if local_options && local_options.has_key?(:wysiwyg_columns)
            self.wysiwyg_columns_names = local_options[:wysiwyg_columns]
          end
        end

        def import_row(row)
          record_info = prepare_record_info(row)
          record = find_or_initialize_record(record_info)

          self.records << record
          if record.valid?
            self.feedback << true
          else
            feedback << record.errors
            self.all_valid = false
          end
        end
        def prepare_record_info(row)
          record_info = {}
          self.import_columns.each do |key , val|
            if !val.blank? && val >= 0
              record_info[key] = row[val]
              record_info[key] = record_info[key].force_encoding("UTF-8") if row[val].kind_of?(String)
            end
          end
          record_info
        end

        def find_or_initialize_record(record_info)
          if local_options[:unique_key]
            record = klass.where(local_options[:unique_key] => record_info[local_options[:unique_key].to_s]).first
          end

          if record.blank?
            record = new_record(record_info)
          end

          record_info.each do |field,val|
            record.send("#{field}=",val)
          end
          record
        end

        def new_record(record_info)
          if klass.respond_to?(:localized?) && klass.localized?
            klass.new_with_localization
          else
            klass.new
          end
        end

        def assign_wysiwyg_columns
          if self.all_valid
            records.each do |record|
              unless self.wysiwyg_columns_names.blank?
                self.wysiwyg_columns_names.each do |c|
                  record.send("#{c}=",helper.simple_format(record.send(c)))
                end
              end
              record.save
            end
          end
        end

      end #ImportUtils

    end #ImportExportCSV
  end
end

