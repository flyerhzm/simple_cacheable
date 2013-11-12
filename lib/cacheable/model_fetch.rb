module Cacheable
	module ModelFetch

		def self.fetch(key, &block)
			unless result = read_from_cache(key)
				if block_given?
					result = yield
					write_to_cache(key, result) unless result.nil?
				end
			end
			result
		end

		private

		def self.write_to_cache(key, value)
			coder = if value.respond_to?(:to_a)
				value = value.to_a
				value.map {|obj| coder_from_record(obj) }
			else
				coder_from_record(value)
			end

			Rails.cache.write(key, coder)
			coder
		end

		def self.read_from_cache(key)
			coder = Rails.cache.read(key)
			return nil if coder.nil?
			
			if coder.is_a?(Array)
				coder.map { |obj| record_from_coder(obj) }
			else
				record_from_coder(coder)
			end
		end

		def self.coder_from_record(record)
			unless record.nil?
				coder = { :class => record.class }
				record.encode_with(coder)
				coder
			end
		end

		def self.record_from_coder(coder)
			record = coder[:class].allocate
			record.init_with(coder)
		end
	end
end