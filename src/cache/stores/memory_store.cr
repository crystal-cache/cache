require "../store"

module Cache
  # A cache store implementation which stores everything into memory in the
  # same process.
  #
  # ```crystal
  # cache = Cache::MemoryStore(String, String).new(expires_in: 1.minute)
  # cache.fetch("today") do
  #   Time.now.day_of_week
  # end
  # ```
  struct MemoryStore(K, V) < Store(K, V)
    def initialize(@expires_in : Time::Span)
      @cache = {} of K => Entry(V)
    end

    def write(key : K, value : V, *, expires_in = @expires_in)
      @expires_in = expires_in
      now = Time.utc_now

      @cache[key] = Entry.new(value, now + expires_in)
    end

    def read(key : K)
      now = Time.utc_now
      entry = @cache[key]?

      if entry && now < entry.expires_in
        entry.value
      else
        nil
      end
    end

    def fetch(key : K, &block)
      value = read(key)
      return value if value

      value = yield

      write(key, value)
      value
    end
  end
end
