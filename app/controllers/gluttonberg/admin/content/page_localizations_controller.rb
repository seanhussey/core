module Gluttonberg
  module Admin
    module Content
      class PageLocalizationsController < Gluttonberg::Admin::BaseController
        before_filter :find_localization, :exclude => [:index, :new, :create]
        before_filter :authorize_user

        # Edit page localization content (edit page)
        def edit
          fix_nav_label_and_slug
          @version = params[:version]  
          prepare_to_edit
        end

        def update
          update_updated_at
          page_attributes = params["gluttonberg_page_localization"].delete(:page)
          set_page_localization_attributes(page_attributes)
          if @page_localization.update_attributes(params["gluttonberg_page_localization"]) || !@page_localization.changed?
            update_page_attributes(page_attributes)
            redirect_to_edit_page
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
            @page = @page_localization.page
            @page.instance_variable_set(:@current_localization, @page_localization)
          end

          def authorize_user
            authorize! :manage, Gluttonberg::Page
            authorize! :manage_object, @page_localization.page
          end

          def prepare_to_edit
            @pages  = Page.where("id != ? AND parent_id IS NULL" , @page.id).order("position asc").all
          end

          def fix_nav_label_and_slug
            @page_localization.navigation_label = @page.navigation_label if @page_localization.navigation_label.blank?
            if(!(Gluttonberg.localized? && @page.localizations &&  @page.localizations.length > 1) )
              @page_localization.slug = @page_localization.page.slug  if @page_localization.slug.blank?
              @page_localization.save!
            end
          end

          # update localization updated_at value for all contents of a page so that all contents have same version number.
          def update_updated_at
            @page_localization.contents.each do |content|
              content.updated_at = Time.now
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

          def set_page_localization_attributes(page_attributes)
            @page_localization.page.current_user_id = current_user.id
            state = page_attributes.delete(:state)
            published_at = page_attributes.delete(:published_at)
            @page_localization.page.state = state unless state.blank?
            @page_localization.page.published_at = published_at unless published_at.blank?
            @page_localization.page._publish_status = page_attributes[:_publish_status]
          end

          # Page description is changed then update page structure to reflect new page description
          def update_page_attributes(page_attributes)
            old_description_name = @page_localization.page.description_name
            new_description_name = page_attributes[:description_name]

            if(old_description_name != new_description_name)
              PageRepairer.change_page_description(@page_localization.page, old_description_name, new_description_name, page_attributes)
            else
              @page_localization.page.update_attributes(page_attributes)
            end
          end

          def redirect_to_edit_page
            flash[:notice] = "The page was successfully updated."
            redirect_to edit_admin_page_page_localization_path( :page_id => params[:page_id], :id =>  @page_localization.id)+ (@page_localization.reload && @page_localization.versions && @page_localization.versions.latest.version != @page_localization.version ? "?version=#{@page_localization.versions.latest.version}" : "")
          end

      end #class
    end
  end
end
