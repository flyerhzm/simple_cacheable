module Cacheable
  module MethodCache
    def with_method(*methods)
      self.cached_methods ||= []
      self.cached_methods += methods

      class_eval do
        after_commit :expire_method_cache, :on => :update
      end

      methods.each do |meth|
        define_method("cached_#{meth}") do
          Rails.cache.fetch method_cache_key(meth) do
            send(meth)
          end
        end
      end
    end
  end
end