module Cache
  # An abstract cache store class.
  #
  # There are multiple cache store implementations,
  # each having its own additional features.
  #
  # See the classes
  # under the `/src/cache/stores` directory, e.g.
  # All implementations should support method `fetch`.
  abstract struct Store(K, V)
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
    #   Time.now.day_of_week
    # end
    # ```
    abstract def fetch(key : K, *, expires_in = @expires_in, &block)

    struct Entry(V)
      getter value
      getter expires_in

      def initialize(@value : V, @expires_in : Time)
      end
    end
  end
end

require "./stores/*"
