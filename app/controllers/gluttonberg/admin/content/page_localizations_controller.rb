module Gluttonberg
  module Admin
    module Content
      class PageLocalizationsController < Gluttonberg::Admin::BaseController
        before_filter :find_localization, :exclude => [:index, :new, :create]
        before_filter :authorize_user

        def edit
          @page = @page_localization.page
          fix_nav_label_and_slug
          @version = params[:version]  unless params[:version].blank?
          prepare_to_edit
        end

        def update
          update_updated_at
          page_attributes = params["gluttonberg_page_localization"].delete(:page)

          if @page_localization.update_attributes(params["gluttonberg_page_localization"]) || !@page_localization.changed?

            @page_localization.page.update_attributes(page_attributes)
            update_publish_state

            flash[:notice] = "The page was successfully updated."
            redirect_to edit_admin_page_page_localization_path( :page_id => params[:page_id], :id =>  @page_localization.id)
          else
            flash[:error] = "Sorry, The page could not be updated."
            prepare_to_edit
            render :edit
          end
        end

        private
          def find_localization
            @page_localization = PageLocalization.where(:id => params[:id]).first
            raise ActiveRecord::RecordNotFound  unless @page_localization
          end

          def authorize_user
            authorize! :manage, Gluttonberg::Page
          end

          def prepare_to_edit
            @pages  = Page.where("id != ? " , @page.id).all
            @descriptions = []
            Gluttonberg::PageDescription.all.each do |name, desc|
              @descriptions << [desc[:description], name]
            end
          end

          def fix_nav_label_and_slug
            @page_localization.navigation_label = @page.navigation_label if @page_localization.navigation_label.blank?
            if(!(Gluttonberg.localized? && @page.localizations &&  @page.localizations.length > 1) )
              @page_localization.slug = @page_localization.page.slug  if @page_localization.slug.blank?
              @page_localization.save!
            end
          end

          def update_updated_at
            # update localization updated_at value so that all contents have same version number.
            @page_localization.contents.each do |content|
              content.updated_at = Time.now
            end
          end

          def update_publish_state
            if params[:commit] && ["Publish", "Update"].include?(params[:commit])
              publish!
            else
              unpublish!
            end
          end

          def publish!
            @page_localization.page.state = "published"
            @page_localization.page.published_at = Time.now
            @page_localization.page.save
            Gluttonberg::Feed.log(current_user,@page_localization.page,"#{@page_localization.page.name} #{localization_detail_for_log}" , "updated and published.")
          end

          def unpublish!
            @page_localization.page.state = "draft"
            @page_localization.page.published_at = nil
            @page_localization.page.save
            Gluttonberg::Feed.log(current_user,@page_localization.page,"#{@page_localization.page.name} #{localization_detail_for_log}" , "saved as draft.")
          end

          def localization_detail_for_log
            localization_detail = ""
            if Gluttonberg.localized?
              localization_detail = "(#{@page_localization.locale.slug})"
            end
          end


      end #class
    end
  end
end
