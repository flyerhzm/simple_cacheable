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
          iv = Cacheable.escape_punctuation("@#{method_name}")
          if instance_variable_get(iv).nil?
            instance_variable_set(iv,
              (Cacheable.fetch method_cache_key(meth) do
                send(meth)
              end)
            )
          end
          instance_variable_get(iv)
        end
      end
    end
  end
end