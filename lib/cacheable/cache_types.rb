module Cacheable
  module CacheTypes
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

    def with_attribute(*attributes)
      self.cached_indices = attributes.inject({}) { |indices, attribute| indices[attribute] = {} }

      class_eval do
        after_commit :expire_attribute_cache, :on => :update
        after_commit :expire_all_attribute_cache, :on => :update
      end

      attributes.each do |attribute|
        define_singleton_method("find_cached_by_#{attribute}") do |value|
          self.cached_indices["#{attribute}"] ||= []
          self.cached_indices["#{attribute}"] << value
          Rails.cache.fetch attribute_cache_key("#{attribute}", value) do
            self.send("find_by_#{attribute}", value)
          end
        end

        define_singleton_method("find_cached_all_by_#{attribute}") do |value|
          self.cached_indices["#{attribute}"] ||= []
          self.cached_indices["#{attribute}"] << value
          Rails.cache.fetch all_attribute_cache_key("#{attribute}", value) do
            self.send("find_all_by_#{attribute}", value)
          end
        end
      end
    end

    def with_method(*methods)
      self.cached_methods = methods

      class_eval do
        after_commit :expire_method_cache, :on => :update
      end

      methods.each do |meth|
        define_method("cached_#{meth}") do
          Rails.cache.fetch method_cache_key(meth) do
            send(meth)
          end
        end
      end
    end

    # Cached class method
    # Should expire on any instance save
    def with_class_method(*methods)
      self.cached_class_methods = methods.inject({}) { |indices, meth| indices[meth] = {} }

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

    def with_association(*association_names)
      self.cached_associations = association_names

      association_names.each do |association_name|
        association = reflect_on_association(association_name)

        if :belongs_to == association.macro
          polymorphic = association.options[:polymorphic]
          polymorphic ||= false

          define_method("cached_#{association_name}") do
            Rails.cache.fetch belong_association_cache_key(association_name, polymorphic) do
              send(association_name)
            end
          end
        else
          if through_reflection_name = association.options[:through]
            through_association = self.reflect_on_association(through_reflection_name)

            # FIXME it should be the only reflection but I'm not 100% positive
            reverse_through_association = through_association.klass.reflect_on_all_associations(:belongs_to).first

            # In a through association it doesn't have to be a belongs_to
            reverse_association = association.klass.reflect_on_all_associations(:belongs_to).find { |reverse_association|
              reverse_association.options[:polymorphic] ? reverse_association.name == association.source_reflection.options[:as] : reverse_association.klass == self
            }
            if reverse_association
              association.klass.class_eval do
                after_commit "expire_#{association_name}_cache".to_sym

                define_method("expire_#{association_name}_cache") do
                  if respond_to? "expire_#{reverse_association.name}_cache".to_sym
                    # cached_viewable.expire_association_cache
                    send("cached_#{reverse_association.name}").expire_association_cache(association_name)
                  else
                    send(reverse_association.name).send(reverse_through_association.name).expire_association_cache(association_name)
                  end
                end
              end
            end
          elsif :has_and_belongs_to_many == association.macro
              # No such thing as a polymorphic has_and_belongs_to_many
              reverse_association = association.klass.reflect_on_all_associations(:has_and_belongs_to_many).find { |reverse_association|
                reverse_association.klass == self
              }

              association.klass.class_eval do
                after_commit "expire_#{association_name}_cache".to_sym

                define_method "expire_#{association_name}_cache" do
                  if respond_to? "cached_#{reverse_association.name}".to_sym
                    # cached_viewable.expire_association_cache
                    send("cached_#{reverse_association.name}").expire_association_cache(association_name)
                  else
                    send("#{reverse_association.name}").each do |assoc|
                      assoc.expire_association_cache(association_name)
                    end
                  end
                end
              end
          else
            reverse_association = association.klass.reflect_on_all_associations(:belongs_to).find { |reverse_association|
              reverse_association.options[:polymorphic] ? reverse_association.name == association.options[:as] : reverse_association.klass == self
            }

            association.klass.class_eval do
              after_commit "expire_#{association_name}_cache".to_sym

              define_method "expire_#{association_name}_cache" do
                if respond_to? "cached_#{reverse_association.name}".to_sym
                  send("cached_#{reverse_association.name}").expire_association_cache(association_name)
                else
                  send("#{reverse_association.name}").expire_association_cache(association_name)
                end
              end
            end
          end

          define_method("cached_#{association_name}") do
            Rails.cache.fetch have_association_cache_key(association_name) do
              send(association_name).respond_to?(:to_a) ? send(association_name).to_a : send(association_name)
            end
          end
        end
      end
    end

  end

end