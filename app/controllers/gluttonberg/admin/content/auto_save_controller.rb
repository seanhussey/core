# encoding: utf-8

module Gluttonberg
  module Admin
    module Content
      class AutoSaveController < Gluttonberg::Admin::BaseController
        before_filter :find_auto_save, :except => [:create]
        def create
          param_name = ActiveModel::Naming.param_key(params[:model_name].constantize).to_sym
          auto_save = AutoSave.where(prepare_opts).first_or_initialize
          auto_save.data = params[param_name].to_json
          render( :json => (auto_save.save ? "OK" : "Error").to_json )
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
