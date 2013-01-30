module Gluttonberg
  module Public
    class CommentsController <  Gluttonberg::Public::BaseController

      def create
        @blog = Gluttonberg::Blog.first(:conditions => {:slug => params[:blog_id]})
        @article = Gluttonberg::Article.first(:conditions => {:slug => params[:article_id], :blog_id => @blog.id})
        @comment = @article.comments.new(params[:comment])
        @comment.blog_slug = params[:blog_id]
        @comment.author_id = current_member.id if current_member
        if @comment.save
          if Setting.get_setting("comment_notification") == "Yes" || @blog.moderation_required == true
            User.all_super_admin_and_admins.each do |user|
              Notifier.comment_notification_for_admin(user , @article , @comment).deliver
            end
          end

          @subscription = CommentSubscription.find(:first , :conditions => {:article_id => @article.id , :author_email => @comment.writer_email })
          if @comment.subscribe_to_comments == "1" && @subscription.blank?
            @subscription = CommentSubscription.create( {:article_id => @article.id , :author_email => @comment.writer_email , :author_name => @comment.writer_name } )
          elsif (@comment.subscribe_to_comments.blank? || @comment.subscribe_to_comments == "0")  && !@subscription.blank?
            #unsubscribe
            @subscription.destroy
          end
        else

        end
        if Gluttonberg.localized?
          redirect_to blog_article_path(current_localization_slug , @blog.slug, @article.slug)
        else
          redirect_to blog_article_path(:blog_id =>  @blog.slug, :id => @article.slug)
        end
      end

      private
        def current_localization_slug
           if @locale
             @locale.slug
           else
             nil
           end
        end
    end

  end
end