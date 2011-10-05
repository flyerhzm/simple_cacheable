require 'spec_helper'

describe Cacheable do
  let(:cache) { Rails.cache }

  before :all do
    @user = User.create(:login => 'flyerhzm')
    @post1 = @user.posts.create(:title => 'post1')
    @post2 = @user.posts.create(:title => 'post2')
    @comment1 = @post1.comments.create
    @comment2 = @post2.comments.create
  end

  after :each do
    cache.clear
  end

  context "with_key" do
    it "should not cache key" do
      cache.data["users/#{@user.id}"].should be_nil
    end

    it "should cache by User#id" do
      User.find_cached(@user.id).should == @user
      cache.data["users/#{@user.id}"].should == @user
    end

    it "should get cached by User#id multiple times" do
      User.find_cached(@user.id)
      User.find_cached(@user.id).should == @user
    end
  end

  context "with_attribute" do
    it "should not cache User.find_by_login" do
      cache.data["users/attribute/login/flyerhzm"].should be_nil
    end

    it "should cache by User.find_by_login" do
      User.find_cached_by_login("flyerhzm").should == @user
      cache.data["users/attribute/login/flyerhzm"].should == @user
    end

    it "should get cached by User.find_by_login multiple times" do
      User.find_cached_by_login("flyerhzm")
      User.find_cached_by_login("flyerhzm").should == @user
    end
  end

  context "with_method" do
    it "should not cache User.last_post" do
      cache.data["users/#{@user.id}/method/last_post"].should be_nil
    end

    it "should cache User#last_post" do
      @user.cached_last_post.should == @user.last_post
      cache.data["users/#{@user.id}/method/last_post"].should == @user.last_post
    end

    it "should cache User#last_post multiple times" do
      @user.cached_last_post
      @user.cached_last_post.should == @user.last_post
    end
  end

  context "with_association" do
    it "should not cache association" do
      cache.data["users/#{@user.id}"].should be_nil
    end

    it "should cache Post#user" do
      @post1.cached_user.should == @user
      cache.data["users/#{@user.id}"].should == @user
    end

    it "should cache Post#user multiple times" do
      @post1.cached_user
      @post1.cached_user.should == @user
    end

    it "should cache Comment#commentable with polymorphic" do
      cache.data["posts/#{@post1.id}"].should be_nil
      @comment1.cached_commentable.should == @post1
      cache.data["posts/#{@post1.id}"].should == @post1
    end
  end

  context "expire_model_cache" do
    it "should delete with_key cache" do
      user = User.find_cached(@user.id)
      cache.data["users/#{user.id}"].should_not be_nil
      user.expire_model_cache
      cache.data["users/#{user.id}"].should be_nil
    end

    it "should delete with_attribute cache" do
      user = User.find_cached_by_login("flyerhzm")
      cache.data["users/attribute/login/flyerhzm"].should == @user
      @user.expire_model_cache
      cache.data["users/attribute/login/flyerhzm"].should be_nil
    end

    it "should delete with_method cache" do
      @user.cached_last_post
      cache.data["users/#{@user.id}/method/last_post"].should_not be_nil
      @user.expire_model_cache
      cache.data["users/#{@user.id}/method/last_post"].should be_nil
    end
  end
end
