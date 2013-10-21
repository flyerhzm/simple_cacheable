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

  it "should not cache Post.default_post" do
    Rails.cache.read("posts/class_method/default_post").should be_nil
  end

  it "should cache Post.default_post" do
    Post.cached_default_post.should == @post1
    Rails.cache.read("posts/class_method/default_post").should == @post1
  end

  it "should cache Post.default_post multiple times" do
    Post.cached_default_post
    Post.cached_default_post.should == @post1
  end

  it "should cache Post.retrieve_with_user_id" do
    Post.cached_retrieve_with_user_id(1).should == @post1
    Rails.cache.read("posts/class_method/retrieve_with_user_id/1").should == @post1
  end

  it "should cache Post.retrieve_with_both with multiple arguments" do
    Post.cached_retrieve_with_both(1, 1).should be_true
    Rails.cache.read("posts/class_method/retrieve_with_both/1+1").should be_true
  end

end