require 'spec_helper'

describe Cacheable do
  let(:cache) { Rails.cache }
  let(:user)  { User.create(:login => 'flyerhzm') }

  before :all do
    @post1 = user.posts.create(:title => 'post1')
    user2 = User.create(:login => 'PelegR')
    user2.posts.create(:title => 'post3')
  end

  before :each do
    cache.clear
    user.reload
  end

  context "expire_model_cache" do
    it "should delete with_key cache" do
      User.find_cached(user.id)
      Rails.cache.read("users/#{user.id}").should_not be_nil
      user.expire_model_cache
      Rails.cache.read("users/#{user.id}").should be_nil
    end

    it "should delete with_attribute cache" do
      user = User.find_cached_by_login("flyerhzm")
      Rails.cache.read("users/attribute/login/flyerhzm").should == user
      user.expire_model_cache
      Rails.cache.read("users/attribute/login/flyerhzm").should be_nil
    end

    it "should delete with_method cache" do
      user.cached_last_post
      Rails.cache.read("users/#{user.id}/method/last_post").should_not be_nil
      user.expire_model_cache
      Rails.cache.read("users/#{user.id}/method/last_post").should be_nil
    end

    it "should delete with_class_method cache (default_post)" do
      Post.cached_default_post
      Rails.cache.read("posts/class_method/default_post").should_not be_nil
      @post1.expire_model_cache
      Rails.cache.read("posts/class_method/default_post").should be_nil
    end

    it "should delete with_class_method cache (retrieve_with_user_id)" do
      Post.cached_retrieve_with_user_id(1)
      Rails.cache.read("posts/class_method/retrieve_with_user_id/1").should_not be_nil
      @post1.expire_model_cache
      Rails.cache.read("posts/class_method/retrieve_with_user_id/1").should be_nil
    end

    it "should delete with_class_method cache (retrieve_with_user_id) with different arguments" do
      Post.cached_retrieve_with_user_id(1)
      Post.cached_retrieve_with_user_id(2)
      Rails.cache.read("posts/class_method/retrieve_with_user_id/1").should_not be_nil
      Rails.cache.read("posts/class_method/retrieve_with_user_id/2").should_not be_nil
      @post1.expire_model_cache
      Rails.cache.read("posts/class_method/retrieve_with_user_id/1").should be_nil
      Rails.cache.read("posts/class_method/retrieve_with_user_id/2").should be_nil
    end

    it "should delete with_class_method cache (retrieve_with_both)" do
      Post.cached_retrieve_with_both(1, 1)
      Rails.cache.read("posts/class_method/retrieve_with_both/1+1").should_not be_nil
      @post1.expire_model_cache
      Rails.cache.read("posts/class_method/retrieve_with_both/1+1").should be_nil
    end

    # TODO: should we cache empty arrays?
    it "should delete associations cache" do
      user.cached_images
      Rails.cache.read("users/#{user.id}/association/images").should_not be_nil
      user.expire_model_cache
      Rails.cache.read("users/#{user.id}/association/images").should be_nil
    end

  end

end