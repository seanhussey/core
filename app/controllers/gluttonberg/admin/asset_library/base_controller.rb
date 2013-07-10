module Gluttonberg
  module Admin
    module AssetLibrary
      class BaseController < Gluttonberg::Admin::BaseController
        before_filter :find_categories, :except => [:delete, :destroy]
        before_filter :prepare_to_edit  , :except => [:category , :show , :delete , :create , :update  ]
        before_filter :authorize_user
        before_filter :authorize_user_for_destroy , :except => [:destroy , :delete]

        protected
          def find_categories
            @categories = AssetCategory.all
          end

          def prepare_to_edit
            @collections = AssetCollection.order("name")
          end

          def authorize_user
            authorize! :manage, Gluttonberg::Asset
          end

          def authorize_user_for_destroy
            authorize! :destroy, Gluttonberg::Asset
          end
      end
    end #AssetLibrary
  end
end