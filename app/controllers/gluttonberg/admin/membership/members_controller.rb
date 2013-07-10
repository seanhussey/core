# encoding: utf-8

module Gluttonberg
  module Admin
    module Membership
      class MembersController < Gluttonberg::Admin::Membership::BaseController
        before_filter :find_member, :only => [:delete, :edit, :update, :destroy, :find_member]
        before_filter :authorize_user , :except => [:edit , :update]
        record_history :@member
        include Gluttonberg::Public

        def index
          @members = Member.order(get_order).includes(:groups)
          unless params[:query].blank?
            query = clean_public_query(params[:query])
            command = Gluttonberg.like_or_ilike
            @members = @members.where(["first_name #{command} :query OR last_name #{command} :query OR email #{command} :query OR bio #{command} :query " , :query => "%#{query}%" ])
          end
          @members = @members.paginate(:page => params[:page] , :per_page => Gluttonberg::Setting.get_setting("number_of_per_page_items") )
        end

        def new
          @member = Member.new
          @member.group_ids = [Group.default_group.id] unless Group.default_group.blank?
          @groups = Gluttonberg::Group.all
        end

        def create
          password_hash = Gluttonberg::Member.generate_password_hash

          @member = Member.new(params[:gluttonberg_member].merge(password_hash))
          @member.assign_groups(params[:gluttonberg_member][:group_ids])
          @member.profile_confirmed = true

          if @member.save
            flash[:notice] = "Member account registered and welcome email is also sent to the member"
            MemberNotifier.welcome(@member.id).deliver
            redirect_to admin_membership_members_path
          else
            render :action => :new
          end
        end

        def edit
          @groups = Gluttonberg::Group.all
        end

        def update
          mark_image_delete
          @member.assign_groups(params[:gluttonberg_member][:group_ids])
          @member.assign_attributes(params[:gluttonberg_member])
          if @member.save
            flash[:notice] = "Member account updated!"
            redirect_to  admin_membership_members_path
          else
            flash[:notice] = "Failed to save account changes!"
            render :action => :edit
          end
        end

        def delete
          display_delete_confirmation(
            :title      => "Delete “#{@member.email}” member?",
            :url        => admin_membership_member_path(@member),
            :return_url => admin_membership_members_path
          )
        end

        def destroy
          if @member.destroy
            flash[:notice] = "Member deleted!"
          else
            flash[:error] = "There was an error deleting the member."
          end
          redirect_to admin_membership_members_path
        end

        def export
          csv_data = Member.exportCSV
          send_data csv_data, :type => 'text/csv' , :disposition => 'attachment' , :filename => "All members at #{Time.now.strftime('%Y-%m-%d')}.csv"
        end

        # form for uploading csv for members
        def new_bulk
        end

        # import csv and show report for successfully, failed, updated members
        def create_bulk
          if params[:csv].blank?
            flash[:error] = "Please provide a valid csv file."
            redirect_to :action => new_bulk
          else
            @successfull , @failed , @updated  = Member.importCSV(params[:csv][:file].tempfile.path , params[:invite] , params[:csv][:group_ids])
            if @successfull.kind_of? String
              flash[:error] = @successfull
              redirect_to :action => new_bulk
            end
          end
        end

        def welcome
           MemberNotifier.welcome( @member ).deliver
           flash[:notice] = "Welcome email is successfully sent to the member."
           redirect_to admin_membership_members_path
        end

       private
          def find_member
            @member = Member.where(:id => params[:id]).first
            raise ActiveRecord::RecordNotFound  if @member.blank?
          end

          def authorize_user
            authorize! :manage, Member
          end

          def mark_image_delete
            if params[:gluttonberg_member] && params[:gluttonberg_member]["image_delete"] == "1"
              params[:gluttonberg_member][:image] = nil
            end
          end

      end
    end
  end
end