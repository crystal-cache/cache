require "../store"
require "file_utils"

module Cache
  # A cache store implementation which stores everything on the filesystem.
  #
  # ```crystal
  # cache_path = "#{__DIR__}/cache"
  # store = Cache::FileStore(String, String).new(expires_in: 12.hours, cache_path: cache_path)
  # cache.fetch("today") do
  #   Time.now.day_of_week
  # end
  # ```
  struct FileStore(K, V) < Store(K, V)
    property cache_path

    def initialize(@expires_in : Time::Span, @cache_path : String)
    end

    def write(key : K, value : V, *, expires_in = @expires_in)
      @keys << key

      file = File.join(@cache_path, key)
      entry = Entry.new(value, expires_in)

      ensure_cache_path(File.dirname(file))
      File.write(file, entry.to_yaml)
    end

    def read(key : K)
      file = File.join(@cache_path, key)

      return nil unless File.exists?(file)

      entry = Entry(V).from_yaml(File.read(file))

      if entry && !entry.expired?
        entry.value
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
      File.delete(File.join(@cache_path, key))

      true
    end

    # Make sure a file path's directories exist.
    private def ensure_cache_path(path)
      FileUtils.mkdir_p(path) unless File.exists?(path)
    end
  end
end
