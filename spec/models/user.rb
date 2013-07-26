class User < ActiveRecord::Base
  include Cacheable

  has_many :posts
  has_one :account
  has_many :images, through: :posts

  has_one :group, through: :account

  model_cache do
    with_key
    with_attribute :login
    with_method :last_post
    with_association :posts, :account, :images, :group
    with_class_method :default_name
  end

  def last_post
    posts.last
  end

  def self.default_name
    "flyerhzm"
  end

end
