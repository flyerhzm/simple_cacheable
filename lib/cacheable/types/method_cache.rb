module Cacheable
  module MethodCache
    def with_method(*methods)
      self.cached_methods ||= []
      self.cached_methods += methods

      class_eval do
        after_commit :expire_method_cache, :on => :update
      end

      methods.each do |meth|
        method_name = "cached_#{meth}"
        define_method(method_name) do
          if instance_variable_get("@#{method_name}").nil?
            instance_variable_set("@#{method_name}",
              (Rails.cache.fetch method_cache_key(meth) do
                send(meth)
              end)
            )
          end
          instance_variable_get("@#{method_name}")
        end
      end
    end
  end
end