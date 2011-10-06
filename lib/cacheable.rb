module Cacheable
  def self.included(base)
    base.class_eval do
      class <<self
        def model_cache(&block)
          instance_exec &block
        end

        def with_key
          class_eval <<-EOF
            after_update :expire_key_cache

            def self.find_cached(id)
              Rails.cache.fetch "#{name.tableize}/" + id.to_i.to_s do
                self.find(id)
              end
            end
          EOF
        end

        def with_attribute(*attributes)
          class_eval <<-EOF
            after_update :expire_attribute_cache
          EOF

          class_attribute :cached_indices
          self.cached_indices = attributes.inject({}) { |indices, attribute| indices[attribute] = {} }
          attributes.each do |attribute|
            class_eval <<-EOF
              def self.find_cached_by_#{attribute}(value)
                self.cached_indices["#{attribute}"] ||= []
                self.cached_indices["#{attribute}"] << value
                Rails.cache.fetch attribute_cache_key("#{attribute}", value) do
                  self.find_by_#{attribute}(value)
                end
              end
            EOF
          end
        end

        def with_method(*methods)
          class_eval <<-EOF
            after_update :expire_method_cache
          EOF

          class_attribute :cached_methods
          self.cached_methods = methods
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
                after_save :expire_#{association_name}_cache
                after_destroy :expire_#{association_name}_cache

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
                    #{association_name}
                  end
                end
              EOF
            end
          end
        end

        def attribute_cache_key(attribute, value)
          "#{name.tableize}/attribute/#{attribute}/#{value}"
        end
      end
    end
  end

  def expire_model_cache
    expire_key_cache
    expire_attribute_cache
    expire_method_cache
  end

  def expire_key_cache
    Rails.cache.delete model_cache_key
  end

  def expire_attribute_cache
    self.class.cached_indices.each do |attribute, values|
      values.each do |value|
        Rails.cache.delete self.class.attribute_cache_key(attribute, value)
      end
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
