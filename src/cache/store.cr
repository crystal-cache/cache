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
    @keys : Set(K) = Set(K).new
    @namespace : String? = nil
    @expires_in : Time::Span = Time::Span::ZERO

    # Returns all keys in the cache, including expired ones.
    # Use #valid_keys for only non-expired keys.
    property keys

    # Returns only non-expired keys in the cache.
    def valid_keys : Set(K)
      @keys.select { |key| exists?(key) }.to_set
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
    # ```
    # cache = Cache::MemoryStore(String, String).new(expires_in: 1.hours)
    # # Set a lower value for one entry
    # cache.fetch("today", expires_in: 10.minutes) do
    #   Time.utc.day_of_week
    # end
    # ```
    def fetch(key : K, *, expires_in = @expires_in, &)
      value = read(key)
      return value unless value.nil?

      value = yield

      write(key, value, expires_in: expires_in)
      value
    end

    # :nodoc:
    def fetch(key : K)
      read(key)
    end

    # Writes the `value` to the cache, with the `key`.
    #
    # Optional `expires_in` will set an expiration time on the `key`.
    #
    # Options are passed to the underlying cache implementation.
    def write(key : K, value : V, *, expires_in = @expires_in)
      key = namespace_key(key)

      instrument(:write, key) do
        write_impl(key, value, expires_in: expires_in)
      end
    end

    # Reads data from the cache, using the given `key`.
    #
    # If there is data in the cache with the given `key`, then that data is returned.
    # Otherwise, `nil` is returned.
    def read(key : K)
      key = namespace_key(key)

      instrument(:read, key) do
        read_impl(key)
      end
    end

    def delete(key : K) : Bool
      key = namespace_key(key)

      instrument(:delete, key) do
        delete_impl(key)
      end
    end

    def exists?(key : K) : Bool
      key = namespace_key(key)

      exists_impl(key)
    end

    private def instrument(operation, key, &)
      Log.debug { "Cache #{operation}: #{key}" }

      yield
    end

    # Implementation of writing an entry.
    private abstract def write_impl(key : K, value : V, *, expires_in)

    # Implementation of reading an entry.
    # Returns the entry, if it existed, `nil` otherwise.
    private abstract def read_impl(key : K)

    # Deletes an entry in the cache. Returns `true` if an entry is deleted.
    #
    # Options are passed to the underlying cache implementation.
    private abstract def delete_impl(key : K) : Bool

    # Returns true if the cache contains an entry for the given key.
    #
    # Options are passed to the underlying cache implementation.
    private abstract def exists_impl(key : K) : Bool

    # Deletes all entries from the cache.
    #
    # Options are passed to the underlying cache implementation.
    abstract def clear

    private def clear_keys
      @keys.clear
    end

    private def cleanup_expired_keys
      @keys.reject! { |key| !exists?(key) }
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

    private def namespace_key(key : K) : String | K
      if @namespace
        "#{@namespace}:#{key}"
      else
        key
      end
    end
  end
end

require "./stores/*"
