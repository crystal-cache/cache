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
  end
end
