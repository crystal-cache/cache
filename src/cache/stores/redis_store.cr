require "../store"
require "redis"

module Cache
  # A cache store implementation which stores data in Redis.
  #
  # By default address is equal localhost:6379
  #
  # ```crystal
  # cache = Cache::RedisStore(String, String).new(expires_in: 1.minute)
  # cache.fetch("today") do
  #   Time.now.day_of_week
  # end
  # ```
  struct RedisStore(K, V) < Store(K, V)
    def initialize(@expires_in : Time::Span)
      @cache = Redis.new
    end

    def write(key : K, value : V, *, expires_in = @expires_in)
      @cache.set(key, value, expires_in.total_seconds.to_i)
    end

    def read(key : K)
      @cache.get(key)
    end

    def fetch(key : K, &block)
      value = read(key)
      return value if value

      value = yield

      write(key, value)
      value
    end
  end
end
