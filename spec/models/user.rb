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
    with_class_method :default_name, :user_with_id, :user_with_email,
                      :users_with_ids, :users_with_ids_in, :user_with_attributes
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

    # accepts a number
  def self.user_with_id(id)
    User.find(id)
  end

  # accepts a string
  def self.user_with_email(email)
    User.find_by_email(email)
  end

  # accepts an array
  def self.users_with_ids(ids)
    User.find(ids)
  end

  # accepts a range
  def self.users_with_ids_in(range)
    User.select { |u| range.include?(u.id) }
  end
end
