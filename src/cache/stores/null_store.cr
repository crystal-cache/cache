require "../store"

module Cache
  # A cache store implementation which doesn't actually store anything. Useful in
  # development and test environments where you don't want caching turned on but
  # need to go through the caching interface.
  struct NullStore(K, V) < Store(K, V)
    def initialize(@expires_in : Time::Span)
    end

    private def write_impl(key : K, value : V, *, expires_in = @expires_in)
      @keys << key
    end

    private def read_impl(key : K)
    end

    def delete(key : K) : Bool
      @keys.delete(key)

      true
    end

    def exists?(key : K) : Bool
      @keys.includes?(key)
    end

    def clear
      clear_keys
    end
  end
end
