require "../store"

module Cache
  # A cache store implementation which stores everything into memory in the
  # same process.
  #
  # Cached data are compressed by default for String values. To turn off compression, pass `compress: false` to the initializer.
  #
  # ```
  # cache = Cache::MemoryStore(String).new(expires_in: 1.minute)
  # cache.fetch("today") do
  #   Time.utc.day_of_week
  # end
  # ```
  struct MemoryStore(V) < Store(V)
    def initialize(@expires_in : Time::Span, @compress : Bool = true)
      @cache = {} of String => Entry(V)
    end

    private def write_impl(key : String, value : V, *, expires_in = @expires_in)
      all_keys << key

      {% if V == String %}
        value = Cache::DataCompressor.deflate(value) if @compress
      {% end %}

      @cache[key] = Entry(V).new(value, expires_in)
    end

    private def read_impl(key : String)
      if entry = @cache[key]?
        if entry.expired?
          delete_impl(key)

          nil
        else
          value = entry.value

          {% if V == String %}
            value = Cache::DataCompressor.inflate(value) if @compress
          {% end %}

          value
        end
      else
        nil
      end
    end

    private def delete_impl(key : String) : Bool
      all_keys.delete(key)

      @cache.delete(key).nil? ? false : true
    end

    private def exists_impl(key : String) : Bool
      if entry = @cache[key]?
        if entry.expired?
          delete_impl(key)

          false
        else
          true
        end
      else
        false
      end
    end

    def clear
      clear_keys

      @cache.clear
    end
  end
end
