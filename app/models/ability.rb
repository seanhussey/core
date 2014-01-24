class Ability
  include CanCan::Ability
  def initialize(user)
    user ||= User.new # guest user (not logged in)
    can :manage, :all
    if user.super_admin?
    elsif user.admin?
      restricted_features_for_admin
    elsif user.editor?
      restricted_features_for_editors
    else
      restricted_features_for_contributors
    end
  end
  
  def restricted_features_for_admin
    cannot :manage, Gluttonberg::Locale
    cannot :create_or_destroy, Gluttonberg::Setting
  end

  def restricted_features_for_editors
    restricted_features_for_admin
    cannot :manage, User
    cannot :manage, Gluttonberg::Member
    cannot :manage, Gluttonberg::Setting
  end

  def restricted_features_for_contributors
    restricted_features_for_editors
    cannot :publish, :all
    cannot :destroy, :all
    cannot :moderate, :all
    cannot :reorder, :all
  end
end