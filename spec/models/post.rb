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
  end
end
