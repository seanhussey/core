
module Gluttonberg
  module Admin
    module Membership
          class MainController < Gluttonberg::Admin::Membership::BaseController
            def index
              redirect_to admin_membership_members_path
            end
          end
      end
  end
end
