require "./spec_helper"

describe Cache::Entry do
  describe "#expired?" do
    it "returns true if the entry is expired" do
      entry = Cache::Entry.new("foobar", expires_in: -2.minutes)
      entry.expired?.should be_true
    end

    it "returns false if the entry is not expired" do
      entry = Cache::Entry.new("foobar", expires_in: 2.minutes)
      entry.expired?.should be_false
    end

    it "returns true if the entry has no expires_in" do
      entry = Cache::Entry.new("foobar")
      entry.expired?.should be_true
    end
  end
end
