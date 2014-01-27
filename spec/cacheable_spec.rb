require 'spec_helper'

describe Cacheable do
  let(:cache) { Rails.cache }

  before :all do
    @user     = User.create(:login => 'flyerhzm')
    @group1   = Group.create(name: "Ruby On Rails")
    @account  = @user.create_account(group: @group1)
    @post1    = @user.posts.create(:title => 'post1')
    @image1   = @post1.images.create
    @comment1 = @post1.comments.create
    @tag1     = @post1.tags.create(title: "Rails")
  end

  before :each do
    @user.reload
  end

  context "Association Expires on Save" do
    it "should delete has_many with_association cache" do
      @user.cached_posts
      Rails.cache.read("users/#{@user.id}/association/posts").should_not be_nil
      @post1.save
      Rails.cache.read("users/#{@user.id}/association/posts").should be_nil
    end

    it "should delete has_many with polymorphic with_association cache" do
      @post1.cached_comments
      Rails.cache.read("posts/#{@post1.id}/association/comments").should_not be_nil
      @comment1.save
      Rails.cache.read("posts/#{@post1.id}/association/comments").should be_nil
    end

    it "should delete has_many through with_association cache" do
      @user.cached_images
      Rails.cache.read("users/#{@user.id}/association/images").should_not be_nil
      @image1.save
      Rails.cache.read("users/#{@user.id}/association/images").should be_nil
    end

    it "should delete has_one with_association cache" do
      @user.cached_account
      Rails.cache.read("users/#{@user.id}/association/account").should_not be_nil
      @account.save
      Rails.cache.read("users/#{@user.id}/association/account").should be_nil
    end

    it "should delete has_and_belongs_to_many with_association cache" do
      @post1.cached_tags
      Rails.cache.read("posts/#{@post1.id}/association/tags").should_not be_nil
      @tag1.save
      Rails.cache.read("posts/#{@post1.id}/association/tags").should be_nil
    end

    it "should delete has_one through belongs_to with_association cache" do
      @group1.save
      Rails.cache.read("users/#{@user.id}/association/group").should be_nil
      @user.cached_group.should == @group1
      Rails.cache.read("users/#{@user.id}/association/group").should == coder(@group1)
    end
  end

  describe "class_attributes" do
    before :each do
      Rails.cache.clear
    end

    describe "cached_key" do
      it "is a boolean for a class" do
        User.cached_key.should be_true
        Account.cached_key.should be_false
      end
    end

    describe "cached_indices" do
      before :each do
        User.cached_indices.values.each(&:clear)
      end

      it "is a hash of attributes for a class" do
        User.cached_indices.should == {:login => Set.new}
        User.find_cached_by_login("flyerhzm")
        User.cached_indices.should == {:login => Set.new(["flyerhzm"])}
      end
    end

    describe "cached_methods" do
      it "is an array of methods" do
        methods = User.cached_methods
        methods.should == [ :last_post, :bad_iv_name!, :bad_iv_name?,
                            :admin?, :hash_with_class_key]
      end

      context "descendant" do
        it "should have cached_methods" do
          methods = Descendant.cached_methods
          methods.should == [:last_post, :bad_iv_name!, :bad_iv_name?,
                             :admin?, :hash_with_class_key, :name]
        end
      end
    end

    describe "cached_class_methods" do
      before :each do
        Post.cached_class_methods.values.each(&:clear)
      end

      it "is an hash of arrays" do
        methods = Post.cached_class_methods
        methods.should == { :retrieve_with_user_id => Set.new,
                            :retrieve_with_both => Set.new,
                            :default_post => Set.new,
                            :where_options_are => Set.new
                          }
        Post.cached_retrieve_with_user_id(1)
        methods = Post.cached_class_methods
        methods.should == { :retrieve_with_user_id => Set.new([[1]]),
                            :retrieve_with_both => Set.new,
                            :default_post => Set.new,
                            :where_options_are => Set.new
                          }
      end
    end

    describe "cached_associations" do
      it "is an array of association names" do
        assocations = User.cached_associations
        assocations.should == {
          :posts   => {:polymorphic => false, :type => :has_many},
          :account => {:polymorphic => false, :type => :has_one},
          :images  => {:polymorphic => false, :type => :has_through},
          :group   => {:polymorphic => false, :type => :has_through}
        }
        assocations = Post.cached_associations
        assocations.should == {
          :user     => {:polymorphic => false, :type => :belongs_to},
          :comments => {:polymorphic => false, :type => :has_many},
          :images   => {:polymorphic => false, :type => :has_many},
          :tags     => {:polymorphic => false, :type => :has_and_belongs_to_many},
          :location => {:polymorphic => false, :type => :belongs_to}
        }
        assocations = Comment.cached_associations
        assocations.should == {
          :commentable => {:polymorphic => true, :type => :belongs_to},
        }
      end
    end
  end
end
