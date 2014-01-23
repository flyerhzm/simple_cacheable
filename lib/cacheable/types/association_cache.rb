module Cacheable
  module AssocationCache
    def with_association(*association_names)
      self.cached_associations ||= []
      self.cached_associations += association_names

      association_names.each do |association_name|
        association = reflect_on_association(association_name)

        belongs_to  = association.macro == :belongs_to
        polymorphic = association.options[:polymorphic]
        polymorphic ||= false

        build_cache_method_for(association_name, belongs_to, polymorphic)
        build_expire_cache_method_for(association, association_name) unless belongs_to
      end
    end

    def build_cache_method_for(association_name, belongs_to, polymorphic)
      method_name = :"cached_#{association_name}"

      define_method(method_name) do
        if instance_variable_get("@#{method_name}").nil?

          cache_key = if belongs_to
            belong_association_cache_key(association_name, polymorphic)
          else
            have_association_cache_key(association_name)
          end

          result = if cache_key
            association_cache.delete(association_name)
            Cacheable.fetch(cache_key) do
              send(association_name)
            end
          else
            # Should be nil, but here to preserve functionality
            send(association_name)
          end

          instance_variable_set("@#{method_name}", result)
        end
        instance_variable_get("@#{method_name}")
      end
    end

    def build_expire_cache_method_for(association, association_name)
      type = determine_type_of(association)
      reverse_association = get_reverse_association_for(association, type)
      return if reverse_association.nil?

      method_name         = reverse_association.name
      cached_method_name  = :"cached_#{method_name}"
      expire_method_name  = :"expire_#{association_name}_cache"

      if type == :has_through
        through_association_class = self.reflect_on_association(association.options[:through]).klass

        # TODO: doesn't have to be a belongs_to
        reverse_through_association = through_association_class.reflect_on_all_associations(:belongs_to).detect do |assoc|
          assoc.klass.ancestors.include?(Cacheable) && assoc.klass.reflect_on_association(association.name)
        end
      end

      association.klass.class_eval do
        after_commit expire_method_name

        define_method expire_method_name do

          if respond_to?(cached_method_name) && !send(cached_method_name).nil?
            send(cached_method_name).expire_association_cache(association_name)

          elsif !send(method_name).nil?
            case type
            when :has_through
              if send(method_name).respond_to?(reverse_through_association.name) && !send(method_name).send(reverse_through_association.name).nil?
                send(method_name).send(reverse_through_association.name).expire_association_cache(association_name)
              end
            else
              send(method_name).to_a.each do |assoc|
                next if assoc.nil?
                assoc.expire_association_cache(association_name)
              end
            end
          end
        end
      end
    end

    def determine_type_of(association)
      if association.options[:through]
        :has_through
      elsif :has_and_belongs_to_many == association.macro
        :habtm
      else
        :has_many
      end
    end

    def get_reverse_association_for(association, type)
      relationship = type == :habtm ? :has_and_belongs_to_many : :belongs_to
      association.klass.reflect_on_all_associations(relationship).find do |reverse_association|
        if reverse_association.options[:polymorphic]
          as_relation = type == :has_through ? association.source_reflection.options[:as] : association.options[:as]
          reverse_association.name == as_relation
        else
          reverse_association.klass == self
        end
      end
    end
  end
end