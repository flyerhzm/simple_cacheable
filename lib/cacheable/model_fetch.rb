module Cacheable
  module ModelFetch

    def self.fetch(key, options=nil)
      unless result = read(key, options)
        if block_given?
          result = yield
          write(key, result, options) unless result.nil?
        end
      end
      result
    end

    private

    def self.write(key, value, options=nil)
      options ||= {}
      coder = if value.respond_to?(:to_a)
        value = value.to_a
        value.map {|obj| coder_from_record(obj) }
      else
        coder_from_record(value)
      end

      Rails.cache.write(key, coder, options)
      coder
    end

    def self.read(key, options=nil)
      options ||= {}
      coder = Rails.cache.read(key, options)
      return nil if coder.nil?

      if coder.is_a?(Hash)
        record_from_coder(coder)
      else
        coder.map { |obj| record_from_coder(obj) }
      end
    end

    def self.coder_from_record(record)
      return if record.nil?
      if record.is_a?(ActiveRecord::Base)
        coder = { :class => record.class }
        record.encode_with(coder)
        coder
      else
        record
      end
    end

    def self.record_from_coder(coder)
      return coder if coder.is_a?(ActiveRecord::Base)
      record = coder[:class].allocate
      record.init_with(coder)
    end
  end
end