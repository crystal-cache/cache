require "./spec_helper"

describe Cache do
  context Cache::RedisStore do
    Spec.before_each do
      redis = Redis.new
      redis.del("foo")
    end

    it "initialize" do
      store = Cache::RedisStore(String, String).new(expires_in: 12.hours)
      store.should be_a(Cache::Store(String, String))
    end

    it "initialize with redis" do
      redis = Redis.new(host: "localhost", port: 6379)
      (Cache::RedisStore(String, String).new(expires_in: 12.hours, cache: redis)).should be_a(Cache::Store(String, String))
    end

    it "has keys" do
      store = Cache::RedisStore(String, String).new(12.hours)

      value = store.fetch("foo") { "bar" }
      store.keys.should eq(Set{"foo"})
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
  end
end
