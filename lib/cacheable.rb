require 'uri'
require "cacheable/caches"
require "cacheable/keys"
require "cacheable/expiry"

module Cacheable
  def self.included(base)
    base.extend(Cacheable::Caches)
    base.send :include, Cacheable::Keys
    base.send :include, Cacheable::Expiry
    base.send :extend,  ClassMethods
    base.class_eval do
      class_attribute   :cached_key,
                        :cached_indices,
                        :cached_methods,
                        :cached_class_methods,
                        :cached_associations
    end

  end

  module ClassMethods
    def model_cache(&block)
      instance_exec &block
    end
  end

end


# class NilClass
#   def expire_association_cache(name)
#     byebug
#     a = 1
#   end
# end