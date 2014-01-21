# encoding: utf-8

require 'spec_helper'

module Gluttonberg
  module DragTree
    describe ActionController do

      before(:each) do
        @locale = Gluttonberg::Locale.generate_default_locale
        Gluttonberg::Setting.generate_common_settings
      end

      after(:each) do
        clean_all_data
      end

      it "drag_tree should set all variables right " do

        class DragTreeTestController < Gluttonberg::Admin::BaseController
          drag_tree Gluttonberg::Page , :route_name => :admin_page_move
        end

        class DragTreeTest2Controller < Gluttonberg::Admin::BaseController
          drag_tree Gluttonberg::Page
        end

        DragTreeTestController.drag_class.should == Gluttonberg::Page
        DragTreeTestController.drag_tree_route_name.should == :admin_page_move
        DragTreeTest2Controller.drag_tree_route_name.should == :"drag_tree_test2/move_node"
      end


      it "_update_position_for_pages" do
        class DragTreeTestController < Gluttonberg::Admin::BaseController
          drag_tree Gluttonberg::Page , :route_name => :admin_page_move
        end

        page1 = Page.create :name => 'Page1', :description_name => 'generic_page'
        page2 = Page.create :name => 'Page2', :description_name => 'generic_page', :parent_id => page1.id
        page3 = Page.create :name => 'Page3', :description_name => 'generic_page'
        page4 = Page.create :name => 'Page4', :description_name => 'generic_page', :parent_id => page2.id
        page5 = Page.create :name => 'Page5', :description_name => 'generic_page', :parent_id => page1.id
        page3_1 = Page.create :name => 'Page3_1', :description_name => 'generic_page'
        page3_2 = Page.create :name => 'Page3_2', :description_name => 'generic_page'
        page3_2_1 = Page.create :name => 'Page3_2_1', :description_name => 'generic_page'

        page1.position.should == 0
        page2.position.should == 0
        page3.position.should == 1
        page4.position.should == 0
        page5.position.should == 1
        page3_1.position.should == 2
        page3_2.position.should == 3
        page3_2_1.position.should == 4

        nestable_serialized_data = [
          {
            "id" => page1.id,
            "children" => [
              {"id" => page5.id},
              {"id" => page4.id, "children"  => [
                {"id" => page2.id}
              ]},
            ]
          },{
            "id" => page3.id, 
            "children" =>
            [
              {"id" => page3_1.id},
              {"id" => page3_2.id, "children" => [{"id" => page3_2_1.id}]}
            ]
          }
        ]

        DragTreeTestController.new._update_position_for_pages(Gluttonberg::Page, nestable_serialized_data)
      
        page1.reload
        page2.reload
        page3.reload
        page4.reload
        page5.reload
        page3_1.reload
        page3_2.reload
        page3_2_1.reload

        page1.position.should == 0

        page5.position.should == 0
        page5.parent_id.should == page1.id

        page4.position.should == 1
        page4.parent_id.should == page1.id

        page2.position.should == 0
        page2.parent_id.should == page4.id
        
        page3.position.should == 1
        page3.parent_id.should == nil
        
        page3_1.position.should == 0
        page3_1.parent_id.should == page3.id

        page3_2.position.should == 1
        page3_2.parent_id.should == page3.id

        page3_2_1.position.should == 0
        page3_2_1.parent_id.should == page3_2.id
      end
      
      it "save_data_for_elements(params)" do
        class DragTreeTestController < Gluttonberg::Admin::BaseController
          drag_tree Gluttonberg::Page , :route_name => :admin_page_move
        end

        page1 = Page.create :name => 'Page1', :description_name => 'generic_page'
        page2 = Page.create :name => 'Page2', :description_name => 'generic_page'
        page3 = Page.create :name => 'Page3', :description_name => 'generic_page'

        # flat ordering testing
        page1.position.should == 0
        page2.position.should == 1
        page3.position.should == 2

        DragTreeTestController.new.save_data_for_elements({:element_ids => "#{page2.id},#{page3.id},#{page1.id}"})

        page1.reload
        page2.reload
        page3.reload

        page1.position.should == 2
        page2.position.should == 0
        page3.position.should == 1
      end
    end
  end
end