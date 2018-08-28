class Redis
  module Commands
    def flushdb
      string_command(["FLUSHDB"])
    end
  end
end
