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
      value.should be_false

      value = store.fetch("foo") { "bar" }
      value.should be_false
    end

    it "don't fetch from cache if expired" do
      freeze do |time|
        store = Cache::FileStore(String, String).new(1.seconds, cache_path: cache_path)

        value = store.fetch("foo") { "bar" }
        value.should eq("bar")

        Timecop.travel(time + 2.seconds)

        value = store.fetch("foo") { "baz" }
        value.should eq("baz")
      end
    end

    it "fetch with expires_in from cache" do
      freeze do |time|
        store = Cache::FileStore(String, String).new(1.seconds, cache_path: cache_path)

        value = store.fetch("foo", expires_in: 1.hours) { "bar" }
        value.should eq("bar")

        Timecop.travel(time + 2.seconds)

        value = store.fetch("foo") { "baz" }
        value.should eq("bar")
      end
    end

    it "don't fetch with expires_in from cache if expires" do
      freeze do |time|
        store = Cache::FileStore(String, String).new(12.hours, cache_path: cache_path)

        value = store.fetch("foo", expires_in: 1.seconds) { "bar" }
        value.should eq("bar")

        Timecop.travel(time + 2.seconds)

        value = store.fetch("foo") { "baz" }
        value.should eq("baz")
      end
    end

    it "write" do
      store = Cache::FileStore(String, String).new(12.hours, cache_path: cache_path)
      store.write("foo", "bar", expires_in: 1.minute)

      value = store.fetch("foo") { "baz" }
      value.should eq("bar")
    end

    it "read" do
      store = Cache::FileStore(String, String).new(12.hours, cache_path: cache_path)
      store.write("foo", "bar")

      value = store.read("foo")
      value.should eq("bar")
    end

    it "read nil if key does not exists" do
      store = Cache::FileStore(String, String).new(expires_in: 12.hours, cache_path: cache_path)

      value = store.read("foo")
      value.should be_nil
    end

    it "fetch without block" do
      store = Cache::FileStore(String, String).new(expires_in: 12.hours, cache_path: cache_path)
      store.write("foo", "bar")

      value = store.fetch("foo")
      value.should eq("bar")
    end

    it "set a custom expires_in value for one entry on write" do
      freeze do |time|
        store = Cache::FileStore(String, String).new(12.hours, cache_path: cache_path)
        store.write("foo", "bar", expires_in: 1.second)

        Timecop.travel(time + 2.seconds)

        File.exists?(File.join(cache_path, "foo")).should be_true
        store.keys.should be_empty

        value = store.read("foo")
        value.should be_nil

        File.exists?(File.join(cache_path, "foo")).should be_false
      end
    end

    it "delete from cache" do
      store = Cache::FileStore(String, String).new(12.hours, cache_path: cache_path)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")
      File.exists?(File.join(cache_path, "foo")).should be_true

      result = store.delete("foo")
      result.should be_true

      value = store.read("foo")
      value.should be_nil
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

    it "#exists?" do
      store = Cache::FileStore(String, String).new(12.hours, cache_path: cache_path)

      store.write("foo", "bar")

      store.exists?("foo").should be_true
      store.exists?("foz").should be_false
    end

    it "#exists? expires" do
      freeze do |time|
        store = Cache::FileStore(String, String).new(1.second, cache_path: cache_path)

        store.write("foo", "bar")

        Timecop.travel(time + 2.seconds)

        store.exists?("foo").should be_false
      end
    end

    it "#increment" do
      store = Cache::FileStore(String, Int32).new(12.hours, cache_path: cache_path)

      store.write("num", 1)
      store.increment("num", 1)

      value = store.read("num")

      value.should eq(2)
    end

    it "#decrement" do
      store = Cache::FileStore(String, Int32).new(12.hours, cache_path: cache_path)

      store.write("num", 2)
      store.decrement("num", 1)

      value = store.read("num")

      value.should eq(1)
    end

    context "with compression" do
      [false, true].each do |compress|
        context "with compress #{compress}" do
          it "compresses string values" do
            store = Cache::FileStore(String, String).new(expires_in: 12.hours, cache_path: cache_path, compress: compress)

            value = store.fetch("foo") { "bar" }
            value.should eq("bar")

            value = store.fetch("foo") { "baz" }
            value.should eq("bar")
          end

          it "does not compress non-string values" do
            store = Cache::FileStore(String, Int32).new(expires_in: 12.hours, cache_path: cache_path, compress: compress)

            value = store.fetch("foo") { 42 }
            value.should eq(42)

            value = store.fetch("foo") { 100 }
            value.should eq(42)
          end

          it "handles large string compression" do
            store = Cache::FileStore(String, String).new(expires_in: 12.hours, cache_path: cache_path, compress: compress)

            large_string = "x" * 1000
            value = store.fetch("large") { large_string }
            value.should eq(large_string)

            value = store.fetch("large") { "different" }
            value.should eq(large_string)
          end
        end
      end
    end
  end
end
