class Gluttonberg::Admin::Membership::BaseController < Gluttonberg::Admin::BaseController
  before_filter :is_members_enabled
  
  protected
    # only allow access for members controllers if membership system is enbaled in initializer
    def is_members_enabled 
      if Gluttonberg::Member.enable_members == false
        raise CanCan::AccessDenied
      end  
    end  
    
end  