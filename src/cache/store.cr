module Cache
  # An abstract cache store class. There are multiple cache store implementations,
  # each having its own additional features.
  abstract struct Store(K, V)
    # Fetches data from the cache, using the given `key`. If there is data in the cache
    # with the given `key`, then that data is returned.
    #
    # If there is no such data in the cache, then a `block` will be passed the `key`
    # and executed in the event of a cache miss.
    abstract def fetch(key : K, &block)

    struct Entry(V)
      getter value
      getter expires_in

      def initialize(@value : V, @expires_in : Time)
      end
    end
  end
end

require "./stores/*"
