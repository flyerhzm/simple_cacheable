class Post < ActiveRecord::Base
  include Cacheable

  belongs_to :user

  has_many :comments, :as => :commentable
  has_many :images, :as => :viewable

  has_and_belongs_to_many :tags

  model_cache do
    with_key
    with_attribute :user_id
    with_association :user, :comments, :images, :tags
    with_class_method :default_post, :retrieve_with_user_id, :retrieve_with_both
  end

  def self.default_post
    Post.first
  end

  def self.retrieve_with_user_id(user_id)
    Post.find_by_user_id(user_id)
  end

  def self.retrieve_with_both(user_id, post_id)
    Post.find(post_id) == Post.find_by_user_id(user_id)
  end

end
