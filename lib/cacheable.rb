require 'uri'
require "cacheable/cache_types"
require "cacheable/class_methods"
require "cacheable/instance_methods"

module Cacheable
  def self.included(base)
    base.extend(Cacheable::CacheTypes)
    base.extend(Cacheable::ClassMethods)
    base.send :include, Cacheable::InstanceMethods
  end
end
