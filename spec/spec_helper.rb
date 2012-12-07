$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'rails'
require 'active_record'
require 'rspec'
require 'mocha/api'
require 'memcached'
require 'cacheable'


# MODELS = File.join(File.dirname(__FILE__), "models")
# $LOAD_PATH.unshift(MODELS)
# Dir[ File.join(MODELS, "*.rb") ].each { |f| require f }

# It needs this order otherwise cacheable throws
# errors when looking for reflection classes
# Specifically, post can't be before tag
# and user can't be before post
require 'models/account'
require 'models/comment'
require 'models/image'
require 'models/tag'
require 'models/post'
require 'models/user'

ActiveRecord::Migration.verbose = false
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')

module Rails
  class <<self
    def cache
      @cache ||= Memcached::Rails.new
    end
  end
end

RSpec.configure do |config|
  config.mock_with :mocha

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.before :all do
    ::ActiveRecord::Schema.define(:version => 1) do
      create_table :users do |t|
        t.string :login
      end

      create_table :accounts do |t|
        t.integer :user_id
      end

      create_table :posts do |t|
        t.integer :user_id
        t.string :title
      end

      create_table :comments do |t|
        t.integer :commentable_id
        t.string :commentable_type
      end

      create_table :images do |t|
        t.integer :viewable_id
        t.string :viewable_type
      end

      create_table :tags do |t|
        t.string :title
      end

      create_table :posts_tags, id: false do |t|
        t.integer :post_id
        t.integer :tag_id
      end
    end

  end

  config.after :all do
    ::ActiveRecord::Base.connection.tables.each do |table|
      ::ActiveRecord::Base.connection.drop_table(table)
    end
  end
end
