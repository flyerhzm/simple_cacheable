module Cacheable
  module KeyCache
    def with_key
      self.cached_key = true

      class_eval do
        after_commit :expire_key_cache, on: :update
      end

      define_singleton_method("find_cached") do |id|
        Rails.cache.fetch "#{name.tableize}/" + id.to_i.to_s do
          self.find(id)
        end
      end
    end
  end
end