require 'spec_helper'

describe Cacheable do
  let(:cache) { Rails.cache }

  before :all do
    @user = User.create(:login => 'flyerhzm')
    @account = @user.create_account
    @post1 = @user.posts.create(:title => 'post1')
    @post2 = @user.posts.create(:title => 'post2')
    @comment1 = @post1.comments.create
    @comment2 = @post1.comments.create
  end

  before :each do
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
    context "belongs_to" do
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

    context "has_many" do
      it "should not cache associations" do
        cache.data["users/#{@user.id}/association/posts"].should be_nil
      end

      it "should cache User#posts" do
        @user.cached_posts.should == [@post1, @post2]
        cache.data["users/#{@user.id}/association/posts"].should == [@post1, @post2]
      end

      it "should cache User#posts multiple times" do
        @user.cached_posts
        @user.cached_posts.should == [@post1, @post2]
      end
    end

    context "has_many with polymorphic" do
      it "should not cache associations" do
        cache.data["posts/#{@post1.id}/association/comments"].should be_nil
      end

      it "should cache Post#comments" do
        @post1.cached_comments.should == [@comment1, @comment2]
        cache.data["posts/#{@post1.id}/association/comments"].should == [@comment1, @comment2]
      end

      it "should cache Post#comments multiple times" do
        @post1.cached_comments
        @post1.cached_comments.should == [@comment1, @comment2]
      end
    end

    context "has_one" do
      it "should not cache associations" do
        cache.data["users/#{@user.id}/association/account"].should be_nil
      end

      it "should cache User#posts" do
        @user.cached_account.should == @account
        cache.data["users/#{@user.id}/association/account"].should == @account
      end

      it "should cache User#posts multiple times" do
        @user.cached_account
        @user.cached_account.should == @account
      end
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

    it "should delete has_many with_association cache" do
      @user.cached_posts
      cache.data["users/#{@user.id}/association/posts"].should_not be_nil
      @post1.save
      cache.data["users/#{@user.id}/association/posts"].should be_nil
    end


    it "should delete has_many with_association cache on destroy" do
      @user.cached_posts
      cache.data["users/#{@user.id}/association/posts"].should_not be_nil
      @post1.destroy
      cache.data["users/#{@user.id}/association/posts"].should be_nil
    end

    it "should delete has_many with polymorphic with_association cache" do
      @post1.cached_comments
      cache.data["posts/#{@post1.id}/association/comments"].should_not be_nil
      @comment1.save
      cache.data["posts/#{@post1.id}/association/comments"].should be_nil
    end

    it "should delete has_many with polymorphic with_association cache on destroy" do
      @post1.cached_comments
      cache.data["posts/#{@post1.id}/association/comments"].should_not be_nil
      @comment1.destroy
      cache.data["posts/#{@post1.id}/association/comments"].should be_nil
    end

    it "should delete has_one with_association cache" do
      @user.cached_account
      cache.data["users/#{@user.id}/association/account"].should_not be_nil
      @account.save
      cache.data["users/#{@user.id}/association/account"].should be_nil
    end

    it "should delete has_one with_association cache on destroy" do
      @user.cached_account
      cache.data["users/#{@user.id}/association/account"].should_not be_nil
      @account.destroy
      cache.data["users/#{@user.id}/association/account"].should be_nil
    end
  end
end
