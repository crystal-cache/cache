require "./spec_helper"

describe Cache do
  context Cache::RedisStore do
    Spec.before_each do
      redis = Redis.new
      redis.del("foo")
    end

    it "initialize" do
      (Cache::RedisStore(String, String).new(expires_in: 12.hours)).should be_a(Cache::Store(String, String))
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

    it "don't fetch from cache if expired" do
      store = Cache::RedisStore(String, String).new(1.seconds)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")

      sleep 1

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

      sleep 1

      value = store.read("foo")
      value.should eq(nil)
    end
  end
end
