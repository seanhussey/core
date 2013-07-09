module Gluttonberg
  module Public
    class ArticlesController <   Gluttonberg::Public::BaseController
      before_filter :is_blog_enabled
      before_filter :find_blog, :only => [:index, :show, :preview]
      
      def index
        @articles = @blog.articles.published
        respond_to do |format|
          format.html
          format.rss { render :layout => false }
        end
      end

      def show
        find_article
        if @blog.previous_slug == params[:blog_id] || @article.previous_slug == params[:id]
          redirect_to blog_article_path(:blog_id => @blog.slug , :id => params[:id]) , :status => 301
          return
        end
        @article.load_localization(env['gluttonberg.locale'])
        @comments = @article.comments.where(:approved => true)
        @comment = Comment.new(:subscribe_to_comments => true)
        respond_to do |format|
          format.html
        end
      end

      def tag
        @articles = Article.tagged_with(params[:tag]).includes(:blog).published
        @tags = Gluttonberg::Article.published.tag_counts_on(:tag)
        respond_to do |format|
          format.html
        end
      end

      def unsubscribe
        @subscription = CommentSubscription.where(:reference_hash => params[:reference]).first
        unless @subscription.blank?
          @subscription.destroy
          flash[:notice] = "You are successfully unsubscribe from comments of \"#{@subscription.article.title}\""
          redirect_to blog_article_url(@subscription.article.blog.slug, @subscription.article.slug)
        end
        respond_to do |format|
          format.html
        end
      end

      def preview
        @article = Gluttonberg::Article.where(:slug => params[:article_id], :blog_id => @blog.id).first
        raise ActiveRecord::RecordNotFound.new if @article.blank?
        @article.load_localization(Locale.where(params[:locale_id]).first)
        render :show
      end

      private
        def find_blog
          @blog = Gluttonberg::Blog.published.where(:slug => params[:blog_id]).includes([:articles]).first
          if @blog.blank?
            @blog = Gluttonberg::Blog.published.where(:previous_slug => params[:blog_id]).first
          end
          raise ActiveRecord::RecordNotFound.new if @blog.blank?
        end

        def find_article
          @article = Gluttonberg::Article.published.where(:slug => params[:id], :blog_id => @blog.id).first
          if @article.blank?
            @article = Gluttonberg::Article.published.where(:previous_slug => params[:id], :blog_id => @blog.id).first
          end
          raise ActiveRecord::RecordNotFound.new if @article.blank?
        end

    end
  end
end