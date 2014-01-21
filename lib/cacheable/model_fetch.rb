module Cacheable
  module ModelFetch
    def fetch(key, options=nil)
      unless result = read(key, options)
        if block_given?
          result = yield
          write(key, result, options) unless result.nil?
        end
      end
      result
    end

    private

    def write(key, value, options=nil)
      options ||= {}

      coder = if !value.is_a?(Hash) && value.respond_to?(:to_a)
        value.to_a.map {|obj| coder_from_record(obj) }
      else
        coder_from_record(value)
      end

      Rails.cache.write(key, coder, options)
      coder
    end

    def read(key, options=nil)
      options ||= {}
      value = Rails.cache.read(key, options)
      return nil if value.nil?

      if !value.is_a?(Hash) && value.respond_to?(:to_a)
        value.to_a.map { |obj| record_from_coder(obj) }
      else
        record_from_coder(value)
      end
    end

    def coder_from_record(record)
      return if record.nil?
      return record unless record.is_a?(ActiveRecord::Base)

      coder = { :class => record.class }
      record.encode_with(coder)
      coder
    end

    def record_from_coder(coder)
      return coder unless coder?(coder)
      klass = coder[:class]
      return coder unless klass.is_a?(Class)
      record = klass.allocate
      record.init_with(coder)
    end

    def coder?(value)
      value.is_a?(Hash) && value[:class].present?
    end
  end
end