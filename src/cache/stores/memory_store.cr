require "../store"

module Cache
  # A cache store implementation which stores everything into memory in the
  # same process.
  struct MemoryStore(K, V) < Store(K, V)
    def fetch(key : K, &block)
      now = Time.utc_now
      entry = @cache[key]?

      if entry && now < entry.expires_in
        return entry.value
      end

      value = yield

      @cache[key] = Entry.new(value, now + @expires_in)
      value
    end
  end
end
