require 'rails'

module Cacheable
  class Railtie < ::Rails::Railtie

    initializer "cacheable.model_methods" do
      ::ActiveRecord::Base.send(:include, Cacheable)
    end
  end
end