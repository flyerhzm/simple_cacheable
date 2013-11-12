require 'spec_helper'

describe Cacheable do
  let(:cache) { Rails.cache }
  let(:user)  { User.create(:login => 'flyerhzm') }

  let(:coder) { lambda do |object| 
                  Cacheable::ModelFetch.send(:coder_from_record, object)
                end
              }

  before :each do
    cache.clear
    user.reload
  end

  it "should not cache key" do
    Rails.cache.read("users/#{user.id}").should be_nil
  end

  it "should cache by User#id" do
    User.find_cached(user.id).should == user
    Rails.cache.read("users/#{user.id}").should == coder.call(user)
  end

  it "should get cached by User#id multiple times" do
    User.find_cached(user.id)
    User.find_cached(user.id).should == user
  end

end