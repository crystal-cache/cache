require "yaml"

module Cache
  # Used to represent cache entries. Cache entries have a value, and expiration time.
  struct Entry(V)
    include YAML::Serializable

    @expires_at : Time

    getter value
    getter expires_at

    def initialize(@value : V, expires_in : Time::Span = Time::Span::ZERO)
      @expires_at = Time.utc + expires_in
    end

    # Checks if the entry is expired.
    def expired?
      @expires_at && @expires_at <= Time.utc
    end
  end
end
