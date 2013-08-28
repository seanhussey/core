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
          else
            self.make_flat_drag_tree
          end
        end

        def repair_list(list)
          unless list.blank?
            list.each_with_index do |sibling , index|
              sibling.position = index
              sibling.save
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
          sorted_elements
        end

      end #module ClassMethods

      module ModelHelpersClassMethods
        extend ActiveSupport::Concern

        included do
          cattr_accessor :is_flat_drag_tree
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
            if behaves_as_a_flat_drag_tree
              if list_options[:scope].blank?
                repair_list(self.all)
              else
                unique_scope_ids = self.select(list_options[:scope]).distinct
                unique_scope_ids.each do |scope_id|
                  items = self.where(list_options[:scope] => scope_id).all
                  repair_list(items)
                end
              end
            end
            # todo: add support for non flat trees
          end
          def all_sorted(query={})
            where(query).order("position asc")
          end
        end #ClassMethods
      end #ModelHelpersClassMethods

    end # ActiveRecord

  end #DragTree
end  #Gluttonberg