require "./spec_helper"

describe Cache do
  context Cache::NullStore do
    it "initialize" do
      store = Cache::NullStore(String).new(expires_in: 12.hours)

      store.should be_a(Cache::Store(String))
    end

    it "fetch" do
      store = Cache::NullStore(String).new(12.hours)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")
    end

    it "fetch with expires_in" do
      store = Cache::NullStore(String).new(12.hours)

      value = store.fetch("foo", expires_in: 3.hours) { "bar" }
      value.should eq("bar")
    end

    it "delete from cache" do
      store = Cache::NullStore(String).new(12.hours)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")

      result = store.delete("foo")
      result.should be_true

      value = store.read("foo")
      value.should be_nil
    end

    it "deletes all items from the cache" do
      store = Cache::NullStore(String).new(12.hours)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")

      store.clear
    end
  end
end
