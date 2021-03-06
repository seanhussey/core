# encoding: utf-8

module Gluttonberg
  module Admin
    module Membership
      class GroupsController < Gluttonberg::Admin::Membership::BaseController
        before_filter :find_group, :only => [:delete, :edit, :update, :destroy]
        before_filter :authorize_user , :except => [:edit , :update]
        drag_tree Group , :route_name => :admin_membership_group_move
        record_history :@group

        def index
          @groups = Group.all
        end

        def new
          @group = Group.new
        end

        def create
          @group = Group.new(params[:gluttonberg_group])
          generic_create(@group, {
            :name => "group",
            :success_path => admin_membership_groups_path
          })
        end

        def edit
        end

        def update
          @group.assign_attributes(params[:gluttonberg_group])
          generic_update(@group, {
            :name => "group",
            :success_path => admin_membership_groups_path
          })
        end

        def delete
          display_delete_confirmation(
            :title      => "Delete “#{@group.name}” group?",
            :url        => admin_membership_group_path(@group),
            :return_url => admin_membership_groups_path
          )
        end

        def destroy
          generic_destroy(@group, {
            :name => "group",
            :success_path => admin_groups_path,
            :failure_path => admin_groups_path
          })
        end

       private
          def find_group
            @group = Group.where(:id => params[:id]).first
            raise ActiveRecord::RecordNotFound  if @group.blank?
          end

          def authorize_user
            authorize! :manage, Group
          end

      end
    end
  end
end