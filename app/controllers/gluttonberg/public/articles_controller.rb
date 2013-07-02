module Gluttonberg
  module Public
    class ArticlesController <   Gluttonberg::Public::BaseController
      before_filter :is_blog_enabled

      def index
        @blog = Gluttonberg::Blog.published.where(:slug => params[:blog_id]).includes([:articles]).first
        raise ActiveRecord::RecordNotFound.new if @blog.blank?
        @articles = @blog.articles.published

         respond_to do |format|
           format.html
           format.rss { render :layout => false }
        end
      end

      def show
        @blog = Gluttonberg::Blog.published.where(:slug => params[:blog_id]).first

        if @blog.blank?
          @blog = Gluttonberg::Blog.published.where(:previous_slug => params[:blog_id]).first

          unless @blog.blank?
             redirect_to blog_article_path(:blog_id => @blog.slug , :id => params[:id]) , :status => 301
             return
          end
        end

        raise ActiveRecord::RecordNotFound.new if @blog.blank?
        @article = Gluttonberg::Article.published.where(:slug => params[:id], :blog_id => @blog.id).first
        if @article.blank?
          @article = Gluttonberg::Article.published.where(:previous_slug => params[:id], :blog_id => @blog.id).first
          unless @article.blank?
             redirect_to blog_article_path(:blog_id => @blog.slug , :id => @article.slug) , :status => 301
             return
          end
        end

        raise ActiveRecord::RecordNotFound.new if @article.blank?
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
        @blog = Gluttonberg::Blog.published.where(:slug => params[:blog_id]).first
        raise ActiveRecord::RecordNotFound.new if @blog.blank?
        @article = Gluttonberg::Article.where(:slug => params[:article_id], :blog_id => @blog.id).first
        @article.load_localization(Locale.where(params[:locale_id]).first)
        raise ActiveRecord::RecordNotFound.new if @article.blank?
        render :show
      end

    end
  end
end