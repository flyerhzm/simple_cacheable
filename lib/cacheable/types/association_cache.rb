module Cacheable
  module AssocationCache

    def with_association(*association_names)
      self.cached_associations ||= []
      self.cached_associations += association_names

      association_names.each do |association_name|
        association = reflect_on_association(association_name)

        if :belongs_to == association.macro
          build_cache_belongs_to(association, association_name)
        else

          if through_reflection_name = association.options[:through]
            build_cache_has_through(association, association_name, through_reflection_name)
          elsif :has_and_belongs_to_many == association.macro
            build_cache_has_and_belongs_to_many(association, association_name)
          else
            build_cache_has_many(association, association_name)
          end

          method_name = "cached_#{association_name}"
          define_method("cached_#{association_name}") do
            if instance_variable_get("@#{method_name}").nil?
              association_cache.delete(association_name)
              cache_key = have_association_cache_key(association_name)
              result = Cacheable::ModelFetch.fetch(cache_key) do
                send(association_name)
              end
              instance_variable_set("@#{method_name}", result)
            end
            instance_variable_get("@#{method_name}")
          end
        end
      end
    end

    def build_cache_belongs_to(association, association_name)
      polymorphic = association.options[:polymorphic]
      polymorphic ||= false

      method_name = "cached_#{association_name}"
      define_method(method_name) do
        if instance_variable_get("@#{method_name}").nil?
          cache_key = belong_association_cache_key(association_name, polymorphic)
          association_cache.delete(association_name)
          result = Cacheable::ModelFetch.fetch(cache_key) do
            send(association_name)
          end
          instance_variable_set("@#{method_name}", result)
        end
        instance_variable_get("@#{method_name}")
      end
    end

    def build_cache_has_through(association, association_name, through_reflection_name)
      through_association = self.reflect_on_association(through_reflection_name)

      reverse_through_association = through_association.klass.reflect_on_all_associations(:belongs_to).detect do |assoc|
        assoc.klass.ancestors.include?(Cacheable) && assoc.klass.reflect_on_association(association.name)
      end

      # In a through association it doesn't have to be a belongs_to
      reverse_association = association.klass.reflect_on_all_associations(:belongs_to).find { |reverse_association|
        reverse_association.options[:polymorphic] ? reverse_association.name == association.source_reflection.options[:as] : reverse_association.klass == self
      }
      if reverse_association
        association.klass.class_eval do
          after_commit "expire_#{association_name}_cache".to_sym

          define_method("expire_#{association_name}_cache") do

            if respond_to? "expire_#{reverse_association.name}_cache".to_sym
              unless send("cached_#{reverse_association.name}").nil?
                send("cached_#{reverse_association.name}").expire_association_cache(association_name)
              end
            elsif !send(reverse_association.name).nil?
              if send(reverse_association.name).respond_to?(reverse_through_association.name) && !send(reverse_association.name).send(reverse_through_association.name).nil?
                send(reverse_association.name).send(reverse_through_association.name).expire_association_cache(association_name)
              end
            end
          end
        end
      end
    end

    def build_cache_has_and_belongs_to_many(association, association_name)
      # No such thing as a polymorphic has_and_belongs_to_many
      reverse_association = association.klass.reflect_on_all_associations(:has_and_belongs_to_many).find { |reverse_association|
        reverse_association.klass == self
      }

      association.klass.class_eval do
        after_commit "expire_#{association_name}_cache".to_sym

        define_method "expire_#{association_name}_cache" do
          if respond_to? "cached_#{reverse_association.name}".to_sym
            unless send("cached_#{reverse_association.name}").nil?
              # cached_viewable.expire_association_cache
              send("cached_#{reverse_association.name}").expire_association_cache(association_name)
            end
          elsif !send("#{reverse_association.name}").nil?
            send("#{reverse_association.name}").each do |assoc|
              next if assoc.nil?
              assoc.expire_association_cache(association_name)
            end
          end
        end
      end
    end

    def build_cache_has_many(association, association_name)
      reverse_association = association.klass.reflect_on_all_associations(:belongs_to).find { |reverse_association|
        reverse_association.options[:polymorphic] ? reverse_association.name == association.options[:as] : reverse_association.klass == self
      }

      association.klass.class_eval do
        after_commit "expire_#{association_name}_cache".to_sym

        define_method "expire_#{association_name}_cache" do
          if respond_to? "cached_#{reverse_association.name}".to_sym
            unless send("cached_#{reverse_association.name}").nil?
              send("cached_#{reverse_association.name}").expire_association_cache(association_name)
            end
          elsif !send("#{reverse_association.name}").nil?
            send("#{reverse_association.name}").expire_association_cache(association_name)
          end
        end
      end
    end

  end
end