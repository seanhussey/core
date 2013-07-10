module Gluttonberg
  module Public
    class BlogsController <  Gluttonberg::Public::BaseController
      before_filter :is_blog_enabled

      def index
        @blogs = Gluttonberg::Blog.published.all
        if @blogs.blank?
          redirect_to "/"
        elsif @blogs.length == 1
          if Gluttonberg.localized?
            redirect_to blog_path(current_localization_slug , @blogs.first.slug)
          else
            redirect_to blog_path(:id =>@blogs.first.slug)
          end
        end
      end

      def show
        @blog = Gluttonberg::Blog.published.where(:slug => params[:id]).includes(:articles).first
        return if find_by_previous_path
        raise ActiveRecord::RecordNotFound.new if @blog.blank?
        @articles = @blog.articles.published
        @tags = Gluttonberg::Article.published.tag_counts_on(:tag)
        respond_to do |format|
           format.html
           format.rss { render :layout => false }
        end

      end

      private
        def find_by_previous_path
          if @blog.blank?
            @blog = Gluttonberg::Blog.published.where(:previous_slug => params[:id]).first

            unless @blog.blank?
               redirect_to blog_path(:id => @blog.slug) , :status => 301
               return true
            end
          end
          false
        end

    end
  end
end