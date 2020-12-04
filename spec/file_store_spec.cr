require "./spec_helper"

describe Cache do
  context Cache::FileStore do
    cache_path = "#{__DIR__}/cache"

    Spec.after_each do
      FileUtils.rm_rf(cache_path)
    end

    it "initialize" do
      store = Cache::FileStore(String, String).new(expires_in: 12.hours, cache_path: cache_path)

      store.should be_a(Cache::Store(String, String))
      store.cache_path.should end_with("/spec/cache")
    end

    it "write to cache first time" do
      store = Cache::FileStore(String, String).new(12.hours, cache_path: cache_path)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")
    end

    it "has keys" do
      store = Cache::FileStore(String, String).new(12.hours, cache_path: cache_path)

      store.fetch("foo") { "bar" }
      store.keys.should eq(Set{"foo"})
    end

    it "fetch from cache" do
      store = Cache::FileStore(String, String).new(12.hours, cache_path: cache_path)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")

      value = store.fetch("foo") { "baz" }
      value.should eq("bar")
    end

    it "fetch from cache with generic types values" do
      store = Cache::FileStore(String, String | Int32).new(expires_in: 12.hours, cache_path: cache_path)

      value = store.fetch("string") { "bar" }
      value.should eq("bar")

      value = store.fetch("integer") { 13 }
      value.should eq(13)
    end

    it "fetch from cache with false values" do
      store = Cache::FileStore(String, String | Bool).new(expires_in: 12.hours, cache_path: cache_path)

      value = store.fetch("foo") { false }
      value.should eq(false)

      value = store.fetch("foo") { "bar" }
      value.should eq(false)
    end

    it "don't fetch from cache if expired" do
      store = Cache::FileStore(String, String).new(1.seconds, cache_path: cache_path)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")

      sleep 2

      value = store.fetch("foo") { "baz" }
      value.should eq("baz")
    end

    it "fetch with expires_in from cache" do
      store = Cache::FileStore(String, String).new(1.seconds, cache_path: cache_path)

      value = store.fetch("foo", expires_in: 1.hours) { "bar" }
      value.should eq("bar")

      sleep 2

      value = store.fetch("foo") { "baz" }
      value.should eq("bar")
    end

    it "don't fetch with expires_in from cache if expires" do
      store = Cache::FileStore(String, String).new(12.hours, cache_path: cache_path)

      value = store.fetch("foo", expires_in: 1.seconds) { "bar" }
      value.should eq("bar")

      sleep 2

      value = store.fetch("foo") { "baz" }
      value.should eq("baz")
    end

    it "write" do
      store = Cache::FileStore(String, String).new(12.hours, cache_path: cache_path)
      store.write("foo", "bar", expires_in: 1.minute)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")
    end

    it "read" do
      store = Cache::FileStore(String, String).new(12.hours, cache_path: cache_path)
      store.write("foo", "bar")

      value = store.read("foo")
      value.should eq("bar")
    end

    it "set a custom expires_in value for one entry on write" do
      store = Cache::FileStore(String, String).new(12.hours, cache_path: cache_path)
      store.write("foo", "bar", expires_in: 1.second)

      sleep 2

      value = store.read("foo")
      value.should eq(nil)
    end

    it "delete from cache" do
      store = Cache::FileStore(String, String).new(12.hours, cache_path: cache_path)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")
      File.exists?(File.join(cache_path, "foo")).should be_true

      result = store.delete("foo")
      result.should eq(true)

      value = store.read("foo")
      value.should eq(nil)
      File.exists?(File.join(cache_path, "foo")).should be_false
      store.keys.should be_empty
    end

    it "deletes all items from the cache" do
      store = Cache::FileStore(String, String).new(12.hours, cache_path: cache_path)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")
      File.exists?(File.join(cache_path, "foo")).should be_true

      store.clear

      File.exists?(File.join(cache_path, "foo")).should be_false
      store.keys.should be_empty
    end
  end
end
