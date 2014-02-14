require 'spec_helper'


describe Notifier do

  before(:each) do
    @locale = Gluttonberg::Locale.generate_default_locale
    Gluttonberg::Setting.generate_common_settings
  end

  before(:all) do
    @params = {
      :first_name => "First",
      :email => "valid_user@test.com",
      :password => "password1",
      :password_confirmation => "password1"
    }
    @user = User.new(@params)
    @user.role = "super_admin"
    @user.save
    @user.id.should_not be_nil
  end

  after :all do
    clean_all_data
  end

  it "password_reset_instructions" do
    Gluttonberg::Setting.generate_common_settings
    mail_object = Notifier.password_reset_instructions(@user.id)
    mail_object.to.should eql([@params[:email]])
    mail_object.subject.should eql("Password Reset Instructions")
    mail_object.from.should be_blank
    expect{ mail_object.deliver}.to raise_error(ArgumentError, "An SMTP From address is required to send a message. Set the message smtp_envelope_from, return_path, sender, or from address.")

    set_from_email_setting

    mail_object = Notifier.password_reset_instructions(@user.id)
    mail_object.to.should eql([@params[:email]])
    mail_object.subject.should eql("Password Reset Instructions")
    mail_object.from.should eql(["from@test.com"])
    mail_object.deliver.class.should == Mail::Message

    set_site_title

    mail_object = Notifier.password_reset_instructions(@user.id)
    mail_object.to.should eql([@params[:email]])
    mail_object.subject.should eql("[Gluttonberg Test] Password Reset Instructions")
    mail_object.from.should eql(["from@test.com"])
    message_object = mail_object.deliver
    message_object.class.should == Mail::Message

    @user.deliver_password_reset_instructions!.class.should == Mail::Message

    reset_site_title
    reset_from_email_setting
  end


  private
    def set_from_email_setting
      Gluttonberg::Setting.update_settings({"from_email" => "from@test.com"})
    end

    def reset_from_email_setting
      Gluttonberg::Setting.update_settings({"from_email" => ""})
    end

    def set_site_title
      Gluttonberg::Setting.update_settings({"title" => "Gluttonberg Test"})
    end

    def reset_site_title
      Gluttonberg::Setting.update_settings({"title" => ""})
    end

    def create_member
      member_params = {
        :first_name => "First",
        :email => "valid_user@test.com",
        :password => "password1",
        :password_confirmation => "password1"
      }
      @member = Gluttonberg::Member.create(member_params)
    end
end
