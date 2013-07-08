source "http://rubygems.org"

# Specify your gem's dependencies in cacheable.gemspec
gemspec

platforms :ruby do
  gem "sqlite3"
  gem "memcached"
end

platforms :jruby do
  gem "activerecord-jdbc-adapter"
  gem "activerecord-jdbcsqlite3-adapter"
  gem "jruby-memcached"
end