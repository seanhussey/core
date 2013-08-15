# encoding: utf-8

require 'spec_helper'

module Gluttonberg
  describe Public do
    before :all do
      
    end

    after :all do
      clean_all_data
    end

    it "basic text Truncate - truncate length smaller than string length" do
      text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
      helper.html_truncate(text, 10).should eql("Lorem ipsum")
    end

    it "basic text Truncate - truncate length larger than string length" do
      text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
      helper.html_truncate(text, 500).should eql(text)
    end

    it "basic thml Truncate - truncate length smaller than string length" do
      html = "<p>Lorem <b>ip</b>sum <input type='text'> <img src='test'/> dolor <br> sit <br/> <br /> amet, consectetur adipiscing elit.</p>"
      helper.html_truncate(html, 22).should eql("<p> Lorem <b> ip </b> sum <input type='text'> <img src='test'/> dolor <br> sit <br/> <br /> amet, </p>")
    end

    it "basic text Truncate - truncate length larger than string length" do
      html = "<p>Lorem <b>ip</b>sum dolor sit amet, consectetur adipiscing elit.</p>"
      helper.html_truncate(html, 500).should eql(html)
    end

    
  end 
end