require "./spec_helper"

describe Cache do
  context Cache::RedisStore do
    Spec.before_each do
      redis = Redis.new
      redis.flushdb
    end

    it "initialize" do
      store = Cache::RedisStore(String, String).new(expires_in: 12.hours)

      store.should be_a(Cache::Store(String, String))
    end

    it "initialize with Redis" do
      redis = Redis.new(host: "localhost", port: 6379)
      store = Cache::RedisStore(String, String).new(expires_in: 12.hours, cache: redis)

      store.should be_a(Cache::Store(String, String))
    end

    it "initialize with Redis::PooledClient" do
      redis = Redis::PooledClient.new(host: "localhost", port: 6379, pool_size: 20)
      store = Cache::RedisStore(String, String).new(expires_in: 12.hours, cache: redis)

      store.should be_a(Cache::Store(String, String))
    end

    it "write to cache first time" do
      store = Cache::RedisStore(String, String).new(12.hours)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")
    end

    it "fetch from cache" do
      store = Cache::RedisStore(String, String).new(12.hours)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")

      value = store.fetch("foo") { "baz" }
      value.should eq("bar")
    end

    it "fetch from cache with custom Redis" do
      redis = Redis.new(host: "localhost", port: 6379)
      store = Cache::RedisStore(String, String).new(expires_in: 12.hours, cache: redis)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")

      value = store.fetch("foo") { "baz" }
      value.should eq("bar")
    end

    it "don't fetch from cache if expired" do
      store = Cache::RedisStore(String, String).new(1.seconds)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")

      sleep 2

      value = store.fetch("foo") { "baz" }
      value.should eq("baz")
    end

    it "fetch with expires_in from cache" do
      store = Cache::RedisStore(String, String).new(1.seconds)

      value = store.fetch("foo", expires_in: 1.hours) { "bar" }
      value.should eq("bar")

      sleep 2

      value = store.fetch("foo") { "baz" }
      value.should eq("bar")
    end

    it "don't fetch with expires_in from cache if expires" do
      store = Cache::RedisStore(String, String).new(12.hours)

      value = store.fetch("foo", expires_in: 1.seconds) { "bar" }
      value.should eq("bar")

      sleep 2

      value = store.fetch("foo") { "baz" }
      value.should eq("baz")
    end

    it "write" do
      store = Cache::RedisStore(String, String).new(12.hours)
      store.write("foo", "bar", expires_in: 1.minute)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")
    end

    it "read" do
      store = Cache::RedisStore(String, String).new(12.hours)
      store.write("foo", "bar")

      value = store.read("foo")
      value.should eq("bar")
    end

    it "set a custom expires_in value for entry on write" do
      store = Cache::RedisStore(String, String).new(12.hours)
      store.write("foo", "bar", expires_in: 1.second)

      sleep 2

      value = store.read("foo")
      value.should eq(nil)
    end

    it "delete from cache" do
      store = Cache::RedisStore(String, String).new(12.hours)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")

      result = store.delete("foo")
      result.should eq(true)

      value = store.read("foo")
      value.should eq(nil)
      store.keys.should eq(Set(String).new)
    end

    it "deletes all items from the cache" do
      store = Cache::RedisStore(String, String).new(12.hours)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")

      store.clear

      value = store.read("foo")
      value.should eq(nil)
      store.keys.should be_empty
    end

    it "#exists?" do
      store = Cache::RedisStore(String, String).new(12.hours)

      store.write("foo", "bar")

      store.exists?("foo").should eq(true)
      store.exists?("foz").should eq(false)
    end

    it "#exists? expires" do
      store = Cache::RedisStore(String, String).new(1.second)

      store.write("foo", "bar")

      sleep 2

      store.exists?("foo").should eq(false)
    end

    it "#increment" do
      store = Cache::RedisStore(String, Int32).new(12.hours)

      store.write("num", 1)
      store.increment("num", 1)

      value = store.read("num")

      value.should eq("2")
    end

    it "#decrement" do
      store = Cache::RedisStore(String, Int32).new(12.hours)

      store.write("num", 2)
      store.decrement("num", 1)

      value = store.read("num")

      value.should eq("1")
    end
  end
end
