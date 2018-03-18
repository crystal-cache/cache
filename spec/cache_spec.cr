require "./spec_helper"

describe Cache do
  context Cache::MemoryStore do
    it "initialize" do
      (Cache::MemoryStore(String, String).new(expires_in: 12.hours)).should be_a(Cache::Store(String, String))
    end

    it "write to cache first time" do
      store = Cache::MemoryStore(String, String).new(12.hours)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")
    end

    it "fetch from cache" do
      store = Cache::MemoryStore(String, String).new(12.hours)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")

      value = store.fetch("foo") { "baz" }
      value.should eq("bar")
    end

    it "don't fetch from cache if expires" do
      store = Cache::MemoryStore(String, String).new(1.seconds)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")

      sleep 1

      value = store.fetch("foo") { "baz" }
      value.should eq("baz")
    end

  end
end
