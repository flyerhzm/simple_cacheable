module Cacheable
  module Keys

    def self.included(base)
      base.extend(Cacheable::Keys::ClassKeys)
      base.send :include, Cacheable::Keys::InstanceKeys
    end

    module ClassKeys

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

      def instance_cache_key(id)
        "#{self.name.tableize}/#{id.to_i}"
      end

    end

    module InstanceKeys

      def model_cache_key
        "#{self.class.name.tableize}/#{self.id.to_i}"
      end

      def method_cache_key(meth)
        "#{model_cache_key}/method/#{meth}"
      end

      def belong_association_cache_key(name, polymorphic=nil)
        name = name.to_s if name.is_a?(Symbol)
        if polymorphic && self.send("#{name}_type").present?
          "#{self.send("#{name}_type").tableize}/#{self.send("#{name}_id")}"
        else
          "#{name.tableize}/#{self.send(name + "_id")}"
        end
      end

      def have_association_cache_key(name)
        "#{model_cache_key}/association/#{name}"
      end

    end

  end
end