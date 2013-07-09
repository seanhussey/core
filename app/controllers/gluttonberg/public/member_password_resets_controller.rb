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
          flash[:notice] = "No member was found with that email address"
          redirect_to root_path
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
        if @member.save
          flash[:notice] = "Password successfully updated"
          redirect_to root_path
        else
          render :edit
        end
      end

      private

        def load_member_using_perishable_token
          @member = Member.where(:perishable_token => params[:id]).first
          unless @member
            flash[:notice] = "We're sorry, but we could not locate your account. " +
            "If you are having issues try copying and pasting the URL " +
            "from your email into your browser or restarting the " +
            "reset password process."
            redirect_to root_path
          end
        end

    end
  end
end