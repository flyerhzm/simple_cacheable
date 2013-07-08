module Cacheable
  module ClassMethods
    def model_cache(&block)
      class_attribute :cached_key,
                      :cached_indices,
                      :cached_methods,
                      :cached_class_methods,
                      :cached_associations
      instance_exec &block
    end

    def attribute_cache_key(attribute, value)
      "#{name.tableize}/attribute/#{attribute}/#{URI.escape(value.to_s)}"
    end

    def all_attribute_cache_key(attribute, value)
      "#{name.tableize}/attribute/#{attribute}/all/#{URI.escape(value.to_s)}"
    end

    def class_method_cache_key(meth, *args)
      key = "#{name.tableize}/class_method/#{meth}"
      args.flatten!
      key += "/#{args.join('+')}" if args.any?
      return key
    end
  end
end