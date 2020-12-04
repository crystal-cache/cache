require "../store"
require "file_utils"

module Cache
  # A cache store implementation which stores everything on the filesystem.
  #
  # ```crystal
  # cache_path = "#{__DIR__}/cache"
  # store = Cache::FileStore(String, String).new(expires_in: 12.hours, cache_path: cache_path)
  # cache.fetch("today") do
  #   Time.utc.day_of_week
  # end
  # ```
  struct FileStore(K, V) < Store(K, V)
    EXCLUDED_DIRS = [".", ".."]

    property cache_path

    def initialize(@expires_in : Time::Span, @cache_path : String)
    end

    def write(key : K, value : V, *, expires_in = @expires_in)
      @keys << key

      file = File.join(@cache_path, key)
      entry = Entry(V).new(value, expires_in)

      ensure_cache_path(File.dirname(file))
      File.write(file, entry.to_yaml)
    end

    def read(key : K)
      entry = read_entry(key)

      if entry && !entry.expired?
        entry.value
      else
        nil
      end
    end

    def fetch(key : K, *, expires_in = @expires_in, &block)
      value = read(key)
      return value unless value.nil?

      value = yield

      write(key, value, expires_in: expires_in)
      value
    end

    def delete(key : K) : Bool
      @keys.delete(key)
      File.delete(File.join(@cache_path, key))

      true
    end

    def exists?(key : K) : Bool
      entry = read_entry(key)
      (entry && !entry.expired?) || false
    end

    def clear
      clear_keys

      root_dirs = Dir.entries(cache_path)
      root_dirs = root_dirs.reject { |f| EXCLUDED_DIRS.includes?(f) }

      files = root_dirs.map { |f| File.join(cache_path, f) }

      FileUtils.rm_r(files)
    end

    private def read_entry(key : K)
      file = File.join(@cache_path, key)

      return nil unless File.exists?(file)

      Entry(V).from_yaml(File.read(file))
    end

    # Make sure a file path's directories exist.
    private def ensure_cache_path(path)
      FileUtils.mkdir_p(path) unless File.exists?(path)
    end
  end
end
