class User < ActiveRecord::Base
  attr_accessible :first_name , :last_name , :email , :password , :password_confirmation , :bio , :image_id

  self.table_name = "gb_users"
  belongs_to :images , :foreign_key => "image_id" , :class_name => "Gluttonberg::Asset"

  validates_presence_of :first_name , :email , :role
  validates_format_of :password, :with => Rails.configuration.password_pattern , :if => :require_password?, :message => Rails.configuration.password_validation_message

  has_many :collapsed_pages, :class_name => "Gluttonberg::CollapsedPage", :dependent => :destroy
  has_many :authorizations, :class_name => "Gluttonberg::Authorization", :dependent => :destroy
  attr_accessible :authorizations, :authorizations_attributes
  accepts_nested_attributes_for :authorizations, :allow_destroy => false

  clean_html [:bio]

  acts_as_authentic do |c|
    c.login_field = "email"
  end

  Gluttonberg::MixinManager.load_mixins(self)

  def full_name
    "#{self.first_name} #{self.last_name}".strip
  end

  def deliver_password_reset_instructions!
    reset_perishable_token!
    Notifier.password_reset_instructions(self.id).deliver
  end

  def ability
    @ability ||= Ability.new(self)
  end

  def super_admin?
    self.role == "super_admin"
  end

  def admin?
    self.role == "admin"
  end

  def editor?
    self.role == "editor"
  end

  def contributor?
    self.role == "contributor"
  end

  def self.user_roles
    @roles ||= (["super_admin" , "admin", 'editor' , "contributor"] << (Rails.configuration.user_roles) ).flatten
  end

  def user_valid_roles(user)
    if user.id == self.id
      []
    else
      roles = (["super_admin" , "admin", 'editor' , "contributor"] << (Rails.configuration.user_roles) ).flatten
      roles.delete("super_admin") unless self.super_admin?
      if !self.super_admin? && !self.admin?
        [self.role]
      else
        roles
      end
    end
  end

  def have_backend_access?
    true
  end

  def self.all_super_admin_and_admins
    self.where(:role => ["super_admin" , "admin"]).all
  end

  def self.all_super_admin_and_admins_editors
    self.where(:role => ["super_admin" , "admin", 'editor']).all
  end

  def self.search_users(query, current_user, get_order)
    users = User.order(get_order)
    unless query.blank?
      users = users.where("first_name LIKE :query OR last_name LIKE :query OR email LIKE :query OR bio LIKE :query ", :query => "%#{query}%")
    end
    if current_user.super_admin?
    elsif current_user.admin?
      users = users.where("role != ?" , "super_admin")
    else
      users = users.where("id = ?" , current_user.id)
    end
    users
  end

  def self.find_user(id, current_user)
    user = User.where(:id => id)
    if current_user.super_admin?
    elsif current_user.admin?
      user = user.where("role != ?" , "super_admin")
    else
      user = user.where(:id => current_user.id)
    end
    user.first
  end

  def authorized?(object)
    auth = nil
    status = case object.class.name.to_s
    when "Gluttonberg::Page"
      auth = self.authorizations.where(:authorizable_type => object.class.name).first
      unless auth.blank? 
        auth.authorizable_id == object.id || object.grand_child_of?(auth.authorizable) 
      else
        false
      end
    when "Gluttonberg::Blog"
      auth = self.authorizations.where(:authorizable_type => object.class.name, :authorizable_id => object.id).first
      unless auth.blank?
        auth.allow == true
      else
        false
      end
    when "String"
      auth = self.authorizations.where(:authorizable_type => object).first
      unless auth.blank?
        auth.allow == true 
      else
        false
      end
    else
      auth = self.authorizations.where(:authorizable_type => object.class.name).first
      unless auth.blank?
        auth.allow == true
      else
        true
      end
    end
    status
  end

  def can_view_page(object)
    if self.contributor?
      if object.class.name == "Gluttonberg::Page"
        auth = self.authorizations.where(:authorizable_type => object.class.name).first
        unless auth.blank? || auth.authorizable.blank?
          object.id == auth.authorizable.id || object.grand_child_of?(auth.authorizable) || object.grand_parent_of?(auth.authorizable)
        else
          false
        end
      else
        false
      end
    else
      true
    end
  end

end