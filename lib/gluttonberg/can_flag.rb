# CanFlag
module Gluttonberg
  module CanFlag
    extend ActiveSupport::Concern
    def self.setup
      ::ActiveRecord::Base.send :include, Gluttonberg::CanFlag
    end
      
    included do
      if defined?(::ActiveSupport::Callbacks)
        self.define_callbacks :after_flagged
      end
    end
    

    module ClassMethods
      # Call can_be_flagged from your content model, or from anything
      # you want to flag.
      def can_be_flagged(opts={})
        has_many :flags, :as => :flaggable, :dependent => :destroy
        validates_associated :flags, :message => 'failed to validate'
        include Gluttonberg::CanFlag::CanBeFlaggedMixin
        cattr_accessor :reasons
        self.reasons = opts[:reasons] || [:inappropriate]
        (::Flag.flaggable_models ||= []) << self
      end
      
      # Call can_flag from your user model, or anything that can own a flagging.
      # That's a paddlin!
      # Limitation for now: you should only allow one model to own flags.
      # This is ridiculously easy to make polymorphic, but no ponies yet.
      def can_flag
        # has_many :flaggables, :foreign_key => "user_id"
        # User created these flags
        has_many :flags, :foreign_key => "user_id", :order => "id desc"
        
        # User was responsible for creating this filth
        has_many :flaggings, :foreign_key => "flaggable_user_id", :class_name => "Flag"
        include CanFlagMixin
        
        # Associate the flag back here
        # Flag.belongs_to :user
        # Flag.belongs_to :owner, :foreign_key => flaggable_user_id
        ::Flag.class_eval "belongs_to :#{name.underscore}, :foreign_key => :user_id; 
          belongs_to :owner, :foreign_key => :flaggable_user_id, :class_name => '#{name}'"
      end
    end

    module CanBeFlaggedMixin
      extend ActiveSupport::Concern
      def flagged?
        flags.size > 0
      end
      
      def inappropriate?
        flags.find_all{|f| f.approved == true }.size > 0
      end
        
      # Flag content with a mass-updater; sets the flagging user.
      # article.update_attributes { 'flagged' => current_user.id }
      def flagged=(by_who)
        flags.build :user_id => by_who
      end
    end
    
    
    module CanFlagMixin
      extend ActiveSupport::Concern
      def flagged?(content)
        logger.warn "Looking for flags with #{content.inspect} #{content.class.name}"
        ::Flag.where(:flaggable_type => content.class.name, :flaggable_id => content[:id]).first
      end
      
      def flagged_by?(content, user)
        ::Flag.where(:flaggable_type => content.class.name, :flaggable_id => content[:id], :flaggable_user_id => user.id).first
      end
    end
    
      
  end
end
