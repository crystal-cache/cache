require "../store"
require "memcached"

module Cache
  # A cache store implementation which stores data in Memcached.
  #
  # ```crystal
  # cache = Cache::MemcachedStore(String, String).new(expires_in: 1.minute)
  # cache.fetch("today") do
  #   Time.now.day_of_week
  # end
  # ```
  #
  # This assumes Memcached was started with a default configuration, and is listening on `localhost:11211`.
  struct MemcachedStore(K, V) < Store(K, V)
    @cache : Memcached::Client

    def initialize(@expires_in : Time::Span, @cache = Memcached::Client.new)
    end

    def write(key : K, value : V, *, expires_in = @expires_in)
      @keys << key
      @cache.set(key, value, expires_in.total_seconds.to_i)
    end

    def read(key : K)
      @cache.get(key)
    end

    def fetch(key : K, *, expires_in = @expires_in, &block)
      value = read(key)
      return value if value

      value = yield

      write(key, value, expires_in: expires_in)
      value
    end

    def delete(key : K) : Bool
      @keys.delete(key)
      @cache.delete(key)
    end
  end
end
