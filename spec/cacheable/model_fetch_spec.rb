require 'spec_helper'

describe Cacheable do 

	let(:cache) { Rails.cache }
  let(:user)  { User.create(:login => 'flyerhzm') }

  before :all do
    @post1 = user.posts.create(:title => 'post1')
    @post2 = user.posts.create(:title => 'post2')
    user.save
  end

 	describe "singleton fetch" do

 		it "should find an object by id" do
 			key = User.instance_cache_key(1)
 			Cacheable::ModelFetch.fetch(key) do 
 				User.find(1)
 			end.should == user
 		end
 	end

 	describe "association fetch" do

 		it "should find associations by name" do
 			key = user.have_association_cache_key(:posts)
 			Cacheable::ModelFetch.fetch(key) do 
 				user.send(:posts)
 			end.should == [@post1, @post2]
 		end
 	end

 	describe "unit tests" do
 		before :each do
 			Rails.cache.clear
 		end

 		describe "#write_to_cache" do
 			it "should write an encoded object to the cache" do
 				Rails.cache.read(user.model_cache_key).should be_nil
 				Cacheable::ModelFetch.send(:write_to_cache, user.model_cache_key, user)
 				Rails.cache.read(user.model_cache_key).should == { :class => user.class, 'attributes' => user.attributes }
 			end
 		end

 		describe "#read_from_cache" do
 			it "should decode an encoded object read from the cache" do
 				Rails.cache.read(user.model_cache_key).should be_nil
 				Rails.cache.write(user.model_cache_key, {:class => user.class, 'attributes' => user.attributes} )
 				Cacheable::ModelFetch.send(:read_from_cache, user.model_cache_key).should == user
 			end
 		end

 		describe "#coder_from_record" do
 			it "should encode an object" do
 				Cacheable::ModelFetch.send(:coder_from_record, user).should == {:class => user.class, 'attributes' => user.attributes}
 			end
 		end

 		describe "#record_from_coder" do
 			it "should decode an object" do
 				Cacheable::ModelFetch.send(:record_from_coder, {:class => user.class, 'attributes' => user.attributes}).should == user
 			end
 		end
 	end
end
