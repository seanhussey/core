module Gluttonberg
  class Member < ActiveRecord::Base
    self.table_name = "gb_members"

    attr_accessible :first_name , :last_name , :email , :password
    attr_accessible :password_confirmation , :bio , :image , :image_delete , :term_and_conditions, :group_ids, :groups
    attr_accessible :return_url

    has_and_belongs_to_many :groups, :class_name => "Group" , :join_table => "gb_groups_members"
    has_attached_file :image, :styles => { :profile => ["600x600"], :thumb => ["142x95#"] , :thumb_for_backend => ["100x75#"]}

    # Validate content type
    validates_attachment_content_type :image, :content_type => /\Aimage/
    # Validate filename
    validates_attachment_file_name :image, :matches => [/png\Z/, /jpe?g\Z/]

    validates_format_of :password, :with => Rails.configuration.password_pattern , :if => :require_password?, :message => Rails.configuration.password_validation_message
    validates_presence_of :first_name , :email
    validates :first_name, :last_name, :email, :length => { :maximum => 255 }

    before_validation :verify_confirmation_status

    attr_accessor :return_url , :term_and_conditions
    attr_accessor :image_delete

    # Included mixins which are registered by host app for extending functionality
    MixinManager.load_mixins(self)

    include Membership::Import
    include Membership::Export

    clean_html [:bio]

    acts_as_authentic do |c|
      c.session_class = MemberSession
      c.login_field = "email"
      c.crypto_provider = Authlogic::CryptoProviders::Sha512
    end

    def full_name
      "#{self.first_name} #{self.last_name}".strip
    end

    def deliver_password_reset_instructions!(current_localization_slug = "")
      reset_perishable_token!
      MemberNotifier.password_reset_instructions(self.id,current_localization_slug).deliver
    end

    def groups_name(join_str=", ")
      unless groups.blank?
        groups.map{|g| g.name}.join(join_str)
      else
        ""
      end
    end

    def can_login?
      !respond_to?(:can_login) || self.can_login == true
    end

    def self.enable_members
      Rails.configuration.enable_members == true || Rails.configuration.enable_members.kind_of?(Hash)
    end

    def self.does_email_verification_required
      if Rails.configuration.enable_members == true
        true
      elsif Rails.configuration.enable_members.kind_of? Hash
        if Rails.configuration.enable_members.has_key?(:email_verification)
          Rails.configuration.enable_members[:email_verification]
        else
          true
        end
      else
        false
      end
    end

    def self.generateRandomString(length=10)
      RandomStringGenerator.generate(length)
    end

    def self.generate_password_hash
      password = self.generateRandomString
      password_hash = {
          :password => password ,
          :password_confirmation => password
      }
    end

    def assign_groups(group_ids)
      if !group_ids.blank? && group_ids.kind_of?(String)
        self.group_ids = [group_ids]
      else
        self.group_ids = group_ids
      end
    end

    def does_member_have_access_to_the_page?( page)
      self.have_group?(page.groups)
    end

    def have_group?(groups)
      if groups.find_all{|g| self.group_ids.include?(g.id)  }.blank?
        false
      else
        true
      end
    end

    def generate_confirmation_key
      self.confirmation_key = Digest::SHA1.hexdigest(Time.now.to_s + rand(12341234).to_s)[1..24]
    end

    private

      def verify_confirmation_status
        if self.profile_confirmed != true
          if self.class.does_email_verification_required
            self.generate_confirmation_key
          else
            self.profile_confirmed = true
          end
        end
      end

  end
end
