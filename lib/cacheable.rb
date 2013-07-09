require 'uri'
require "cacheable/caches"
require "cacheable/keys"
require "cacheable/expiry"

module Cacheable
  def self.included(base)
    base.extend(Cacheable::Caches)
    base.send :include, Cacheable::Keys
    base.send :include, Cacheable::Expiry

    base.class_eval do
      def self.model_cache(&block)
        class_attribute :cached_key,
                        :cached_indices,
                        :cached_methods,
                        :cached_class_methods,
                        :cached_associations
        instance_exec &block
      end
    end
  end

end
