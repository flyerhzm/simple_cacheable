class Post < ActiveRecord::Base
  include Cacheable

  belongs_to :user
  has_many :comments, :as => :commentable

  model_cache do
    with_key
    with_association :user
  end
end
