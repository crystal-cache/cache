require "../store"

module Cache
  # A cache store implementation which doesn't actually store anything. Useful in
  # development and test environments where you don't want caching turned on but
  # need to go through the caching interface.
  struct NullStore(K, V) < Store(K, V)
    def initialize(@expires_in : Time::Span)
    end

    def write(key : K, value : V, *, expires_in = @expires_in)
      @keys << key
    end

    def read(key : K)
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

      true
    end

    def clear
      clear_keys
    end
  end
end
