class Comment < ActiveRecord::Base
  include Cacheable

  belongs_to :commentable, :polymorphic => true

  model_cache do
    with_association :commentable
  end
end
