require 'spec_helper'

describe "Cacheable Keys" do

  let(:cache) { Rails.cache }

  before :all do
    user = User.create(:login => 'scotterc')
    user.create_account
    post = user.posts.create
    post.images.create
    post.comments.create
    Image.create
  end

  before :each do
    @user       = User.find_by_login('scotterc')
    @account    = @user.account
    @image      = @user.images.first
    @comment    = Comment.first
    @lone_image = Image.last
  end

  describe ".attribute_cache_key" do
    it "is key for find first by attribute" do
      key = User.attribute_cache_key(:login, "scotterc")
      key.should == "users/attribute/login/scotterc"
    end
  end

  describe ".all_attribute_cache_key" do
    it "is key for find by all" do
      key = User.all_attribute_cache_key(:login, "scotterc")
      key.should == "users/attribute/login/all/scotterc"
    end
  end

  describe ".class_method_cache_key" do
    context "without arguments" do
      it "gives a key" do
        key = User.class_method_cache_key(:default_name, [])
        key.should == "users/class_method/default_name"
      end
    end

    context "with arguments" do
      it "gives a key" do
        key = User.class_method_cache_key(:user_with_id, [1])
        key.should == "users/class_method/user_with_id/1"
      end
    end
  end

  describe ".instance_cache_key" do
    it "key with id param" do
      key = User.instance_cache_key(1)
      key.should == "users/1"
    end

    it "key with username param" do
      key = User.instance_cache_key('scotterc')
      key.should == "users/scotterc"
    end
  end

  describe ".cacheable_table_name" do
    it "base class tableized" do
      User.cacheable_table_name.should == "users"
    end
  end

  describe "#model_cache_keys" do
    it "possible implementations of key lookups" do
      value = @user.model_cache_keys
      value.should == ["users/#{@user.id}", "users/#{@user.to_param}" ]
    end
  end

  describe "#model_cache_key" do
    it "base of instance key" do
      value = @user.model_cache_key
      value.should == "users/#{@user.id}"
    end
  end

  describe "#method_cache_key" do
    it "names the method" do
      value = @user.method_cache_key(:last_post)
      value.should == "users/1/method/last_post"
    end
  end

  describe "#belongs_to_cache_key" do
    it "gets the assoication" do
      value = @account.belongs_to_cache_key(:user)
      value.should == 'users/1'
    end

    describe "polymorphic" do
      it "gets it" do
        value = @image.belongs_to_cache_key(:viewable, true)
        value.should == "posts/1"
      end

      describe "can't qualify" do
        it "returns nil" do
          value = @lone_image.belongs_to_cache_key(:viewable, true)
          value.should be_nil
        end
      end
    end
  end

  describe "#association_cache_key" do
    it "uses model_cache_key and name" do
      value = @user.association_cache_key(:account)
      value.should == "users/1/association/account"
    end

    context "given a polymorphic name" do
      it "should find the type" do
        value = @comment.association_cache_key(:commentable)
        value.should == "comments/1/association/commentable"
      end
    end
  end

  describe "#base_class_or_name" do
    it "finds base class if it exists" do
      @user.base_class_or_name("descendant").should == "users"
    end

    it "tableizes if it's not constantizable" do
      @user.base_class_or_name("foo").should == "foos"
    end
  end

end