require "./spec_helper"

describe Cache do
  context Cache::NullStore do
    it "initialize" do
      (Cache::NullStore(String, String).new(expires_in: 12.hours)).should be_a(Cache::Store(String, String))
    end

    it "fetch" do
      store = Cache::NullStore(String, String).new(12.hours)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")
    end

    it "fetch with expires_in" do
      store = Cache::NullStore(String, String).new(12.hours)

      value = store.fetch("foo", expires_in: 3.hours) { "bar" }
      value.should eq("bar")
    end

    it "has keys" do
      store = Cache::NullStore(String, String).new(12.hours)

      value = store.fetch("foo") { "bar" }
      store.keys.should eq(Set{"foo"})
    end

    it "delete from cache" do
      store = Cache::NullStore(String, String).new(12.hours)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")

      store.delete("foo")

      value = store.read("foo")
      value.should eq(nil)
      store.keys.should eq(Set(String).new)
    end
  end
end
