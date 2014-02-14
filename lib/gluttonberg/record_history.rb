
module Gluttonberg
  module RecordHistory
    def self.setup
      ::ActionController::Base.send  :include, Gluttonberg::RecordHistory::ActionController
    end

    module ActionController
      extend ActiveSupport::Concern


      module ClassMethods
        def record_history(object_name, title_field_name="", options = {})
          class << self;
            attr_accessor :object_name, :title_field_name;
          end
          self.object_name = object_name
          self.title_field_name = title_field_name
          self.send(:include, Gluttonberg::RecordHistory::ActionController::ControllerHelperClassMethods)
          after_filter :log_create , :only => [:create]
          after_filter :log_update , :only => [:update]
          after_filter :log_destroy, :only => [:destroy]
        end

      end # class methods

      module ControllerHelperClassMethods
        def log_create
          unless object.blank?
            if object.new_record?
            else
              if object.respond_to?(:user_id) # record creator user id
                object.user_id = current_user.id
                object.save
              end
              Gluttonberg::Feed.log(current_user, object ,object_title , "created")
            end
          end
        end

        def log_update
          unless object.blank?
            if object.errors.blank?
              Gluttonberg::Feed.log(current_user, object ,object_title , "updated")
            end
          end
        end

        def log_destroy
          if object && object.destroyed?()
            Gluttonberg::Feed.log(current_user, object ,object_title , "deleted")
          end
        end

        def object
          unless self.class.object_name.blank?
            self.instance_variable_get(self.class.object_name)
          end
        end



        #this method is used to get title or name for the object
        def object_title
          unless object.blank?
            field_name = ""
            if self.class.title_field_name.blank?
              if object.respond_to?(:name)
                field_name = :name
              elsif object.respond_to?(:title)
                field_name = :title
              elsif object.respond_to?(:title_or_name?)
                field_name = :title_or_name?
              else
                field_name = :id
              end
            else
              field_name = self.class.title_field_name
            end
            unless field_name.blank?
              object.send(field_name)
            end
          end
        end
      end #ControllerHelperClassMethods
    end
  end #RecordHistory
end #Gluttonberg




