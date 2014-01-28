# encoding: utf-8

module Gluttonberg
  module Admin
    module Content
      class BlogsController < Gluttonberg::Admin::BaseController
        before_filter :is_blog_enabled
        before_filter :find_blog, :only => [:show, :edit, :update, :delete, :destroy]
        before_filter :require_super_admin_user , :except => [:index]
        before_filter :authorize_user , :except => [:destroy , :delete]
        before_filter :authorize_user_for_destroy , :only => [:destroy , :delete]
        record_history :@blog

        def index
          @blogs = Blog.all
          @blogs = @blogs.find_all{|blog| can?(:manage_object, blog) } 
          if @blogs && @blogs.size == 1
            redirect_to admin_blog_articles_path(@blogs.first)
          end
          @blogs = @blogs.paginate(:per_page => Gluttonberg::Setting.get_setting("number_of_per_page_items"), :page => params[:page])
        end

        def show
          if @blog
            redirect_to admin_blog_articles_path(@blog)
          else
            redirect_to admin_blog_path
          end
        end

        def new
          @blog = Blog.new
        end

        def create
          @blog = Blog.new(params[:gluttonberg_blog])
          generic_create(@blog, {
            :name => "blog",
            :success_path => admin_blogs_path
          })
        end

        def edit
          unless params[:version].blank?
            @version = params[:version]
            @blog.revert_to(@version)
          end
        end

        def update
          @blog.assign_attributes(params[:gluttonberg_blog])
          generic_update(@blog, {
            :name => "blog",
            :success_path => admin_blogs_path
          })
        end

        def delete
          display_delete_confirmation(
            :title      => "Delete Blog '#{@blog.name}'?",
            :url        => admin_blog_path(@blog),
            :return_url => admin_blogs_path,
            :warning    => "This will delete all the articles that belong to this blog"
          )
        end

        def destroy
          generic_destroy(@blog, {
            :name => "blog",
            :success_path => admin_blogs_path,
            :failure_path => admin_blogs_path
          })
        end


        protected

          def find_blog
            @blog = Blog.where(:id => params[:id]).first
            authorize! :manage_object, @blog
          end

          def authorize_user
            authorize! :manage, Gluttonberg::Blog
          end

          def authorize_user_for_destroy
            authorize! :destroy, Gluttonberg::Blog
          end

      end
    end
  end
end
