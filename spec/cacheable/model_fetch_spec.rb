require 'spec_helper'

describe Cacheable do

  let(:cache) { Rails.cache }

  before :all do
    @user   = User.create(:login => 'flyerhzm')
    @post1  = @user.posts.create(:title => 'post1')
    @post2  = @user.posts.create(:title => 'post2')
  end

  describe "singleton fetch" do
    it "should find an object by id" do
      key = User.instance_cache_key(1)
      Cacheable.fetch(key) do
        User.find(1)
      end.should == @user
    end
  end

  describe "association fetch" do
    it "should find associations by name" do
      key = @user.have_association_cache_key(:posts)
      Cacheable.fetch(key) do
        @user.send(:posts)
      end.should == [@post1, @post2]
    end
  end

  describe "unit tests" do
    describe "#write" do
      it "should write an encoded object to the cache" do
        Rails.cache.read(@user.model_cache_key).should be_nil
        Cacheable.send(:write, @user.model_cache_key, @user)
        Rails.cache.read(@user.model_cache_key).should == { :class => @user.class, 'attributes' => @user.attributes }
      end
    end

    describe "#read" do
      it "should decode an encoded object read from the cache" do
        Rails.cache.read(@user.model_cache_key).should be_nil
        Rails.cache.write(@user.model_cache_key, {:class => @user.class, 'attributes' => @user.attributes} )
        Cacheable.send(:read, @user.model_cache_key).should == @user
      end

      it "returns nil if value is nil" do
        Cacheable.send(:read, "clearly_a_nil_key").should be_nil
      end
    end

    describe "#coder_from_record" do
      it "should encode an object" do
        Cacheable.send(:coder_from_record, @user).should == {:class => @user.class, 'attributes' => @user.attributes}
      end

      it "returns nil if record is nil" do
        Cacheable.send(:coder_from_record, nil).should be_nil
      end

      it "returns the record if it's not an AR object" do
        Cacheable.send(:coder_from_record, false).should be_false
      end
    end

    describe "#record_from_coder" do
      it "should decode an object" do
        Cacheable.send(:record_from_coder, {:class => @user.class,
                                    'attributes' => @user.attributes}).should == @user
      end

      it "returns the object if it's not a hash" do
        Cacheable.send(:record_from_coder, false).should be_false
        Cacheable.send(:record_from_coder, @user).should == @user
      end
    end
  end

  describe "returning a hash with class key" do
    it "handles a hash with a class key at fetch level" do
      key = "cacheable_hash"
      hash_value = {:superman => "Clark Kent", :batman => "Bruce Wayne"}
      Cacheable.send(:write, key, hash_value)
      Cacheable.send(:read, key).should == hash_value
    end

    it "handles a hash with a class key" do
      hash_value = @user.hash_with_class_key
      @user.cached_hash_with_class_key.should == hash_value
      User.first.cached_hash_with_class_key.should == hash_value
    end
  end
end
