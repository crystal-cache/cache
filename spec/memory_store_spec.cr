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

    it "has keys" do
      store = Cache::MemoryStore(String, String).new(12.hours)

      value = store.fetch("foo") { "bar" }
      store.keys.should eq(Set{"foo"})
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

      sleep 2

      value = store.fetch("foo") { "baz" }
      value.should eq("baz")
    end

    it "fetch with expires_in from cache" do
      store = Cache::MemoryStore(String, String).new(1.seconds)

      value = store.fetch("foo", expires_in: 1.hours) { "bar" }
      value.should eq("bar")

      sleep 2

      value = store.fetch("foo") { "baz" }
      value.should eq("bar")
    end

    it "don't fetch with expires_in from cache if expires" do
      store = Cache::MemoryStore(String, String).new(12.hours)

      value = store.fetch("foo", expires_in: 1.seconds) { "bar" }
      value.should eq("bar")

      sleep 2

      value = store.fetch("foo") { "baz" }
      value.should eq("baz")
    end

    it "write" do
      store = Cache::MemoryStore(String, String).new(12.hours)
      store.write("foo", "bar", expires_in: 1.minute)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")
    end

    it "read" do
      store = Cache::MemoryStore(String, String).new(12.hours)
      store.write("foo", "bar")

      value = store.read("foo")
      value.should eq("bar")
    end

    it "set a custom expires_in value for one entry on write" do
      store = Cache::MemoryStore(String, String).new(12.hours)
      store.write("foo", "bar", expires_in: 1.second)

      sleep 2

      value = store.read("foo")
      value.should eq(nil)
    end

    it "delete from cache" do
      store = Cache::MemoryStore(String, String).new(12.hours)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")

      result = store.delete("foo")
      result.should eq(true)

      value = store.read("foo")
      value.should eq(nil)
      store.keys.should eq(Set(String).new)
    end
  end
end
