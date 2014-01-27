require 'spec_helper'

describe Cacheable do
  let(:cache) { Rails.cache }

  before :all do
    user       = User.create(:login => 'flyerhzm')
    descendant = Descendant.create(:login => "scotterc")
    post1 = user.posts.create(:title => 'post1')
    post1.images.create(:name => "foobar")
    user2       = User.create(:login => 'PelegR')
    user2.posts.create(:title => 'post3')
    descendant.posts.create(:title => 'post3')
  end

  before :each do
    @user             = User.find_by_login('flyerhzm')
    @descendant       = Descendant.find_by_login('scotterc')
    @post1            = Post.find_by_title("post1")
    @post3            = Post.where(user_id: @descendant.id, title: "post3").first
  end

  context "exiring" do
    it "should delete with_key cache" do
      User.find_cached(@user.id)
      Rails.cache.read("users/#{@user.id}").should_not be_nil
      @user.save
      Rails.cache.read("users/#{@user.id}").should be_nil
    end

    it "should delete with_attribute cache" do
      @user = User.find_cached_by_login("flyerhzm")
      Rails.cache.read("users/attribute/login/flyerhzm").should == {:class => @user.class, 'attributes' => @user.attributes}
      @user.save
      Rails.cache.read("users/attribute/login/flyerhzm").should be_nil
    end

    it "should delete with_method cache" do
      @user.cached_last_post
      Rails.cache.read("users/#{@user.id}/method/last_post").should_not be_nil
      @user.save
      Rails.cache.read("users/#{@user.id}/method/last_post").should be_nil
    end

    it "should delete with_class_method cache (default_post)" do
      Post.cached_default_post
      Rails.cache.read("posts/class_method/default_post").should_not be_nil
      @post1.save
      Rails.cache.read("posts/class_method/default_post").should be_nil
    end

    it "should delete with_class_method cache (retrieve_with_user_id)" do
      Post.cached_retrieve_with_user_id(1)
      Rails.cache.read("posts/class_method/retrieve_with_user_id/1").should_not be_nil
      @post1.save
      Rails.cache.read("posts/class_method/retrieve_with_user_id/1").should be_nil
    end

    it "should delete with_class_method cache (retrieve_with_user_id) with different arguments" do
      Post.cached_retrieve_with_user_id(1)
      Post.cached_retrieve_with_user_id(2)
      Rails.cache.read("posts/class_method/retrieve_with_user_id/1").should_not be_nil
      Rails.cache.read("posts/class_method/retrieve_with_user_id/2").should_not be_nil
      @post1.save
      Rails.cache.read("posts/class_method/retrieve_with_user_id/1").should be_nil
      Rails.cache.read("posts/class_method/retrieve_with_user_id/2").should be_nil
    end

    it "should delete with_class_method cache (retrieve_with_both)" do
      Post.cached_retrieve_with_both(1, 1)
      Rails.cache.read("posts/class_method/retrieve_with_both/1+1").should_not be_nil
      @post1.save
      Rails.cache.read("posts/class_method/retrieve_with_both/1+1").should be_nil
    end

    it "should delete associations cache" do
      Rails.cache.read("users/#{@user.id}/association/images").should be_nil
      @user.cached_images
      Rails.cache.read("users/#{@user.id}/association/images").should_not be_nil
      @user.save
      Rails.cache.read("users/#{@user.id}/association/images").should be_nil
    end

    context "with expire model cache" do
      it "should delete with_key cache" do
        User.find_cached(@user.id)
        Rails.cache.read("users/#{@user.id}").should_not be_nil
        @user.expire_model_cache
        Rails.cache.read("users/#{@user.id}").should be_nil
      end

      it "should delete with_attribute cache" do
        @user = User.find_cached_by_login("flyerhzm")
        Rails.cache.read("users/attribute/login/flyerhzm").should == coder(@user)
        @user.expire_model_cache
        Rails.cache.read("users/attribute/login/flyerhzm").should be_nil
      end

      it "should delete with_method cache" do
        @user.cached_last_post
        Rails.cache.read("users/#{@user.id}/method/last_post").should_not be_nil
        @user.expire_model_cache
        Rails.cache.read("users/#{@user.id}/method/last_post").should be_nil
      end

      it "should delete with_class_method cache (default_post)" do
        Post.cached_default_post
        Rails.cache.read("posts/class_method/default_post").should_not be_nil
        @post1.save
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

      it "should delete associations cache" do
        @user.cached_images
        Rails.cache.read("users/#{@user.id}/association/images").should_not be_nil
        @user.expire_model_cache
        Rails.cache.read("users/#{@user.id}/association/images").should be_nil
      end
    end

  end

  context "single table inheritance bug" do
    context "user" do
      it "has cached indices" do
        User.cached_indices.should_not be_nil
      end

      it "has specific cached indices" do
        User.cached_indices.keys.should include :login
        User.cached_indices.keys.should_not include :email
      end
    end

    context "expiring class_method cache" do
      it "expires correctly from inherited attributes" do
        Rails.cache.read("users/class_method/default_name").should be_nil
        User.cached_default_name
        Rails.cache.read("users/class_method/default_name").should == "flyerhzm"
        @user.expire_model_cache
        Rails.cache.read("users/class_method/default_name").should be_nil
      end
    end

    context "descendant" do

      it "should have cached indices hash" do
        Descendant.cached_indices.should_not be_nil
      end

      it "has specific cached indices" do
        Descendant.cached_indices.keys.should include :login
        Descendant.cached_indices.keys.should include :email
      end

      context "expiring method cache" do
        it "expires correctly from inherited attributes" do
          Rails.cache.read("users/#{@descendant.id}/method/last_post").should be_nil
          @descendant.cached_last_post.should == @descendant.last_post
          Rails.cache.read("users/#{@descendant.id}/method/last_post").should == {:class => @descendant.last_post.class,
                                                                                  'attributes' => @descendant.last_post.attributes}
          @descendant.expire_model_cache
          Rails.cache.read("users/#{@descendant.id}/method/last_post").should be_nil
        end
      end

      context "expiring attribute cache" do
        it "expires correctly from inherited attributes" do
          Rails.cache.read("users/attribute/login/scotterc").should be_nil
          Descendant.find_cached_by_login("scotterc").should == @descendant
          Rails.cache.read("users/attribute/login/scotterc").should == {:class => @descendant.class, 'attributes' => @descendant.attributes}
          @descendant.expire_model_cache
          Rails.cache.read("users/attribute/login/scotterc").should be_nil
        end
      end

      context "expiring association cache" do
        it "expires correctly from inherited attributes" do
          Rails.cache.read("users/#{@descendant.id}/association/posts").should be_nil
          @descendant.cached_posts.should == [@post3]
          Rails.cache.read("users/#{@descendant.id}/association/posts").should == [coder(@post3)]
          @descendant.expire_model_cache
          Rails.cache.read("users/#{@descendant.id}/association/posts").should be_nil
        end
      end

      context "expiring class_method cache" do
        it "expires correctly from inherited attributes" do
          Rails.cache.read("users/class_method/default_name").should be_nil
          Descendant.cached_default_name
          Rails.cache.read("users/class_method/default_name").should == "ScotterC"
          @descendant.expire_model_cache
          Rails.cache.read("users/class_method/default_name").should be_nil
        end
      end
    end
  end
end