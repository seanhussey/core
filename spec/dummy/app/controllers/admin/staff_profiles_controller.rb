module Admin
  class StaffProfilesController < Gluttonberg::Admin::BaseController
    before_filter :authorize_user , :except => [:destroy , :delete]
    before_filter :authorize_user_for_destroy , :only => [:destroy , :delete]
    
    drag_tree StaffProfile , :route_name => :admin_cup5_move
    
    record_history :@staff_profile

    def create
      @staff_profile = StaffProfile.new_with_localization({
        :name => "Abdul"
      })
      @staff_profile.save
      render :text => "OK"
    end

    def update
      @staff_profile = StaffProfile.find(params[:id])
      @staff_profile.assign_attributes(params[:staff_profile])
      @staff_profile.save
      render :text => "OK"
    end

    def destroy
      @staff_profile = StaffProfile.find(params[:id])
      @staff_profile.destroy
      render :text => "OK"
    end

    def duplicate
      @staff_profile = StaffProfile.find(params[:id])
      @cloned_staff_profile = @staff_profile.duplicate!
      @cloned_staff_profile
      render :text => "OK"
    end

    private

      def create_staff
        @staff_profile = StaffProfile.new_with_localization({
          :name => "Abdul"
        })
        @staff_profile.save
      end

      def authorize_user
        authorize! :manage, StaffProfile
      end

      def authorize_user_for_destroy
        authorize! :destroy, StaffProfile
      end

  end
end
