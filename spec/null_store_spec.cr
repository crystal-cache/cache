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

    it "returns the value from write" do
      store = Cache::NullStore(String).new(12.hours)

      store.write("foo", "bar").should eq("bar")
      store.read("foo").should be_nil
    end

    it "delete from cache" do
      store = Cache::NullStore(String).new(12.hours)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")

      result = store.delete("foo")
      result.should be_false

      value = store.read("foo")
      value.should be_nil
    end

    it "does not report entries as existing" do
      store = Cache::NullStore(String).new(12.hours)

      store.write("foo", "bar")

      store.exists?("foo").should be_false
      store.keys.should be_empty
    end

    it "returns false when deleting a missing key" do
      store = Cache::NullStore(String).new(12.hours)

      store.delete("missing").should be_false
    end

    it "deletes all items from the cache" do
      store = Cache::NullStore(String).new(12.hours)

      value = store.fetch("foo") { "bar" }
      value.should eq("bar")

      store.clear
    end
  end
end
