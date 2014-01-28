class Ability
  include CanCan::Ability
  def initialize(user)
    user ||= User.new # guest user (not logged in)
    can :manage, :all
    if user.super_admin?
    elsif user.admin?
      restricted_features_for_admin(user)
    elsif user.editor?
      restricted_features_for_editors(user)
    else
      restricted_features_for_contributors(user)
    end
  end
  
  def restricted_features_for_admin(user)
    cannot :manage, Gluttonberg::Locale
    cannot :create_or_destroy, Gluttonberg::Setting
  end

  def restricted_features_for_editors(user)
    restricted_features_for_admin(user)
    cannot :manage, User
    cannot :manage, Gluttonberg::Member
    cannot :manage, Gluttonberg::Setting
  end

  def restricted_features_for_contributors(user)
    restricted_features_for_editors(user)
    cannot :publish, :all
    cannot :destroy, :all do |object|
      if object.respond_to?(:user_id)
        (object.respond_to?(:state) && ["published", "archived"].include?(object.state)) || object.user_id != user.id
      else
        true
      end 
    end

    cannot :edit, Gluttonberg::Asset do |object|
      object.user_id != user.id
    end

    #can :destroy, :all, :state => ["not_ready", "ready"], :user_id => user.id
    cannot :moderate, :all
    cannot :reorder, :all
  end
end