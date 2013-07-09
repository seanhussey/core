module Gluttonberg
  module Public
    class CommentsController <  Gluttonberg::Public::BaseController
      before_filter :is_blog_enabled

      def create
        find_blog_and_article
        prepare_comment

        if @comment.save
          send_notification
          adjust_subscription
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
          @locale ? @locale.slug : nil
        end

        def send_notification
          if Setting.get_setting("comment_notification") == "Yes" || @blog.moderation_required == true
            User.all_super_admin_and_admins.each do |user|
              Notifier.comment_notification_for_admin(user , @article , @comment).deliver
            end
          end
        end

        def find_blog_and_article
          @blog = Gluttonberg::Blog.where(:slug => params[:blog_id]).first
          @article = Gluttonberg::Article.where(:slug => params[:article_id], :blog_id => @blog.id).first
        end

        def prepare_comment
          @comment = @article.comments.new(params[:comment])
          @comment.blog_slug = params[:blog_id]
          @comment.author_id = current_member.id if current_member
        end

        def adjust_subscription
          @subscription = CommentSubscription.where(:article_id => @article.id , :author_email => @comment.writer_email).first
          if @comment.subscribe_to_comments == "1" && @subscription.blank?
            @subscription = CommentSubscription.create( {:article_id => @article.id , :author_email => @comment.writer_email , :author_name => @comment.writer_name } )
          elsif (@comment.subscribe_to_comments.blank? || @comment.subscribe_to_comments == "0")  && !@subscription.blank?
            #unsubscribe
            @subscription.destroy
          end
        end
    end

  end
end