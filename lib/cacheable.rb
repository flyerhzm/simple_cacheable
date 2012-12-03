require 'uri'

module Cacheable
  def self.included(base)
    base.class_eval do
      class <<self
        def model_cache(&block)
          class_attribute :cached_key, :cached_indices, :cached_methods
          instance_exec &block
        end

        def with_key
          self.cached_key = true

          class_eval <<-EOF
            after_commit :expire_key_cache, :on => :update

            def self.find_cached(id)
              Rails.cache.fetch "#{name.tableize}/" + id.to_i.to_s do
                self.find(id)
              end
            end
          EOF
        end

        def with_attribute(*attributes)
          self.cached_indices = attributes.inject({}) { |indices, attribute| indices[attribute] = {} }

          class_eval <<-EOF
            after_commit :expire_attribute_cache, :on => :update
            after_commit :expire_all_attribute_cache, :on => :update

          EOF

          attributes.each do |attribute|
            class_eval <<-EOF
              def self.find_cached_by_#{attribute}(value)
                self.cached_indices["#{attribute}"] ||= []
                self.cached_indices["#{attribute}"] << value
                Rails.cache.fetch attribute_cache_key("#{attribute}", value) do
                  self.find_by_#{attribute}(value)
                end
              end

              def self.find_cached_all_by_#{attribute}(value)
                self.cached_indices["#{attribute}"] ||= []
                self.cached_indices["#{attribute}"] << value
                Rails.cache.fetch all_attribute_cache_key("#{attribute}", value) do
                  self.find_all_by_#{attribute}(value)
                end
              end
            EOF
          end
        end

        def with_method(*methods)
          self.cached_methods = methods

          class_eval <<-EOF
            after_commit :expire_method_cache, :on => :update
          EOF

          methods.each do |meth|
            class_eval <<-EOF
              def cached_#{meth}
                Rails.cache.fetch method_cache_key("#{meth}") do
                  #{meth}
                end
              end
            EOF
          end
        end

        def with_association(*association_names)
          association_names.each do |association_name|
            association = reflect_on_association(association_name)
            if :belongs_to == association.macro
              polymorphic = association.options[:polymorphic]
              polymorphic ||= false
              class_eval <<-EOF
                def cached_#{association_name}
                  Rails.cache.fetch belong_association_cache_key("#{association_name}", #{polymorphic}) do
                    #{association_name}
                  end
                end
              EOF
            else
              reverse_association = association.klass.reflect_on_all_associations(:belongs_to).find { |reverse_association|
                reverse_association.options[:polymorphic] ? reverse_association.name == association.options[:as] : reverse_association.klass == self
              }
              association.klass.class_eval <<-EOF
                after_commit :expire_#{association_name}_cache

                def expire_#{association_name}_cache
                  if respond_to? :cached_#{reverse_association.name}
                    cached_#{reverse_association.name}.expire_association_cache(:#{association_name})
                  else
                    #{reverse_association.name}.expire_association_cache(:#{association_name})
                  end
                end
              EOF

              class_eval <<-EOF
                def cached_#{association_name}
                  Rails.cache.fetch have_association_cache_key("#{association_name}") do
                    #{association_name}.respond_to?(:all) ? #{association_name}.all : #{association_name}
                  end
                end
              EOF
            end
          end
        end

        def attribute_cache_key(attribute, value)
          "#{name.tableize}/attribute/#{attribute}/#{URI.escape(value.to_s)}"
        end

        def all_attribute_cache_key(attribute, value)
          "#{name.tableize}/attribute/#{attribute}/all/#{URI.escape(value.to_s)}"
        end
      end
    end
  end

  def expire_model_cache
    expire_key_cache if self.class.cached_key
    expire_attribute_cache if self.class.cached_indices.present?
    expire_method_cache if self.class.cached_methods.present?
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

  def expire_association_cache(name)
    Rails.cache.delete have_association_cache_key(name)
  end

  def model_cache_key
    "#{self.class.name.tableize}/#{self.id.to_i}"
  end

  def method_cache_key(meth)
    "#{model_cache_key}/method/#{meth}"
  end

  def belong_association_cache_key(name, polymorphic=nil)
    if polymorphic
      "#{self.send("#{name}_type").tableize}/#{self.send("#{name}_id")}"
    else
      "#{name.tableize}/#{self.send(name + "_id")}"
    end
  end

  def have_association_cache_key(name)
    "#{model_cache_key}/association/#{name}"
  end
end
