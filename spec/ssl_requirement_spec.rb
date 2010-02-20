require File.dirname(__FILE__) + '/spec_helper'

describe "SslRequirement" do
  
  it "should not accidently introduce any methods as controller actions" do
    Merb::Controller.callable_actions.should be_empty
  end
  
end

describe "ssl_allowed" do
  it "should allow http connection to allowed action" do
    dispatch_to(Secure, :c, {}, 'HTTPS' => nil).body.should == "c"
  end
  
  it "should allow https connection to allowed action" do
    dispatch_to(Secure, :c, {}, 'HTTPS' => 'on').body.should == "c" 
  end
end

describe "ssl_required" do
  it "should redirect http to https for required actions" do
    controller = dispatch_to(Secure, :a, {}, 'HTTPS' => nil)
    controller.should redirect
    controller.headers['Location'].should match(%r{^https://})
  end
  

  it "should allow https connection to required actions" do
    dispatch_to(Secure, :a, {}, 'HTTPS' => 'on').body.should == "a"
  end
end

describe "non-ssl actions" do
  it "should allow http connection" do
    dispatch_to(Secure, :d, {}, 'HTTPS' => nil).body.should == "d"
  end
  
  it "should redirect https connection to http" do
    controller = dispatch_to(Secure, :d, {}, 'HTTPS' => 'on')
    controller.should redirect
    controller.headers['Location'].should match(%r{^http://})
  end
end


describe "ssl_required behavior taking into account configuration" do
  before(:each) do
    Merb::Config.use do |c|
      c[:ssl_requirement_excluded_environments] = ["test"]
    end
  end

  it "should verify ability to set configuration parameter :ssl_requirement_excluded_environments in test environment" do
    Merb::Config.key?(:ssl_requirement_excluded_environments).should be_true
    Merb::Config[:ssl_requirement_excluded_environments].should == ["test"]
  end
    
      
  it "should not require ssl if the application configuration specifies the test environment as an environment excluded from enforcement" do
    controller = dispatch_to(Secure, :a, {}, 'HTTPS' => nil)
    controller.should_not redirect
  end

  it "should require ssl if the configuration does not specify :ssl_requirement_excluded_environments" do
    Merb::Config.delete(:ssl_requirement_excluded_environments)
    Merb::Config.key?(:ssl_requirement_excluded_environments).should be_false
    controller = dispatch_to(Secure, :a, {}, 'HTTPS' => nil)
    controller.should redirect
    controller.headers['Location'].should match(%r{^https://})
  end
  
  it "should require ssl if the configuration does specify :ssl_requirement_excluded_environments, but provides not initialized value" do
    Merb::Config[:ssl_requirement_excluded_environments] = nil
    controller = dispatch_to(Secure, :a, {}, 'HTTPS' => nil)
    controller.should redirect
    controller.headers['Location'].should match(%r{^https://})
  end
  
  it "should require ssl if the configuration specifies an an environment, in :ssl_requirement_excluded_environments, that does not include 'test'" do
    Merb::Config[:ssl_requirement_excluded_environments] = ["staging", "development"]
    controller = dispatch_to(Secure, :a, {}, 'HTTPS' => nil)
    controller.should redirect
    controller.headers['Location'].should match(%r{^https://})
  end
  
    
    
end
  
