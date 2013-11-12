module Cacheable
  module AttributeCache
    def with_attribute(*attributes)
      self.cached_indices ||= {}
      self.cached_indices = self.cached_indices.merge(attributes.each_with_object({}) {
        |attribute, indices| indices[attribute] = {}
      })

      class_eval do
        after_commit :expire_attribute_cache, :on => :update
        after_commit :expire_all_attribute_cache, :on => :update
      end

      attributes.each do |attribute|
        define_singleton_method("find_cached_by_#{attribute}") do |value|
          self.cached_indices["#{attribute}"] ||= []
          self.cached_indices["#{attribute}"] << value
          Cacheable::ModelFetch.fetch(attribute_cache_key("#{attribute}", value)) do
            self.send("find_by_#{attribute}", value)
          end
        end

        define_singleton_method("find_cached_all_by_#{attribute}") do |value|
          self.cached_indices["#{attribute}"] ||= []
          self.cached_indices["#{attribute}"] << value
          Cacheable::ModelFetch.fetch(all_attribute_cache_key("#{attribute}", value)) do
            self.send("find_all_by_#{attribute}", value)
          end
        end
      end
    end
  end
end