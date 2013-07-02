module Gluttonberg
  module Public
    class BlogsController <  Gluttonberg::Public::BaseController
      before_filter :is_blog_enabled

      def index
        if Gluttonberg::Blog.published.all.size == 0
          redirect_to "/"
        elsif Gluttonberg::Blog.published.all.size == 1
          blog = Gluttonberg::Blog.published.first
          if Gluttonberg.localized?
            redirect_to blog_path(current_localization_slug , blog.slug)
          else
            redirect_to blog_path(:id =>blog.slug)
          end
        else
          @blogs = Gluttonberg::Blog.published.all
        end
      end

      def show
        @blog = Gluttonberg::Blog.published.first(:conditions => {:slug => params[:id]}, :include => [:articles])

        if @blog.blank?
          @blog = Gluttonberg::Blog.published.first(:conditions => {:previous_slug => params[:id]})

          unless @blog.blank?
             redirect_to blog_path(:id => @blog.slug) , :status => 301
             return
          end
        end

        raise ActiveRecord::RecordNotFound.new if @blog.blank?
        @articles = @blog.articles.published
        @tags = Gluttonberg::Article.published.tag_counts_on(:tag)
        respond_to do |format|
           format.html
           format.rss { render :layout => false }
        end

      end

    end
  end
end