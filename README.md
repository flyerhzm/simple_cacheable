cacheable
=========

cacheable is a simple cache implementation based on activerecord, it is
extracted from [rails-bestpractices.com][1].

it supports activerecord >= 3.0.0

Usage
-----

    class User < ActiveRecord::Base
      include Cacheable

      has_many :posts

      model_cache do
        with_key                   # User.find_cached(1)
        with_attribute :login      # User.find_by_login('flyerhzm')
        with_method :last_post     # user.cached_last_post
      end

      def last_post
        posts.last
      end
    end

    class Post < ActiveRecord::Base
      include Cacheable

      belongs_to :user
      has_many :comments, :as => :commentable

      model_cache do
        with_key                   # post.find_cached(1)
        with_association :user     # post.cached_user
      end
    end

    class Comment < ActiveRecord::Base
      include Cacheable

      belongs_to :commentable, :polymorphic => true

      model_cache do
        with_association :commentable  # comment.cached_commentable
      end
    end

Install
-------

add the following code to your Gemfile

    gem "simple_cacheable", :require => "cacheable"


Copyright © 2011 Richard Huang (flyerhzm@gmail.com), released under the MIT license


[1]:https://github.com/flyerhzm/rails-bestpractices.com
