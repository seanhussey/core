module Gluttonberg
  module Admin
    class TrashController < Gluttonberg::Admin::BaseController
      def index
        load_models_in_development

        @all_records = []
        Gluttonberg::Content::Trashable.models.each do |model|
          model = model.constantize
          @all_records << model.only_deleted
        end
        @all_records = @all_records.flatten
        @all_records = @all_records.sort{|x,y| y.deleted_at <=> x.deleted_at}
        @all_records = @all_records.paginate(:page => params[:page], :per_page => Gluttonberg::Setting.get_setting("number_of_per_page_items"))
      end

      def destroy
      end

      def empty
      end

      private
        def load_models_in_development
          if Rails.env == "development"
            load_gb_models
          end
        end

        def load_gb_models
          Dir.glob(File.expand_path("app/models/*.rb", Rails.root)).each do |model_file|
          require model_file
        end
          Dir.glob(File.expand_path("app/models/*.rb", Rails.root)).each do |model_file|
            require model_file
          end
        end

    end
  end
end
