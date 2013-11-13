module Cacheable
  module Keys

    def self.included(base)
      base.extend(Cacheable::Keys::ClassKeys)
      base.send :include, Cacheable::Keys::InstanceKeys
    end

    module ClassKeys

      def attribute_cache_key(attribute, value)
        "#{self.base_class.name.tableize}/attribute/#{attribute}/#{URI.escape(value.to_s)}"
      end

      def all_attribute_cache_key(attribute, value)
        "#{self.base_class.name.tableize}/attribute/#{attribute}/all/#{URI.escape(value.to_s)}"
      end

      def class_method_cache_key(meth, *args)
        key = "#{self.base_class.name.tableize}/class_method/#{meth}"
        args.flatten!
        key += "/#{args.join('+')}" if args.any?
        return key
      end

      def instance_cache_key(param)
        "#{self.base_class.name.tableize}/#{param}"
      end

    end

    module InstanceKeys

      def model_cache_keys
        ["#{self.class.base_class.name.tableize}/#{self.id.to_i}", "#{self.class.base_class.name.tableize}/#{self.to_param}"]
      end

      def model_cache_key
        "#{self.class.base_class.name.tableize}/#{self.id.to_i}"
      end

      def method_cache_key(meth)
        "#{model_cache_key}/method/#{meth}"
      end

      # Returns nil if association cannot be qualified
      def belong_association_cache_key(name, polymorphic=nil)
        name = name.to_s if name.is_a?(Symbol)

        if polymorphic && self.respond_to?(:"#{name}_type")
          return nil unless self.send(:"#{name}_type").present?
          "#{self.send(:"#{name}_type").constantize.base_class.name.tableize}/#{self.send(:"#{name}_id")}"
        else
          "#{name.capitalize.constantize.base_class.name.tableize}/#{self.send(:"#{name}_id")}"
        end
      end

      def have_association_cache_key(name)
        "#{model_cache_key}/association/#{name}"
      end

    end

  end
end