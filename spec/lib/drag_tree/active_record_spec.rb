# encoding: utf-8

require 'spec_helper'

module Gluttonberg
  module DragTree
    describe ActiveRecord do

      before(:each) do
        @locale = Gluttonberg::Locale.generate_default_locale
        Gluttonberg::Setting.generate_common_settings
      end

      after(:each) do
        clean_all_data
      end

      it "is_drag_tree should set all variables right " do
        Page.behaves_as_a_flat_drag_tree.should == false
        Page.drag_tree_scope_column.should == :parent_id
        Page.behaves_as_a_drag_tree.should == true
        @page = Page.new :name => 'first name', :description_name => 'generic_page'
        @page.respond_to?(:parent).should == true
        @page.respond_to?(:children).should == true
      end

      it "find_by_sorted_ids (unique and right order" do
        Page.count.should == 0
        page1 = Page.create :name => 'Page1', :description_name => 'generic_page'
        page2 = Page.create :name => 'Page2', :description_name => 'generic_page'
        page3 = Page.create :name => 'Page3', :description_name => 'generic_page'
        page4 = Page.create :name => 'Page4', :description_name => 'generic_page'
        page5 = Page.create :name => 'Page5', :description_name => 'generic_page'

        found_pages = Page.find_by_sorted_ids([page3.id, page4.id, page2.id, page1.id, page5.id, page2.id])
        found_pages.length.should == 5
        found_pages[0].id.should == page3.id
        found_pages[1].id.should == page4.id
        found_pages[2].id.should == page2.id
        found_pages[3].id.should == page1.id
        found_pages[4].id.should == page5.id
      end

      it "repair tree/list" do
        Page.count.should == 0
        page1 = Page.create :name => 'Page1 repair', :description_name => 'generic_page'
        page2 = Page.create :name => 'Page2 repair', :description_name => 'generic_page', :parent_id => page1.id
        page3 = Page.create :name => 'Page3 repair', :description_name => 'generic_page'
        page4 = Page.create :name => 'Page4 repair', :description_name => 'generic_page', :parent_id => page2.id
        page5 = Page.create :name => 'Page5 repair', :description_name => 'generic_page', :parent_id => page1.id

        page1.position.should == 0
        page2.position.should == 0
        page3.position.should == 1
        page4.position.should == 0
        page5.position.should == 1

        page1.update_attributes(:position => 4)
        page2.update_attributes(:position => 4)
        page3.update_attributes(:position => 4)
        page4.update_attributes(:position => 4)
        page5.update_attributes(:position => 4)

        page1.position.should == 4
        page2.position.should == 4
        page3.position.should == 4
        page4.position.should == 4
        page5.position.should == 4

        Page.repair_drag_tree
        page1.reload
        page2.reload
        page3.reload
        page4.reload
        page5.reload

        page1.position.should == 0
        page2.position.should == 0
        page3.position.should == 1
        page4.position.should == 0
        page5.position.should == 1

      end
    end
  end
end