# encoding: utf-8

module Gluttonberg
  module Admin
    module Content
      class AutoSaveController < Gluttonberg::Admin::BaseController
        def create
          @success = false
          unless params[:model_name].blank? || params[:id].blank?
            if params[:model_name] == "PageLocalization"
              # @page_localization = PageLocalization.find(params[:id])
              # @page_localization.contents.each do |content|
              #   content.updated_at = Time.now
              # end
              # page_attributes = params["gluttonberg_page_localization"].delete(:page)


              # @page_localization.assign_attributes(params["gluttonberg_page_localization"])         
              # @page_localization.create_content_localizations_autosave_version
              
              # @versions = @page_localization.contents.first.versions
              
            elsif params[:model_name] == "ArticleLocalization"
              find_article
              auto_save = AutoSave.where(:auto_save_able_id => @article_localization.id, :auto_save_able_type => @article_localization.class.name).first_or_initialize
              auto_save.data = params[:gluttonberg_article_localization].to_json
              auto_save.save
            else
            end
          end 
          render :layout => false, :text => "OK" 
        end #create

        def destroy
          @success = false
          unless params[:model_name].blank? || params[:id].blank?
            if params[:model_name] == "PageLocalization"
            elsif params[:model_name] == "ArticleLocalization"
              find_article
              auto_save = AutoSave.where(:auto_save_able_id => @article_localization.id, :auto_save_able_type => @article_localization.class.name).first
              auto_save.destroy unless auto_save.blank?
            end
          end
          redirect_to :back
        end

        def retreive_changes
          @success = false
          unless params[:model_name].blank? || params[:id].blank?
            if params[:model_name] == "PageLocalization"
            elsif params[:model_name] == "ArticleLocalization"
              find_article
              auto_save = AutoSave.where(:auto_save_able_id => @article_localization.id, :auto_save_able_type => @article_localization.class.name).first
              unless auto_save.blank?
                puts JSON.parse(auto_save.data).to_param
                render :json => JSON.parse(auto_save.data).to_json
              end
            end
          end
        end

        private 
          def find_article
            if params[:localization_id].blank?
              conditions = { :article_id => params[:id] , :locale_id => Locale.first_default.id}
              @article_localization = ArticleLocalization.where(conditions).first
            else
              @article_localization = ArticleLocalization.where(:id => params[:localization_id]).first
            end
            @article = Article.where(:id => params[:id]).first
          end
      end
    end
  end
end
