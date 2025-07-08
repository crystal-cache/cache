require "../store"

module Cache
  # A cache store implementation which stores everything into memory in the
  # same process.
  #
  # Cached data are compressed by default. To turn off compression, pass `compress: false` to the initializer.
  #
  # ```
  # cache = Cache::MemoryStore(String, String).new(expires_in: 1.minute)
  # cache.fetch("today") do
  #   Time.utc.day_of_week
  # end
  # ```
  struct MemoryStore(K, V) < Store(K, V)
    def initialize(@expires_in : Time::Span, @compress : Bool = true)
      @cache = {} of K => Entry(V)
    end

    private def write_impl(key : K, value : V, *, expires_in = @expires_in)
      all_keys << key

      {% if V.is_a?(String) %}
        value = Cache::DataCompressor.deflate(value) if @compress
      {% end %}

      @cache[key] = Entry(V).new(value, expires_in)
    end

    private def read_impl(key : K)
      entry = @cache[key]?

      if entry && !entry.expired?
        value = entry.value

        {% if V.is_a?(String) %}
          value = Cache::DataCompressor.inflate(value) if @compress
        {% end %}

        value
      else
        all_keys.delete(key) if entry && entry.expired?

        nil
      end
    end

    private def delete_impl(key : K) : Bool
      all_keys.delete(key)

      @cache.delete(key).nil? ? false : true
    end

    private def exists_impl(key : K) : Bool
      entry = @cache[key]?

      if entry && !entry.expired?
        true
      else
        all_keys.delete(key) if entry && entry.expired?

        false
      end
    end

    def clear
      clear_keys

      @cache.clear
    end
  end
end
