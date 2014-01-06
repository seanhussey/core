module Gluttonberg
  module Membership
    module Import
      extend ActiveSupport::Concern

      module ClassMethods
        ###############################
        # takes complete path to csv file.
        # and returns successfull_users , failed_users and updated_users arrays that contains user objects
        # if user exist with given email then update its information
        # otherwise create a new user for it
        # returns [successfull_users , failed_users , updated_users , ]
        # if csv format is incorrect then it will return a string "CSV file format is invalid"
        def importCSV(file_path , invite , group_ids )
          begin
            require 'csv'
            csv_table = CSV.read(file_path)
          rescue => e
            return "Please provide a valid CSV file with correct column names."
          end

          known_columns = PrivateMethods.find_known_columns(csv_table)
          other_columns = PrivateMethods.find_other_columns(csv_table)

          successfull_users = []
          failed_users = []
          updated_users = []

          if PrivateMethods.known_columns_valid?(known_columns)
            csv_table.each_with_index do |row , index |
              if index > 0 # ignore first row because its meta data row
                user_info = PrivateMethods.read_data_row(row, known_columns, other_columns)

                #attach user to an group if its valid
                PrivateMethods.attach_user_to_group(user_info, row, known_columns, other_columns, group_ids)

                user = where(:email => row[known_columns[:email]]).first
                if user.blank?
                  PrivateMethods.create_member(user_info, invite, row, successfull_users , failed_users , updated_users)
                else
                  PrivateMethods.update_member(user, user_info, successfull_users , failed_users , updated_users)
                end
              end # if csv row index > 0
            end #loop
          else
            return "Please provide a valid CSV file with correct column names"
          end #if
          [successfull_users , failed_users , updated_users ]
        end

        def contains_user?(user , list)
          list.each do |record|
            return true if record.id == user.id || record.email == user.email
          end
          false
        end

      end #ClassMethods

      module PrivateMethods

        # csv_table is two dimentional array
        # col_name is a string.
        # if structure is proper and column name found it returns column index from 0 to n-1
        # otherwise nil
        def self.find_column_position(csv_table  , col_name)
          if csv_table.instance_of?(Array) && csv_table.count > 0 && csv_table.first.count > 0
            csv_table.first.each_with_index do |table_col , index|
              return index if table_col.to_s.upcase == col_name.to_s.upcase
            end
          end
          nil
        end

        def self.find_known_columns(csv_table)
          known_columns = {}
          known_columns[:first_name]  = find_column_position(csv_table , Rails.configuration.member_csv_metadata[:first_name] )
          known_columns[:last_name]   = find_column_position(csv_table ,  Rails.configuration.member_csv_metadata[:last_name]  )
          known_columns[:email]       = find_column_position(csv_table , Rails.configuration.member_csv_metadata[:email] )
          known_columns[:groups]      = find_column_position(csv_table , Rails.configuration.member_csv_metadata[:groups] )
          known_columns
        end

        def self.find_other_columns(csv_table)
          other_columns = {}
          Rails.configuration.member_csv_metadata.each do |key , val|
            if ![:first_name, :last_name , :email, :groups].include?(key)
              other_columns[key] = find_column_position(csv_table , val )
            end
          end
          other_columns
        end

        def self.read_data_row(row, known_columns, other_columns)
          user_info = {
            :group_ids => []
          }
          user_info[:first_name] = row[known_columns[:first_name]] unless Rails.configuration.member_csv_metadata[:first_name].blank? 
          user_info[:last_name] = row[known_columns[:last_name]]  unless Rails.configuration.member_csv_metadata[:last_name].blank?
          user_info[:email] = row[known_columns[:email]]  unless Rails.configuration.member_csv_metadata[:email].blank?

          other_columns.each do |key , val|
            if !val.blank? && val >= 0
              if row[val].blank? || !user_info[key].kind_of?(String)
                user_info[key] = row[val]
              else
                user_info[key] = row[val].force_encoding("UTF-8")
              end
            end
          end
          user_info
        end

        def self.known_columns_valid?(known_columns)
          known_columns[:first_name] && known_columns[:email]
        end

        def self.attach_user_to_group(user_info, row, known_columns, other_columns, group_ids)
          unless known_columns[:groups].blank? || row[known_columns[:groups]].blank?
            group_names = row[known_columns[:groups]].split(";")
            temp_group_ids = []
            group_names.each do |group_name|
              group = Gluttonberg::Group.where(:name => group_name.strip).first
              temp_group_ids << group.id unless group.blank?
            end
            user_info[:group_ids] = temp_group_ids
          end

          unless group_ids.blank?
            if user_info[:group_ids].blank?
              user_info[:group_ids] = group_ids
            else
              user_info[:group_ids] << group_ids
            end
          end
          user_info
        end #attr_user_to_group

        def self.prepare_user_record(user_info, row)
          # generate random password
          temp_password = Gluttonberg::Member.generateRandomString
          password_hash = {
            :password => temp_password ,
            :password_confirmation => temp_password
          }

          # make user object
          Gluttonberg::Member.new(user_info.merge(password_hash))
        end

        def self.create_member(user_info, invite, row, successfull_users , failed_users , updated_users)
          user = PrivateMethods.prepare_user_record(user_info, row)
          #if its valid then save it send an email and also add it to successfull_users array
          if user.valid?
            user.save
            if invite == "1"
              # we will regenerate password and send it member
              MemberNotifier.delay.welcome(user)
            end
            successfull_users << user
          else # if failed then add it to failed list
            failed_users << user
          end
        end
        
        def self.update_member(user, user_info, successfull_users , failed_users , updated_users)
          if !Gluttonberg::Member.contains_user?(user , successfull_users) and !Gluttonberg::Member.contains_user?(user , updated_users)
            if user.update_attributes(user_info)
              updated_users << user
            else
              failed_users << user
            end
          end
        end

      end #PrivateMethods
    end #Import
  end
end