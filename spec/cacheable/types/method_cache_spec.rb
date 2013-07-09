require 'spec_helper'

describe Cacheable do
  let(:cache) { Rails.cache }
  let(:user)  { User.create(:login => 'flyerhzm') }

  before :all do
    @post1 = user.posts.create(:title => 'post1')
    @post2 = user.posts.create(:title => 'post2')
  end

  before :each do
    cache.clear
    user.reload
  end

  context "with_method" do
    it "should not cache User.last_post" do
      Rails.cache.read("users/#{user.id}/method/last_post").should be_nil
    end

    it "should cache User#last_post" do
      user.cached_last_post.should == user.last_post
      Rails.cache.read("users/#{user.id}/method/last_post").should == user.last_post
    end

    it "should cache User#last_post multiple times" do
      user.cached_last_post
      user.cached_last_post.should == user.last_post
    end
  end

end