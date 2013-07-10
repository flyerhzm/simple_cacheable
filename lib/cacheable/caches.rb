require "cacheable/types/key_cache"
require "cacheable/types/attribute_cache"
require "cacheable/types/method_cache"
require "cacheable/types/class_method_cache"
require "cacheable/types/association_cache"

module Cacheable
  module Caches
    include Cacheable::KeyCache
    include Cacheable::AttributeCache
    include Cacheable::MethodCache
    include Cacheable::ClassMethodCache
    include Cacheable::AssocationCache
  end
end