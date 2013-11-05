module Cacheable
  module KeyCache
    def with_key
      self.cached_key = true

      class_eval do
        after_commit :expire_key_cache, on: :update
      end

      define_singleton_method("find_cached") do |id|
        model_cache_key = [name.tableize, id.to_s].join("/")
        Cacheable::ModelFetch.fetch(model_cache_key) do
          self.find(id)
        end
      end
    end
  end
end