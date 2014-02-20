class Gluttonberg::Admin::Membership::BaseController < Gluttonberg::Admin::BaseController
  before_filter :is_members_enabled
  
  protected
    def is_members_enabled 
      if Gluttonberg::Member.enable_members == false
        raise CanCan::AccessDenied
      end  
    end  
    
end  