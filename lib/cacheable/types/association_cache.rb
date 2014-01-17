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

          method_name = :"cached_#{association_name}"
          define_method(method_name) do
            if instance_variable_get("@#{method_name}").nil?
              association_cache.delete(association_name)
              cache_key = have_association_cache_key(association_name)
              result = Cacheable.fetch(cache_key) do
                send(association_name)
              end
              instance_variable_set("@#{method_name}", result)
            end
            instance_variable_get("@#{method_name}")
          end

        end

      end
    end

    # No expiring callback
    def build_cache_belongs_to(association, association_name)
      polymorphic = association.options[:polymorphic]
      polymorphic ||= false

      method_name         = association_name
      cached_method_name = :"cached_#{association_name}"

      define_method(cached_method_name) do
        if instance_variable_get("@#{cached_method_name}").nil?
          cache_key = belong_association_cache_key(association_name, polymorphic)
          result = if cache_key
            association_cache.delete(association_name)
            Cacheable.fetch(cache_key) do
              send(association_name)
            end
          else
            # Should be nil, but preserve functionality
            send(association_name)
          end
          instance_variable_set("@#{cached_method_name}", result)
        end
        instance_variable_get("@#{cached_method_name}")
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
          after_commit :"expire_#{association_name}_cache"

          define_method(:"expire_#{association_name}_cache") do

            method_name = reverse_association.name
            cached_method_name = :"cached_#{reverse_association.name}"

            if respond_to? cached_method_name
              unless send(cached_method_name).nil?
                send(cached_method_name).expire_association_cache(association_name)
              end
            elsif !send(method_name).nil?
              if send(method_name).respond_to?(reverse_through_association.name) && !send(method_name).send(reverse_through_association.name).nil?
                send(method_name).send(reverse_through_association.name).expire_association_cache(association_name)
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
        after_commit :"expire_#{association_name}_cache"

        define_method :"expire_#{association_name}_cache" do

          method_name = :"#{reverse_association.name}"
          cached_method_name = :"cached_#{reverse_association.name}"

          if respond_to? cached_method_name
            unless send(cached_method_name).nil?
              # cached_viewable.expire_association_cache
              send(cached_method_name).expire_association_cache(association_name)
            end
          elsif !send(method_name).nil?
            send(method_name).each do |assoc|
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
        after_commit :"expire_#{association_name}_cache"

        define_method :"expire_#{association_name}_cache" do

          cached_method_name = :"cached_#{reverse_association.name}"
          method_name = :"#{reverse_association.name}"

          if respond_to? cached_method_name
            unless send(cached_method_name).nil?
              send(cached_method_name).expire_association_cache(association_name)
            end
          elsif !send(method_name).nil?
            send(method_name).expire_association_cache(association_name)
          end

        end
      end
    end

  end
end