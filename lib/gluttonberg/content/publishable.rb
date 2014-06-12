module Gluttonberg
  module Content
    # A mixin that will add simple publishing functionality to any arbitrary 
    # model. This includes finders for retrieving published records and 
    # instance methods for quickly changing the state.
    module Publishable
      extend ActiveSupport::Concern
      # Add the class and instance methods, declare the property we store the
      # published state in.
      included do
        scope :published, lambda { where("state = 'published'  AND  published_at <= ?", Time.zone.now) }
        scope :archived, lambda { where(:state => "archived") }
        scope :draft, lambda { where( :state => "draft") }
        scope :non_published, lambda { where("state != 'published'") }
        before_validation :set_status 
        before_validation :clean_published_date 
        attr_accessor :_publish_status
        attr_accessible :_publish_status
      end

      # Change the publish state to true and save the record.
      def publish!
        self.publish
        self.save
      end
      
      # Change the publish state to false and save the record.
      def unpublish!
        self.unpublish
        self.save
      end

      # Change the publish state to draft but not save the record
      def publish
        self.state= "published"
        self.published_at = Time.now
      end

      # Change the publish state to draft but not save the record
      def unpublish
        self.state= "draft"
      end
      
      # Change the publish state to true but not save the record.
      def archive
        self.state = "archived"
      end

      # Change the publish state to true and save the record.
      def archive!
        self.archive
        self.save
      end
      
      # Check to see if this record has been published.
      def published?
        self.state == "published" && published_at <= Time.zone.now
      end
      
      # Check to see if this record has been published.
      def archived?
        self.state == "archived"
      end
      
      def draft?
        self.state == "draft" || self.state == "ready" || self.state == "not_ready"
      end
      
      def publishing_status
        temp_status = if draft?
          "Draft"
        else  
          self.state.capitalize unless self.state.blank?
        end
        # TODO support for 'submitted for approval'
        temp_status.html_safe 
      end
      
      def set_status
        if ["draft", "ready", "not_ready"].include?(self.state) || self.state.blank?
          self.state = "draft"
        elsif ["published", "archived"].include?(self.state) 
          self.state = self.state
        else
          #self.state = "draft"
        end
      end

      def clean_published_date
        if self.state != "published"
          self.published_at = nil
        end  
      end
    end # Publishable
  end # Content
end # Gluttonberg
