require 'spec_helper'

describe Cacheable do
  let(:cache) { Rails.cache }
  let(:user)  { User.create(:login => 'flyerhzm') }

  let(:coder) { lambda do |object| 
                  coder = {:class => object.class}
                  object.encode_with(coder)
                  coder 
                end
              }

  before :all do
    @group1 = Group.create(name: "Ruby On Rails")
    @account = user.create_account(group: @group1)
    @post1 = user.posts.create(:title => 'post1')
    @image1 = @post1.images.create
    @comment1 = @post1.comments.create
    @tag1 = @post1.tags.create(title: "Rails")
  end

  before :each do
    cache.clear
    user.reload
  end

  context "Association Expires on Save" do
    it "should delete has_many with_association cache" do
      user.cached_posts
      Rails.cache.read("users/#{user.id}/association/posts").should_not be_nil
      @post1.save
      Rails.cache.read("users/#{user.id}/association/posts").should be_nil
    end

    it "should delete has_many with polymorphic with_association cache" do
      @post1.cached_comments
      Rails.cache.read("posts/#{@post1.id}/association/comments").should_not be_nil
      @comment1.save
      Rails.cache.read("posts/#{@post1.id}/association/comments").should be_nil
    end

    it "should delete has_many through with_association cache" do
      user.cached_images
      Rails.cache.read("users/#{user.id}/association/images").should_not be_nil
      @image1.save
      Rails.cache.read("users/#{user.id}/association/images").should be_nil
    end

    it "should delete has_one with_association cache" do
      user.cached_account
      Rails.cache.read("users/#{user.id}/association/account").should_not be_nil
      @account.save
      Rails.cache.read("users/#{user.id}/association/account").should be_nil
    end

    it "should delete has_and_belongs_to_many with_association cache" do
      @post1.cached_tags
      Rails.cache.read("posts/#{@post1.id}/association/tags").should_not be_nil
      @tag1.save
      Rails.cache.read("posts/#{@post1.id}/association/tags").should be_nil
    end

    it "should delete has_one through belongs_to with_association cache" do
      @group1.save
      Rails.cache.read("users/#{user.id}/association/group").should be_nil
      user.cached_group.should == @group1
      Rails.cache.read("users/#{user.id}/association/group").should == coder.call(@group1)
    end
  end
end
