module Gluttonberg
  module Content
    # Mixin which extends functionality of pages model for handling page childrens
    module PageChildren
      extend ActiveSupport::Concern

      module ClassMethods
        def fix_children_count
          self.all.each do |page|
            self.reset_counters(page.id, :children)
          end
        end
      end

      def grand_child_of?(page)
        if self.parent_id.blank? || page.blank?
          false
        else
          self.parent_id == page.id || self.parent.grand_child_of?(page)
        end
      end

      def grand_parent_of?(page)
        page.grand_child_of?(self)
      end

      def number_of_children
        if self.respond_to?(:children_count)
          self.children_count
        else
          self.children.count
        end
      end
    end #PageChildren
  end
end