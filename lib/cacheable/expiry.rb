module Cacheable
  module Expiry
    def expire_model_cache
      expire_key_cache            if self.class.cached_key
      expire_attribute_cache      if self.class.cached_indices.present?
      expire_all_attribute_cache  if self.class.cached_indices.present?
      expire_method_cache         if self.class.cached_methods.present?
      expire_class_method_cache   if self.class.cached_class_methods.present?

      if self.class.cached_associations.present?
        self.class.cached_associations.each do |assoc|
          expire_association_cache(assoc)
        end
      end
    end

    def expire_key_cache
      Rails.cache.delete model_cache_key
    end

    def expire_attribute_cache
      self.class.cached_indices.each do |attribute, values|
        value = self.send(attribute)
        Rails.cache.delete self.class.attribute_cache_key(attribute, value)
      end
    end

    def expire_all_attribute_cache
      self.class.cached_indices.each do |attribute, values|
        value = self.send(attribute)
        Rails.cache.delete self.class.all_attribute_cache_key(attribute, value)
      end
    end

    def expire_method_cache
      self.class.cached_methods.each do |meth|
        Rails.cache.delete method_cache_key(meth)
      end
    end

    def expire_class_method_cache
      self.class.cached_class_methods.each do |meth, args|
        args.each do |arg|
          Rails.cache.delete self.class.class_method_cache_key(meth, arg)
        end
      end
    end

    def expire_association_cache(name)
      Rails.cache.delete have_association_cache_key(name)
    end
  end
end