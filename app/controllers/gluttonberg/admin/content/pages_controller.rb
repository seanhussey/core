# encoding: utf-8

module Gluttonberg
  module Admin
    module Content
      class PagesController < Gluttonberg::Admin::BaseController
        drag_tree Page , :route_name => :admin_page_move
        before_filter :find_page, :only => [:show, :edit, :delete, :update, :destroy]
        before_filter :authorize_user , :except => [:destroy , :delete]
        before_filter :authorize_user_for_destroy , :only => [:destroy , :delete]
        record_history :@page

        def index
          @pages = Page.includes(:user, :localizations, :collapsed_pages).order('position').all
        end

        def show
        end

        def new
          @page = Page.new(:parent_id => params[:parent_id])
          @page_localization = PageLocalization.new
        end

        def delete
          display_delete_confirmation(
            :title      => "Delete “#{@page.current_localization.name}” page?",
            :url        => admin_page_url(@page),
            :return_url => admin_pages_path ,
            :warning    => "Children of this page will also be deleted."
          )
        end

        def create
          @page = Page.new(params["gluttonberg_page"])
          @page.state = "draft"
          @page.published_at = nil
          @page.user_id = current_user.id
          if @page.save
            @page.create_default_template_file
            flash[:notice] = "The page was successfully created."
            redirect_to edit_admin_page_page_localization_path( :page_id => @page.id, :id => @page.current_localization.id)
          else
            render :new
          end
        end


        def destroy
          generic_destroy(@page, {
            :name => "page",
            :success_path => admin_pages_path,
            :failure_path => admin_pages_path
          })
        end

        def update_home
          @new_home = Page.where(:id => params[:home]).first
          unless @new_home.blank?
            @new_home.update_attributes(:home => true)
          else
            @old_home = Page.where(:home => true).first
            @old_home.update_attributes(:home => false)
          end
          Gluttonberg::Feed.log(current_user,@new_home,@new_home.name , "set as home")
          render :text => "Home page is changed"
        end

        def pages_list_for_tinymce
          @pages = Page.published.count
          @pages = Page.published.where("not(description_name = 'top_level_page')").order('position' )

          @articles_count = 0
          if Gluttonberg.constants.include?(:Blog)
            @articles_count = Gluttonberg::Blog::Article.published.count
            @blogs = Gluttonberg::Blog::Weblog.published.order("name ASC")
          end

          render :layout => false
        end

        def duplicate
          @page = Page.find(params[:id])
          @duplicated_page = @page.duplicate
          @duplicated_page.user_id = current_user.id
          if @duplicated_page
            flash[:notice] = "The page was successfully duplicated."
            redirect_to edit_admin_page_page_localization_path( :page_id => @duplicated_page.id, :id => @duplicated_page.current_localization.id)
          else
            flash[:error] = "There was an error duplicating the page."
            redirect_to admin_pages_path
          end
        end

        def collapse
          @page = Page.find(params[:id])
          collapse = CollapsedPage.where(:page_id => @page.id, :user_id => current_user.id).first
          if collapse.blank?
            CollapsedPage.create(:page_id => @page.id, :user_id => current_user.id)
          end
          render :json => {:status => true}
        end

        def expand
          CollapsedPage.delete_all(:page_id => params[:id], :user_id => current_user.id)
          render :json => {:status => true}
        end

        def collapse_all
          @pages = Page.all
          @pages.each do |page|
            if page.children.count > 0
              collapse = CollapsedPage.where(:page_id => page.id, :user_id => current_user.id).first
              if collapse.blank?
                CollapsedPage.create(:page_id => page.id, :user_id => current_user.id)
              end
            end
          end
          render :json => {:status => true}
        end

        def expand_all
          CollapsedPage.delete_all(:user_id => current_user.id)
          render :json => {:status => true}
        end

        private

        def find_page
          @page = Page.find( params[:id])
          raise ActiveRecord::RecordNotFound unless @page
        end

        def authorize_user
          authorize! :manage, Gluttonberg::Page
        end

        def authorize_user_for_destroy
          authorize! :destroy, Gluttonberg::Page
        end

      end
    end #content
  end #admin
end  #gluttonberg
