class User < ActiveRecord::Base
  include Cacheable

  has_many :posts
  has_one :account
  has_many :images, through: :posts

  model_cache do
    with_key
    with_attribute :login
    with_method :last_post
    with_association :posts, :account, :images
  end

  def last_post
    posts.last
  end
end
