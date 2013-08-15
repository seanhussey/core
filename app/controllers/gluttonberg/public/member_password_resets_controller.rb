module Gluttonberg
  module Public
    class MemberPasswordResetsController < Gluttonberg::Public::BaseController
      skip_before_filter :require_member
      before_filter :load_member_using_perishable_token, :only => [:edit, :update]

      layout 'public'

      def new
        respond_to do |format|
          format.html
        end
      end

      def create
        @member = Member.where(:email => params[:gluttonberg_member][:email]).first
        if @member
          @member.deliver_password_reset_instructions!(current_localization_slug)
          flash[:notice] = "Instructions to reset your password have been emailed to you. " +
          "Please check your email."
          redirect_to root_path
        else
          flash[:error] = "No member was found with that email address"
          render :new
        end
      end

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        @member.password = params[:gluttonberg_member][:password]
        @member.password_confirmation = params[:gluttonberg_member][:password_confirmation]
        generic_update_reset_password(@member, root_path)
      end

      private

        def load_member_using_perishable_token
          @member = generic_find_using_perishable_token(Member)
        end

    end
  end
end