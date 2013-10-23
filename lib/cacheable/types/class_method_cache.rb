module Cacheable
  module ClassMethodCache
    # Cached class method
    # Should expire on any instance save
    def with_class_method(*methods)
      self.cached_class_methods = methods.each_with_object({}) { |meth, indices| indices[meth] = [] }

      class_eval do
        after_commit :expire_class_method_cache, on: :update
      end

      methods.each do |meth|
        define_singleton_method("cached_#{meth}") do |*args|
          self.cached_class_methods["#{meth}"] ||= []
          self.cached_class_methods["#{meth}"] << args
          Rails.cache.fetch class_method_cache_key(meth, args) do
            self.method(meth).arity == 0 ? send(meth) : send(meth, *args)
          end
        end
      end
    end
  end
end