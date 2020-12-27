require "./spec_helper"

describe Cache::Log do
  it "logging" do
    IO.pipe do |read, write|
      log_backend = Log::IOBackend.new(write)
      Log.builder.bind "cache.*", :debug, log_backend

      store = Cache::MemoryStore(String, String).new(expires_in: 1.second)

      store.fetch("foo") { "bar" }

      read.gets.should match(/DEBUG - cache: Cache read: foo/)
      read.gets.should match(/DEBUG - cache: Cache write: foo/)
    end

    Log.builder.clear
  end
end
