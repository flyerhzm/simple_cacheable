require 'spec_helper'

describe Cacheable do
  let(:cache) { Rails.cache }
  let(:coder) { lambda do |object|
                  Cacheable::ModelFetch.send(:coder_from_record, object)
                end
              }

  before :all do
    @user  = User.create(:login => 'flyerhzm')
    @post1 = @user.posts.create(:title => 'post1')
  end


  before :each do
    cache.clear
    @user.reload
  end

  it "should not cache key" do
    Rails.cache.read("users/#{@user.id}").should be_nil
  end

  it "should cache by User#id" do
    User.find_cached(@user.id).should == @user
    Rails.cache.read("users/#{@user.id}").should == coder.call(@user)
  end

  it "should get cached by User#id multiple times" do
    User.find_cached(@user.id)
    User.find_cached(@user.id).should == @user
  end

  describe "it should handle slugs as keys" do
    it "should have a slug" do
      @post1.slug.should == @post1.title
    end

    it "should be accessed by slug" do
      Post.find(@post1.slug).should == @post1
    end

    it "should cache it with id" do
      Rails.cache.read("posts/#{@post1.id}").should == nil
      Post.find_cached(@post1.id)
      Rails.cache.read("posts/#{@post1.id}").should == coder.call(@post1)
    end

    it "should cache it with slug" do
      Rails.cache.read("posts/#{@post1.slug}").should == nil
      Post.find_cached(@post1.slug)
      Rails.cache.read("posts/#{@post1.slug}").should == coder.call(@post1)
    end

    describe "it should expire both" do
      it "should expire it with id" do
        Post.find_cached(@post1.id)
        Rails.cache.read("posts/#{@post1.id}").should == coder.call(@post1)
        @post1.save
        Rails.cache.read("posts/#{@post1.id}").should == nil
      end

      it "should expire it with slug" do
        Post.find_cached(@post1.slug)
        Rails.cache.read("posts/#{@post1.slug}").should == coder.call(@post1)
        @post1.save
        Rails.cache.read("posts/#{@post1.slug}").should == nil
      end
    end
  end

end