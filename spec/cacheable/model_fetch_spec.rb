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
 			User.fetch(1).should == user
 		end
 	end

 	describe "association fetch" do

 		it "should find associations by name" do
 			user.fetch_association(user, :posts).should == [@post1, @post2]
 		end
 	end
end
