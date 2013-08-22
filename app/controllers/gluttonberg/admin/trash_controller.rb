module Gluttonberg
  module Admin
    class TrashController < Gluttonberg::Admin::BaseController
      before_filter :find_object, :only => [:destroy, :restore]
      def index
        load_models_in_development
        @all_records = Gluttonberg::Content::Trashable.all_trash        
        @all_records = @all_records.paginate(:page => params[:page], :per_page => Gluttonberg::Setting.get_setting("number_of_per_page_items"))
      end

      def empty
        Gluttonberg::Content::Trashable.empty_trash
        flash[:notice] = "The Trash bin is successfully emptied."
        redirect_to admin_trash_path
      end

      def destroy
        unless @object.blank?
          if @object.destroy
            flash[:notice] = "The #{@type} was successfully deleted."
          else
            flash[:error] = "There was an error deleting the #{@type}."
          end
        end
        redirect_to admin_trash_path
      end

      def restore
        unless @object.blank?
          if @object.recover
            flash[:notice] = "The #{@type} was successfully restored."
          else
            flash[:error] = "There was an error restoring the #{@type}."
          end
        end
        redirect_to admin_trash_path
      end

      private
        def load_models_in_development
          if Rails.env == "development"
            load_models_for(Rails.root)
            Rails.application.railties.engines.each do |r|
              load_models_for(r.root)
            end
          end
        end

        def load_models_for(root)
          Dir.glob("#{root}/app/models/**/*.rb") do |model_path|
            begin
              require model_path
            rescue
              # ignore
            end
          end
        end

        def find_object
          klass = params[:class_name].constantize
          @object = klass.only_deleted.where(:id => params[:id]).first
          unless @object.blank?
            @type = params[:class_name].demodulize
          end
        end
    end
  end
end
