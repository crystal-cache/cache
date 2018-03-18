module Cache
  # An abstract cache store class. There are multiple cache store implementations,
  # each having its own additional features.
  #
  # ```crystal
  # cache = Cache::MemoryStore(String, String).new(expires_in: 1.minute)
  # cache.fetch("today") do
  #   Time.now.day_of_week
  # end
  # ```
  abstract struct Store(K, V)
    def initialize(@expire_time : Time::Span)
      @cache = {} of K => Entry(V)
    end

    # Fetches data from the `cache`, using the given `key`. If there is data in the `cache`
    # with the given `key`, then that data is returned.
    #
    # If there is no such data in the `cache`, then a `block` will be passed the `key`
    # and executed in the event of a cache miss.
    abstract def fetch(key : K, &block)
  end

  struct Entry(V)
    getter value
    getter expire_time

    def initialize(@value : V, @expire_time : Time)
    end
  end
end

require "./stores/*"
