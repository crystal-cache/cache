require "../store"

module Cache
  # A cache store implementation which stores everything into memory in the
  # same process.
  #
  # ```crystal
  # cache = Cache::MemoryStore(String, String).new(expires_in: 1.minute)
  # cache.fetch("today") do
  #   Time.utc.day_of_week
  # end
  # ```
  struct MemoryStore(K, V) < Store(K, V)
    def initialize(@expires_in : Time::Span, @compress : Bool = true)
      @cache = {} of K => Entry(V)
    end

    def write(key : K, value : V, *, expires_in = @expires_in)
      @keys << key

      if @compress
        value = Cache::DataCompressor.deflate(value)
      end

      @cache[key] = Entry.new(value, expires_in)
    end

    def read(key : K)
      entry = @cache[key]?

      if entry && !entry.expired?
        if @compress
          Cache::DataCompressor.inflate(entry.value)
        else
          entry.value
        end
      else
        nil
      end
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

      @cache.delete(key).nil? ? false : true
    end

    def clear
      clear_keys

      @cache.clear
    end
  end
end
