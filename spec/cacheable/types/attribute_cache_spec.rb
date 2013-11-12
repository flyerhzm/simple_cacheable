require 'spec_helper'

describe Cacheable do
  let(:cache) { Rails.cache }
  let(:user)  { User.create(:login => 'flyerhzm') }
  let(:descendant) { Descendant.create(:login => "scotterc")}

  before :all do
    @post1 = user.posts.create(:title => 'post1')
    @post2 = user.posts.create(:title => 'post2')
    @post3 = descendant.posts.create(:title => 'post3')
  end

  before :each do
    cache.clear
    user.reload
  end

  context "with_attribute" do
    it "should not cache User.find_by_login" do
      Rails.cache.read("users/attribute/login/flyerhzm").should be_nil
    end

    it "should cache by User.find_by_login" do
      User.find_cached_by_login("flyerhzm").should == user
      Rails.cache.read("users/attribute/login/flyerhzm").should =={:class => user.class, 'attributes' => user.attributes}
    end

    it "should get cached by User.find_by_login multiple times" do
      User.find_cached_by_login("flyerhzm")
      User.find_cached_by_login("flyerhzm").should == user
    end

    it "should escape whitespace" do
      new_user = User.create(:login => "user space")
      User.find_cached_by_login("user space").should == new_user
    end

    it "should handle fixed numbers" do
      Post.find_cached_by_user_id(user.id).should == @post1
      Rails.cache.read("posts/attribute/user_id/#{user.id}").should == {:class => @post1.class, 'attributes' => @post1.attributes}
    end

    it "should return correct nil values" do
      User.find_cached_by_login("ducksauce").should be_nil
      User.find_cached_by_login("ducksauce").should be_nil
      User.find_cached_all_by_login("ducksauce").should == []
      User.find_cached_all_by_login("ducksauce").should == []
    end

    context "find_all" do
      it "should not cache Post.find_all_by_user_id" do
        Rails.cache.read("posts/attribute/user_id/all/#{user.id}").should be_nil
      end

      it "should cache by Post.find_cached_all_by_user_id" do
        Post.find_cached_all_by_user_id(user.id).should == [@post1, @post2]
        Rails.cache.read("posts/attribute/user_id/all/#{user.id}").should == [{:class => @post1.class, 'attributes' => @post1.attributes},
                                                                              {:class => @post2.class, 'attributes' => @post2.attributes}]
      end

      it "should get cached by Post.find_cached_all_by_user_id multiple times" do
        Post.find_cached_all_by_user_id(user.id)
        Post.find_cached_all_by_user_id(user.id).should == [@post1, @post2]
      end

    end
  end

  context "descendant" do
    it "should not cache Descendant.find_by_login" do
      Rails.cache.read("descendants/attribute/login/scotterc").should be_nil
    end

    it "should cache by Descendant.find_by_login" do
      Descendant.find_cached_by_login("scotterc").should == descendant
      Rails.cache.read("descendants/attribute/login/scotterc").should == {:class => descendant.class, 'attributes' => descendant.attributes }
    end

    it "should get cached by Descendant.find_by_login multiple times" do
      Descendant.find_cached_by_login("scotterc")
      Descendant.find_cached_by_login("scotterc").should == descendant
    end

    it "should escape whitespace" do
      new_descendant = Descendant.create(:login => "descendant space")
      Descendant.find_cached_by_login("descendant space").should == new_descendant
    end

    it "maintains cached methods" do
      Rails.cache.read("descendants/#{descendant.id}/method/name").should be_nil
      descendant.cached_name.should == descendant.name
      Rails.cache.read("descendants/#{descendant.id}/method/name").should == descendant.name
    end
  end

end