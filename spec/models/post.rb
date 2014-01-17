class Post < ActiveRecord::Base
  include Cacheable
  extend FriendlyId

  belongs_to :location
  belongs_to :user

  friendly_modules = [:slugged]
  friendly_modules << :finders if Cacheable.rails4?

  friendly_id :title, use: friendly_modules

  has_many :comments, :as => :commentable
  has_many :images, :as => :viewable

  has_and_belongs_to_many :tags

  model_cache do
    with_key
    with_attribute :user_id
    with_association :user, :comments, :images, :tags
    with_class_method :retrieve_with_user_id, :retrieve_with_both, :default_post,
                      :where_options_are
  end

  before_validation :create_slug

  def self.default_post
    Post.first
  end

  def self.retrieve_with_user_id(user_id)
    Post.find_by_user_id(user_id)
  end

  def self.retrieve_with_both(user_id, post_id)
    Post.find(post_id) == Post.find_by_user_id(user_id)
  end

  def self.where_options_are(options={})
    Post.where(options).first
  end

  def create_slug
    self.slug = title
  end

  def to_param
    slug
  end
end
