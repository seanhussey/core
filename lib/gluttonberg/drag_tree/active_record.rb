module Gluttonberg
  module DragTree
    module ActiveRecord
      extend ActiveSupport::Concern

      module ClassMethods
        def is_drag_tree(options = {})
          options[:flat] = true unless options.has_key?(:flat)
          self.send(:include, Gluttonberg::DragTree::ActiveRecord::ModelHelpersClassMethods)
          unless options[:flat]
            acts_as_tree options
            self.is_flat_drag_tree = false
          else
            self.make_flat_drag_tree
          end
          self.drag_tree_scope_column = options[:scope] unless options[:scope].blank?
        end

        def repair_list(list)
          unless list.blank?
            list.each_with_index do |sibling , index|
              sibling.update_attributes(:position => index)
            end
          end
        end

        def find_by_sorted_ids(new_sorted_element_ids)
          # find records in unorder list
          elements = self.where(:id => new_sorted_element_ids).all
          # sort it using ruby method
          sorted_elements = []
          new_sorted_element_ids.each do |id|
            id = id.to_i
            sorted_elements << elements.find{ |x| x.id == id }
          end
          sorted_elements.blank? ? sorted_elements : sorted_elements.uniq
        end

      end #module ClassMethods

      module ModelHelpersClassMethods
        extend ActiveSupport::Concern

        included do
          cattr_accessor :is_flat_drag_tree, :drag_tree_scope_column
          before_validation :set_position
        end

        module ClassMethods
          def behaves_as_a_drag_tree
            true
          end

          def make_flat_drag_tree
            self.is_flat_drag_tree = true
          end

          def behaves_as_a_flat_drag_tree
            self.is_flat_drag_tree
          end

          def repair_drag_tree
            if self.drag_tree_scope_column.blank?
              repair_list(self.all_sorted.all)
            else
              unique_scope_ids = self.select(self.drag_tree_scope_column).uniq.all
              unique_scope_ids.each do |scope_id|
                scope_id = scope_id.send(self.drag_tree_scope_column)
                items = self.all_sorted(self.drag_tree_scope_column => scope_id).all
                repair_list(items)
              end
            end
          end
          def all_sorted(query={})
            objs = self.order("position asc")
            objs = objs.where(query) unless query.blank?
            objs
          end
        end #ClassMethods
      end #ModelHelpersClassMethods

      def set_position
        if self.position.blank?
          if self.class.drag_tree_scope_column.blank?
            self.position = self.class.count + 1
          else
            items_count = self.class.where(self.class.drag_tree_scope_column => self.send(self.class.drag_tree_scope_column)).count
            self.position = items_count + (self.new_record? ? 0 : -1)
          end
        end
      end

    end # ActiveRecord

  end #DragTree
end  #Gluttonberg