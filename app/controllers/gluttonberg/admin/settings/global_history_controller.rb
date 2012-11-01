module Gluttonberg
  module Admin
    module Settings  
          class GlobalHistoryController < Gluttonberg::Admin::BaseController
            def index
              @feeds = Feed.order("created_at DESC").paginate(:page => params[:page] , :per_page =>Gluttonberg::Setting.get_setting("number_of_per_page_items"))
            end
          end
      end    
  end
end
