module Gluttonberg
  module DragTree
    module ActionController
      extend ActiveSupport::Concern
      
      module ClassMethods
        def drag_tree(model_class, options = {})
          self.send(:include, Gluttonberg::DragTree::ActionController::ControllerHelperClassMethods)
          self.set_drag_tree(model_class, options)
        end

      end # class methods

      module ControllerHelperClassMethods
        extend ActiveSupport::Concern
        included do
          @drag_tree_model_class = nil
          @drag_tree_route_name = nil
        end
        module ClassMethods
          def drag_class
            @drag_tree_model_class
          end

          def set_drag_tree(model_class, options = {})
            @drag_tree_route_name = options[:route_name] if options[:route_name]
            @drag_tree_model_class = model_class
          end

          def drag_tree_route_name
            if @drag_tree_route_name then
              @drag_tree_route_name
            else
              "#{self.controller_name}/move_node".to_sym
            end
          end
        end #ClassMethods

        def move_node
          if params[:element_ids].blank? && params[:nestable_serialized_data].blank?
            render :json => {:success => false}
            return
          end
          if params[:element_ids]
            save_data_for_elements(params)
          else
            nestable_serialized_data = JSON.parse(params[:nestable_serialized_data])
            _update_position_for_pages(self.class.drag_class, nestable_serialized_data, nil)
          end
          render :json => {:success => true}
        end

        def save_data_for_elements(params)
          ids = params[:element_ids].split(",")
          elements = self.class.drag_class.find_by_sorted_ids(ids)
          elements.each_with_index do |element , index|
            element.update_attributes!({:position => index})
          end
        end

        def _update_position_for_pages(klass, pages, parent_id=nil)
          pages.each_with_index do |row, index|
            klass.update(row["id"], :position => index, :parent_id => parent_id)
            unless row["children"].blank?
              _update_position_for_pages(klass, row["children"], row["id"])
            end
          end
        end
      end #ControllerHelperClassMethods

    end
  end #DragTree
end  # Gluttonberg