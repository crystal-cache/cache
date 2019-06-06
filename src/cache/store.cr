require "yaml"

module Cache
  # An abstract cache store class.
  #
  # There are multiple cache store implementations,
  # each having its own additional features.
  #
  # See the classes
  # under the `/src/cache/stores` directory, e.g.
  # All implementations should support method , `write`, `read`, `fetch`, and `delete`.
  abstract struct Store(K, V)
    @keys : Set(String) = Set(String).new

    property keys

    # Fetches data from the cache, using the given `key`. If there is data in the cache
    # with the given `key`, then that data is returned.
    #
    # If there is no such data in the cache, then a `block` will be passed the `key`
    # and executed in the event of a cache miss.
    # Setting `:expires_in` will set an expiration time on the cache.
    # All caches support auto-expiring content after a specified number of seconds.
    # This value can be specified as an option to the constructor (in which case all entries will be affected),
    # or it can be supplied to the `fetch` or `write` method to effect just one entry.
    #
    # ```crystal
    # cache = Cache::RedisStore(String, String).new(expires_in: 1.hours)
    # # Set a lower value for one entry
    # cache.fetch("today", expires_in: 10.minutes) do
    #   Time.utc.day_of_week
    # end
    # ```
    abstract def fetch(key : K, *, expires_in = @expires_in, &block)

    # Writes the `value` to the cache, with the `key`.
    #
    # Optional `expires_in` will set an expiration time on the `key`.
    #
    # Options are passed to the underlying cache implementation.
    abstract def write(key : K, value : V, *, expires_in = @expires_in)

    # Reads data from the cache, using the given `key`.
    #
    # If there is data in the cache with the given `key`, then that data is returned.
    # Otherwise, `nil` is returned.
    abstract def read(key : K)

    # Deletes an entry in the cache. Returns `true` if an entry is deleted.
    #
    # Options are passed to the underlying cache implementation.
    abstract def delete(key : K) : Bool

    # Deletes all entries from the cache.
    #
    # Options are passed to the underlying cache implementation.
    abstract def clear

    private def clear_keys
      @keys.clear
    end

    struct Entry(V)
      include YAML::Serializable

      @expires_at : Time

      getter value
      getter expires_at

      def initialize(@value : V, expires_in : Time::Span)
        @expires_at = Time.utc_now + expires_in
      end

      # Checks if the entry is expired.
      def expired?
        @expires_at && @expires_at <= Time.utc_now
      end
    end
  end
end

require "./stores/*"
