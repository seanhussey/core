module Gluttonberg
  class Comment < ActiveRecord::Base
    self.table_name = "gb_comments"

    attr_accessible :body , :author_name , :author_email , :author_website  , :subscribe_to_comments , :blog_slug

    belongs_to :commentable, :polymorphic => true
    belongs_to :article
    belongs_to :author, :class_name => "Gluttonberg::Member"

    before_save :init_moderation
    before_validation :spam_detection
    after_save :send_notifications_if_needed

    validates_presence_of :body

    scope :all_approved, :conditions => ["approved = ? AND ( spam = ? OR spam IS NULL)",true , false]
    scope :all_pending, :conditions => ["moderation_required = ? AND ( spam = ? OR spam IS NULL)",true , false]
    scope :all_rejected, :conditions => ["moderation_required = ? AND approved = ? AND ( spam = ? OR spam IS NULL)",false , false , false]
    scope :all_spam, :conditions => { :spam => true }

    attr_accessor :subscribe_to_comments , :blog_slug
    attr_accessible :body , :author_name , :author_email , :author_website , :commentable_id , :commentable_type , :author_id

    can_be_flagged

    clean_html [:body]

    def moderate(params)
      if params == "approve"
        self.moderation_required = false
        self.approved = true
        self.spam = false
        self.save
      elsif params == "disapprove"
        self.moderation_required = false
        self.approved = false
        self.save
      else
        #error
      end
    end

    def self.all_comments_count
      self.count
    end

    def self.approved_comments_count
      self.all_approved.count
    end

    def self.rejected_comments_count
      self.all_rejected.count
    end

    def self.pending_comments_count
      self.all_pending.count
    end

    def self.spam_comments_count
      self.all_spam.count
    end


    def user_id
      self.author_id
    end

    def user_id=(new_id)
      self.author_id=new_id
    end

    # these are helper methods for comment.
    def writer_email
      if self.author_email
        self.author_email
      elsif author
        author.email
      end
    end

    def writer_name
      if self.author_name
        self.author_name
      elsif author
        author.name
      end
    end

    def approved=(val)
      @approve_updated = !self.moderation_required && val && self.notification_sent_at.blank? #just got approved
      write_attribute(:approved, val)
    end

    def self.spam_detection_for_all
      self.all_pending.each do |c|
        c.send("spam_detection")
        c.save(:validate => false)
      end
    end

    protected
      def init_moderation
        if self.commentable.respond_to?(:moderation_required)
          if self.commentable.moderation_required == false
            self.approved = true
            write_attribute(:moderation_required, false)
          end
        end
        true
      end

      def send_notifications_if_needed
        if @approve_updated == true
          @approve_updated = false
          CommentSubscription.notify_subscribers_of(self.commentable , self)
        end
      end

      def spam_detection
        unless self.body.blank?
          dspam = Gluttonberg::Content::Despamilator.new(self.body)
          self.spam = (dspam.score >= 1.0)
          self.spam_score = dspam.score
          unless self.spam
            naughty_word_parser = Gluttonberg::Content::DespamilatorFilter::NaughtyWords.new
            if !self.author_email.blank? && naughty_word_parser.local_parse(self.author_email) >= 1.0
              self.spam = true
            elsif !self.author_name.blank? && naughty_word_parser.local_parse(self.author_name) >= 1.0
              self.spam = true
            elsif !self.author_website.blank? && naughty_word_parser.local_parse(self.author_website) >= 1.0
              self.spam = true
            end
          end
        else
          self.spam = true
          self.spam_score = 1.0
        end
      end

  end
end