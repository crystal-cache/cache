require "./entry"

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

    # Writes the `value` to the cache, with the `key`.
    #
    # Optional `expires_in` will set an expiration time on the `key`.
    #
    # Options are passed to the underlying cache implementation.
    def write(key : K, value : V, *, expires_in = @expires_in)
      instrument(:write, key) do
        write_entry(key, value, expires_in: expires_in)
      end
    end

    # Reads data from the cache, using the given `key`.
    #
    # If there is data in the cache with the given `key`, then that data is returned.
    # Otherwise, `nil` is returned.
    def read(key : K)
      instrument(:read, key) do
        read_entry(key)
      end
    end

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
    def fetch(key : K, *, expires_in = @expires_in, &block)
      value = read(key)
      return value unless value.nil?

      value = yield

      write(key, value, expires_in: expires_in)
      value
    end

    private def instrument(operation, key, &block)
      Log.debug { "Cache #{operation}: #{key}" }

      yield
    end

    private abstract def write_entry(key : K, value : V, *, expires_in)
    private abstract def read_entry(key : K)

    # Deletes an entry in the cache. Returns `true` if an entry is deleted.
    #
    # Options are passed to the underlying cache implementation.
    abstract def delete(key : K) : Bool

    # Returns true if the cache contains an entry for the given key.
    #
    # Options are passed to the underlying cache implementation.
    abstract def exists?(key : K) : Bool

    # Deletes all entries from the cache.
    #
    # Options are passed to the underlying cache implementation.
    abstract def clear

    private def clear_keys
      @keys.clear
    end

    # Increment an integer value in the cache.
    def increment(key : K, amount = 1)
      if num = read(key)
        return unless num.is_a?(Int)

        num += amount
        write(key, num)
      end
    end

    # Decrement an integer value in the cache.
    def decrement(key : K, amount = 1)
      if num = read(key)
        return unless num.is_a?(Int)

        num -= amount
        write(key, num)
      end
    end
  end
end

require "./stores/*"
