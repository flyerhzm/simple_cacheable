require 'spec_helper'

describe Cacheable do
  let(:cache) { Rails.cache }

  before :all do
    @user       = User.create(:login => 'flyerhzm')
    @descendant = Descendant.create(:login => "scotterc")
    @post1      = @user.posts.create(:title => 'post1')
    @post2      = @user.posts.create(:title => 'post2')
    @post3      = @descendant.posts.create(:title => 'post3')
  end

  before :each do
    cache.clear
    @user.reload
  end

  it "should not cache User.last_post" do
    Rails.cache.read("users/#{@user.id}/method/last_post").should be_nil
  end

  it "should cache User#last_post" do
    @user.cached_last_post.should == @user.last_post
    Rails.cache.read("users/#{@user.id}/method/last_post").should == @user.last_post
  end

  it "should cache User#last_post multiple times" do
    @user.cached_last_post
    @user.cached_last_post.should == @user.last_post
  end

  context "descendant should inherit methods" do
    it "should not cache Descendant.last_post" do
      Rails.cache.read("descendants/#{@descendant.id}/method/last_post").should be_nil
    end

    it "should cache Descendant#last_post" do
      @descendant.cached_last_post.should == @descendant.last_post
      Rails.cache.read("descendants/#{@descendant.id}/method/last_post").should == @descendant.last_post
    end

    it "should cache Descendant#last_post multiple times" do
      @descendant.cached_last_post
      @descendant.cached_last_post.should == @descendant.last_post
    end

    context "as well as new methods" do
      it "should not cache Descendant.name" do
        Rails.cache.read("descendants/#{@descendant.id}/method/name").should be_nil
      end

      it "should cache Descendant#name" do
        @descendant.cached_name.should == @descendant.name
        Rails.cache.read("descendants/#{@descendant.id}/method/name").should == @descendant.name
      end

      it "should cache Descendant#name multiple times" do
        @descendant.cached_name
        @descendant.cached_name.should == @descendant.name
      end
    end
  end

  describe "memoization" do
    before :each do
      @user.instance_variable_set("@cached_last_post", nil)
      @user.expire_model_cache
    end

    it "memoizes cache calls" do
      @user.instance_variable_get("@cached_last_post").should be_nil
      @user.cached_last_post.should == @user.last_post
      @user.instance_variable_get("@cached_last_post").should == @user.last_post
    end

    it "hits the cache only once" do
      Rails.cache.expects(:fetch).returns(@user.last_post).once
      @user.cached_last_post.should == @user.last_post
      @user.cached_last_post.should == @user.last_post
    end

    describe "bad iv names stripped" do
      it "should deal with queries" do
        @user.instance_variable_get("@cached_bad_iv_name_bang").should be_nil
        @user.cached_bad_iv_name!.should == 42
        @user.instance_variable_get("@cached_bad_iv_name_bang").should == 42
      end

      it "should deal with bangs" do
        @user.instance_variable_get("@cached_bad_iv_name_query").should be_nil
        @user.cached_bad_iv_name?.should == 44
        @user.instance_variable_get("@cached_bad_iv_name_query").should == 44
      end
    end
  end

end