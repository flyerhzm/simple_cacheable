cacheable
=========

cacheable is a simple cache implementation based on activerecord, it is
extracted from [rails-bestpractices.com][1].

it supports activerecord >= 3.0.0, works on 1.9.2, 1.9.3 and jruby.

Introduction
------------

Here is a blog post to introduce simple_cacheable gem, <http://rails-bestpractices.com/blog/posts/24-simple_cacheable>

Usage
-----

    class User < ActiveRecord::Base
      include Cacheable

      has_many :posts
      has_one :account

      model_cache do
        with_key                          # User.find_cached(1)
        with_attribute :login             # User.find_cached_by_login('flyerhzm')
        with_method :last_post            # user.cached_last_post
        with_association :posts, :account # user.cached_posts, user.cached_account
      end

      def last_post
        posts.last
      end
    end

    class Account < ActiveRecord::Base
      belongs_to :user
    end

    class Post < ActiveRecord::Base
      include Cacheable

      belongs_to :user
      has_many :comments, :as => :commentable

      model_cache do
        with_key                          # post.find_cached(1)
        with_class_method  :posts_by_first_user # Post.cached_posts_by_first_user
        with_association   :user, :comments # post.cached_user, post.cached_comments
      end

      def self.posts_by_first_user
        where(user_id: User.first.id)
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
