require File.dirname(__FILE__) + '/../spec_helper'

describe "heartbeat base package" do
  before(:each) do
    @hb = PoolPartyHeartbeatClass.new
  end
  it "should have the heartbeat package defined" do
    lambda {PoolPartyHeartbeatClass}.should_not raise_error    
  end
  it "should call enable (and setup resources) since there is no block given when it's instantiated" do
    @hb.resources.should_not be_empty
  end
  it "should have no resources when starting with a block (that defines no methods)" do
    @pphc = PoolPartyHeartbeatClass.new do
    end
    @pphc.resources.should be_empty
  end
  it "should have a file resource" do
    @hb.resource(:remotefile).should_not be_empty
  end
  it "should have at least 3 remotefiles" do
    @hb.resource(:remotefile).size.should >= 3
  end
end