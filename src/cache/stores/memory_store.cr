require "../store"

module Cache
  # A cache store implementation which stores everything into memory in the
  # same process.
  #
  # Cached data are compressed by default. To turn off compression, pass `compress: false` to the initializer.
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

      {% if V.is_a?(String) %}
        value = Cache::DataCompressor.deflate(value) if @compress
      {% end %}

      @cache[key] = Entry(V).new(value, expires_in)
    end

    def read(key : K)
      entry = @cache[key]?
      value = nil

      if entry && !entry.expired?
        value = entry.value

        {% if V.is_a?(String) %}
          value = Cache::DataCompressor.inflate(value) if @compress
        {% end %}
      end

      value
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
