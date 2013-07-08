module Gluttonberg
  module Membership
    module Import
      def self.included(klass)
        klass.class_eval do
          extend ClassMethods
        end
      end

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
          first_name_column_num =   self.find_column_position(csv_table , Rails.configuration.member_csv_metadata[:first_name] )
          last_name_column_num =   self.find_column_position(csv_table ,  Rails.configuration.member_csv_metadata[:last_name]  )
          email_column_num =   self.find_column_position(csv_table , Rails.configuration.member_csv_metadata[:email] )
          groups_column_num =   self.find_column_position(csv_table , Rails.configuration.member_csv_metadata[:groups] )
          other_columns = {}

          Rails.configuration.member_csv_metadata.each do |key , val|
            if ![:first_name, :last_name , :email, :groups].include?(key)
              other_columns[key] = self.find_column_position(csv_table , val )
            end
          end

          successfull_users = []
          failed_users = []
          updated_users = []


          if first_name_column_num && last_name_column_num  && email_column_num
            csv_table.each_with_index do |row , index |
                if index > 0 # ignore first row because its meta data row
                  #user information hash
                  user_info = {
                    :first_name => row[first_name_column_num] ,
                    :last_name => row[last_name_column_num] ,
                    :email => row[email_column_num],
                    :group_ids => []
                  }
                  other_columns.each do |key , val|
                    if !val.blank? && val >= 0
                      if row[val].blank? || !user_info[key].kind_of?(String)
                        user_info[key] = row[val]
                      else
                        user_info[key] = row[val].force_encoding("UTF-8")
                      end
                    end
                  end

                  #attach user to an group if its valid
                  unless groups_column_num.blank? || row[groups_column_num].blank?
                    group_names = row[groups_column_num].split(";")
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

                  user = self.where(:email => row[email_column_num]).first
                  if user.blank?
                    # generate random password
                    temp_password = self.generateRandomString
                    password_hash = {
                      :password => temp_password ,
                      :password_confirmation => temp_password
                    }

                    # make user object
                    user = self.new(user_info.merge(password_hash))

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
                  else
                    if  !self.contains_user?(user , successfull_users) and !self.contains_user?(user , updated_users)
                      if user.update_attributes(user_info)
                        updated_users << user
                      else
                        failed_users << user
                      end
                    end
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

        # csv_table is two dimentional array
        # col_name is a string.
        # if structure is proper and column name found it returns column index from 0 to n-1
        # otherwise nil
        def find_column_position(csv_table  , col_name)
          if csv_table.instance_of?(Array) && csv_table.count > 0 && csv_table.first.count > 0
            csv_table.first.each_with_index do |table_col , index|
              return index if table_col.to_s.upcase == col_name.to_s.upcase
            end
          end
          nil
        end
      end
    end
  end
end