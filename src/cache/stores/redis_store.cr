require "../store"
require "redis"
require "../../ext/redis/commands"

module Cache
  # A cache store implementation which stores data in Redis.
  #
  # ```crystal
  # cache = Cache::RedisStore(String, String).new(expires_in: 1.minute)
  # cache.fetch("today") do
  #   Time.utc.day_of_week
  # end
  # ```
  #
  # This assumes Redis was started with a default configuration, and is listening on localhost, port 6379.
  #
  # You can connect to Redis by instantiating the `Redis::Client` class.
  #
  # If you need to connect to a remote server or a different port, try:
  #
  # ```crystal
  # redis = Redis::Client.new(URI.parse("rediss://:my-secret-pw@10.0.1.1:6380/my-database"))
  # cache = Cache::RedisStore(String, String).new(expires_in: 1.minute, cache: redis)
  # ```
  struct RedisStore(K, V) < Store(K, V)
    @cache : Redis::Client

    def initialize(@expires_in : Time::Span, @cache = Redis::Client.new)
    end

    def write(key : K, value : V, *, expires_in = @expires_in)
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
      @cache.del(key) == 1_i64 ? true : false
    end

    def clear
      @cache.flushdb
    end
  end
end
