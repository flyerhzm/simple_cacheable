module Cacheable
  module AssocationCache
    def with_association(*association_names)
      self.cached_associations ||= {}
      self.cached_associations = self.cached_associations.merge(association_names.each_with_object({}) {
        |meth, hash| hash[meth.to_sym] = {}
      })

      class_eval do
        after_commit :expire_associations_cache
      end

      association_names.each do |association_name|
        association = reflect_on_association(association_name)


        polymorphic = association.options[:polymorphic]
        polymorphic ||= false

        type = determine_type_of(association)
        belongs_to = type == :belongs_to
        association_info = { :polymorphic => polymorphic, :type => type }
        self.cached_associations[association_name].merge!(association_info)

        build_cache_method_for(association_name, association_info)
        build_expire_cache_method_for(association, association_name, association_info) unless belongs_to
      end
    end

    def build_cache_method_for(association_name, association_info)
      method_name = :"cached_#{association_name}"

      define_method(method_name) do
        if instance_variable_get("@#{method_name}").nil?

          cache_key = association_cache_key(association_name, association_info)

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

    def build_expire_cache_method_for(association, association_name, association_info)
      type = association_info[:type]
      reverse_association = get_reverse_association_for(association, type)
      return if reverse_association.nil?

      method_name         = reverse_association.name
      cached_method_name  = :"cached_#{method_name}"
      expire_method_name  = :"expire_#{cacheable_table_name}_#{association_name}_cache"

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
              [send(method_name)].flatten.each do |assoc|
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
      else
        association.macro
      end
    end

    def get_reverse_association_for(association, type)
      relationship = type == :has_and_belongs_to_many ? :has_and_belongs_to_many : :belongs_to
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