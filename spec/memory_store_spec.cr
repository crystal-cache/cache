require "./spec_helper"

describe Cache do
  context Cache::MemoryStore do
    context "initialize" do
      it "String values" do
        store = Cache::MemoryStore(String).new(expires_in: 12.hours)

        store.should be_a(Cache::Store(String))
      end

      it "Integer values" do
        store = Cache::MemoryStore(Int32).new(expires_in: 12.hours)

        store.should be_a(Cache::Store(Int32))

        store.fetch("foo") { 42 }
        store.fetch("bar") { 100 }
        store.read("foo").should eq(42)
        store.read("bar").should eq(100)
      end
    end

    [true, false].each do |compress|
      context "with compress #{compress}" do
        it "write to cache first time" do
          store = Cache::MemoryStore(String).new(expires_in: 12.hours, compress: compress)

          value = store.fetch("foo") { "bar" }
          value.should eq("bar")
        end

        it "fetch from cache" do
          store = Cache::MemoryStore(String).new(expires_in: 12.hours, compress: compress)

          value = store.fetch("foo") { "bar" }
          value.should eq("bar")

          value = store.fetch("foo") { "baz" }
          value.should eq("bar")
        end

        it "fetch from cache with generic types values" do
          store = Cache::MemoryStore(String | Int32).new(expires_in: 12.hours, compress: compress)

          value = store.fetch("string") { "bar" }
          value.should eq("bar")

          value = store.fetch("integer") { 13 }
          value.should eq(13)
        end

        it "fetch from cache with false values" do
          store = Cache::MemoryStore(String | Bool).new(expires_in: 12.hours, compress: compress)

          value = store.fetch("foo") { false }
          value.should be_false

          value = store.fetch("foo") { "bar" }
          value.should be_false
        end

        it "don't fetch from cache if expires" do
          freeze do |time|
            store = Cache::MemoryStore(String).new(expires_in: 1.seconds, compress: compress)

            value = store.fetch("foo") { "bar" }
            value.should eq("bar")

            Timecop.travel(time + 2.seconds)

            value = store.fetch("foo") { "baz" }
            value.should eq("baz")
          end
        end

        it "fetch with expires_in from cache" do
          freeze do |time|
            store = Cache::MemoryStore(String).new(expires_in: 1.seconds, compress: compress)

            value = store.fetch("foo", expires_in: 1.hours) { "bar" }
            value.should eq("bar")

            Timecop.travel(time + 2.seconds)

            value = store.fetch("foo") { "baz" }
            value.should eq("bar")
          end
        end

        it "don't fetch with expires_in from cache if expires" do
          freeze do |time|
            store = Cache::MemoryStore(String).new(expires_in: 12.hours, compress: compress)

            value = store.fetch("foo", expires_in: 1.seconds) { "bar" }
            value.should eq("bar")

            Timecop.travel(time + 2.seconds)

            value = store.fetch("foo") { "baz" }
            value.should eq("baz")
          end
        end

        it "write" do
          store = Cache::MemoryStore(String).new(expires_in: 12.hours, compress: compress)
          store.write("foo", "bar", expires_in: 1.minute)

          value = store.fetch("foo") { "baz" }
          value.should eq("bar")
        end

        it "read" do
          store = Cache::MemoryStore(String).new(expires_in: 12.hours, compress: compress)
          store.write("foo", "bar")

          value = store.read("foo")
          value.should eq("bar")
        end

        it "read nil if key does not exists" do
          store = Cache::MemoryStore(String).new(expires_in: 12.hours, compress: compress)

          value = store.read("foo")
          value.should be_nil
        end

        it "fetch without block" do
          store = Cache::MemoryStore(String).new(expires_in: 12.hours, compress: compress)
          store.write("foo", "bar")

          value = store.fetch("foo")
          value.should eq("bar")
        end

        it "set a custom expires_in value for one entry on write" do
          freeze do |time|
            store = Cache::MemoryStore(String).new(expires_in: 12.hours, compress: compress)
            store.write("foo", "bar", expires_in: 1.second)

            Timecop.travel(time + 2.seconds)

            value = store.read("foo")
            value.should be_nil
          end
        end

        it "delete from cache" do
          store = Cache::MemoryStore(String).new(expires_in: 12.hours, compress: compress)

          value = store.fetch("foo") { "bar" }
          value.should eq("bar")

          result = store.delete("foo")
          result.should be_true

          value = store.read("foo")
          value.should be_nil
        end

        it "deletes all items from the cache" do
          store = Cache::MemoryStore(String).new(expires_in: 12.hours, compress: compress)

          value = store.fetch("foo") { "bar" }
          value.should eq("bar")

          store.clear

          value = store.read("foo")
          value.should be_nil
        end

        it "#exists?" do
          store = Cache::MemoryStore(String).new(expires_in: 12.hours, compress: compress)

          store.write("foo", "bar")

          store.exists?("foo").should be_true
          store.exists?("foz").should be_false
        end

        it "#exists? expires" do
          freeze do |time|
            store = Cache::MemoryStore(String).new(expires_in: 1.second, compress: compress)

            store.write("foo", "bar")

            Timecop.travel(time + 2.seconds)

            store.exists?("foo").should be_false
          end
        end

        it "#increment" do
          store = Cache::MemoryStore(Int32).new(expires_in: 12.hours, compress: compress)

          store.write("num", 1)
          store.increment("num", 1)

          value = store.read("num")

          value.should eq(2)
        end

        it "#decrement" do
          store = Cache::MemoryStore(Int32).new(expires_in: 12.hours, compress: compress)

          store.write("num", 2)
          store.decrement("num", 1)

          value = store.read("num")

          value.should eq(1)
        end
      end
    end

    context "with Hash as value" do
      [true, false].each do |compress|
        context "with compress #{compress}" do
          it "fetch from cache" do
            store = Cache::MemoryStore(Hash(String, String | Int32))
              .new(expires_in: 30.seconds, compress: compress)

            data = {
              "a" => 1,
              "b" => "foo",
            }

            new_data = {
              "a" => 2,
              "b" => "bar",
            }

            value = store.fetch("data_key") { data }
            value.should eq(data)

            value = store.fetch("data_key") { new_data }
            value.should eq(data)
          end

          it "write and read" do
            store = Cache::MemoryStore(Hash(String, String | Int32))
              .new(expires_in: 30.seconds, compress: compress)

            data = {
              "a" => 1,
              "b" => "bla",
            }

            store.write("data_key", data)

            result = store.read("data_key")
            result.should eq(data)
          end
        end
      end
    end
  end
end
