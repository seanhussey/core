module Gluttonberg
  module Public
    class FlagController <  Gluttonberg::Public::BaseController

      def new
        model = nil
        if params[:flaggable_type].include?("Gluttonberg::")
          model = Gluttonberg.const_get(params[:flaggable_type][13..-1])
        else
          model = Kernel.const_get(params[:flaggable_type])
        end
        @flaggable = model.where(:id => params[:flaggable_id]).first
        respond_to do |format|
          format.html
        end
      end

      def create
        flag = current_user.flags.create params[:flag]
        flash[:notice] = if flag.new_record?
          "You already flagged this content!"
        else # success
          "Content has been flagged!"
        end


        respond_to do |format|# note: you'll need to ensure that this route exists
          format.html {
            url = ""
            begin
              if flag.flaggable.respond_to?(:commentable)
                url = polymorphic_path(flag.flaggable.commentable)
              else
                url = polymorphic_path(flag.flaggable)
              end
              flag.update_attributes(:url => url)
              redirect_to url
            rescue => e
            end
          }
        end
      end

    end
  end
end