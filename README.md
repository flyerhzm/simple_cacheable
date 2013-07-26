cacheable
=========

cacheable is a simple cache implementation based on activerecord, it is
extracted from [rails-bestpractices.com][1].

it supports activerecord >= 3.0.0, tested on 1.9.3 and 2.0.0 and works with jruby.

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
        with_key                                # post.find_cached(1)
        with_class_method  :default_post        # Post.default_post
        with_association   :user, :comments     # post.cached_user, post.cached_comments
      end

      def self.default_post
        Post.first
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

    gem "simple_cacheable"


Gotchas
-------

Caching, and caching invalidation specifically, can be hard and confusing.  Simple Cacheable methods should
expire correctly in most cases.  Be careful using `with_method` and `with_class_method`, they should
specifically not be used to return collections.  This is demonstrated well in Tobias Lutke's presentation: [Rockstar Memcaching][2].

Copyright © 2011 Richard Huang (flyerhzm@gmail.com), released under the MIT license


[1]:https://github.com/flyerhzm/rails-bestpractices.com
[2]:http://www.infoq.com/presentations/lutke-rockstar-memcaching
