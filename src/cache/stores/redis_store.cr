require "../store"
require "../../../ext/crystal-redis/redis"
require "redis"

module Cache
  # A cache store implementation which stores data in Redis.
  #
  # ```crystal
  # cache = Cache::RedisStore(String, String).new(expires_in: 1.minute)
  # cache.fetch("today") do
  #   Time.now.day_of_week
  # end
  # ```
  #
  # This assumes Redis was started with a default configuration, and is listening on localhost, port 6379.
  #
  # You can connect to `Redis` by instantiating the `Redis` class.
  #
  # If you need to connect to a remote server or a different port, try:
  #
  # ```crystal
  # redis = Redis.new(host: "10.0.1.1", port: 6380, password: "my-secret-pw", database: "my-database")
  # cache = Cache::RedisStore(String, String).new(expires_in: 1.minute, cache: redis)
  # ```
  struct RedisStore(K, V) < Store(K, V)
    @cache : Redis

    def initialize(@expires_in : Time::Span, @cache = Redis.new)
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

      @cache.del(key) == 1_i64 ? true : false
    end

    def clear
      clear_keys

      @cache.flushdb
    end
  end
end
