class User < ActiveRecord::Base
  include Cacheable

  has_many :posts
  has_one :account
  has_many :images, through: :posts

  has_one :group, through: :account

  model_cache do
    with_key
    with_attribute :login
    with_method :last_post, :bad_iv_name!, :bad_iv_name?
    with_association :posts, :account, :images, :group
    with_class_method :default_name
  end

  def last_post
    posts.last
  end

  def self.default_name
    "flyerhzm"
  end

  def bad_iv_name!
    42
  end

  def bad_iv_name?
    44
  end

end
