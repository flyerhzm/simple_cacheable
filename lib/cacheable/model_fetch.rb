module Cacheable
	
	module ClassMethods
			
			def singleton_fetch(key, &block)
				result = self.new.fetch(key) do
					yield
				end
			end

	end

	module ModelFetch

		def fetch(key, &block)
			
			result = read_from_cache(key)

			if result.nil?
				if block_given?
					result = yield
					write_to_cache(key, result)
				end
			end
			result
		end

		def coder_from_record(record)
			unless record.nil?
				coder = { :class => record.class }
				record.encode_with(coder)
				coder
			end
		end

		def record_from_coder(coder)
			record = coder[:class].allocate
			record.init_with(coder)
		end

		def write_to_cache(key, value)
			if value.respond_to?(:to_a)
				value = value.to_a
				coder = value.map {|obj| coder_from_record(obj) }
			else
				coder = coder_from_record(value)
			end

			Rails.cache.write(key, coder)
			coder
		end

		def read_from_cache(key)
			coder = Rails.cache.read(key)
			return nil if coder.nil?
			
			unless coder.is_a?(Array)
				record_from_coder(coder)
			else
				coder.map { |obj| record_from_coder(obj) }
			end
		end
	end
end