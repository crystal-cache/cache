require "../store"
require "file_utils"

module Cache
  # A cache store implementation which stores everything on the filesystem.
  #
  # Cached data are not compressed by default for String values. To enable compression, pass `compress: true` to the initializer.
  #
  # ```
  # cache_path = "#{__DIR__}/cache"
  # store = Cache::FileStore(String).new(expires_in: 12.hours, cache_path: cache_path)
  # cache.fetch("today") do
  #   Time.utc.day_of_week
  # end
  # ```
  struct FileStore(V) < Store(V)
    EXCLUDED_DIRS = [".", ".."]

    property cache_path

    def initialize(@expires_in : Time::Span, @cache_path : String, @compress : Bool = false)
    end

    private def write_impl(key : String, value : V, *, expires_in = @expires_in)
      all_keys << key

      {% if V == String %}
        value = Cache::DataCompressor.deflate(value) if @compress
      {% end %}

      file = key_file(key)
      entry = Entry(V).new(value, expires_in)

      ensure_cache_path(File.dirname(file))
      File.write(file, entry.to_yaml)
    end

    private def read_impl(key : String)
      if entry = entry_for(key)
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
      File.delete(key_file(key))

      true
    end

    private def exists_impl(key : String) : Bool
      if entry = entry_for(key)
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

      root_dirs = Dir.entries(cache_path)
      root_dirs = root_dirs.reject { |f| EXCLUDED_DIRS.includes?(f) }

      files = root_dirs.map { |f| File.join(cache_path, f) }

      FileUtils.rm_r(files)
    end

    private def entry_for(key : String)
      file = key_file(key)

      return nil unless File.exists?(file)

      Entry(V).from_yaml(File.read(file))
    end

    # Make sure a file path's directories exist.
    private def ensure_cache_path(path)
      FileUtils.mkdir_p(path) unless File.exists?(path)
    end

    private def key_file(key : String)
      File.join(@cache_path, key.to_s)
    end
  end
end
