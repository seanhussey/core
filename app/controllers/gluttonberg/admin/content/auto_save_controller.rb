# encoding: utf-8

module Gluttonberg
  module Admin
    module Content
      class AutoSaveController < Gluttonberg::Admin::BaseController
        before_filter :find_auto_save, :except => [:create]
        layout nil
        def create
          auto_save = AutoSave.where(prepare_opts).first_or_initialize
          auto_save.data = params[AutoSave.param_name_for(params[:model_name])].to_json
          status = auto_save.save
          if !params[:version].blank? && !auto_save.auto_save_able.blank?
            date = nil
            content = nil
            if auto_save.auto_save_able.kind_of?(Gluttonberg::PageLocalization)
              content = auto_save.auto_save_able.contents.first
            elsif Gluttonberg::Article && auto_save.auto_save_able.kind_of?(Gluttonberg::ArticleLocalization)
              content = auto_save.auto_save_able
            end
            if !content.blank? && content.version.to_s != params[:version].to_s
              date = auto_save.auto_save_able.created_at
            end
            unless date.blank?
              auto_save.created_at = auto_save.updated_at = date
             auto_save.save
            end
          end
          render( :json => ( status ? "OK" : "Error").to_json )
        end #create

        def destroy
          status = false
          status = @auto_save.destroy unless @auto_save.blank?
          render( :json => (status ? "OK" : "Error").to_json )
        end

        def retreive_changes
          render( :json => (@auto_save.blank? ? {} : JSON.parse(@auto_save.data).to_json ) )
        end

        private
          def prepare_opts
            {:auto_save_able_id => params[:id], :auto_save_able_type => params[:model_name]}
          end

          def find_auto_save
            @auto_save = AutoSave.where(prepare_opts).first
          end
      end
    end
  end
end