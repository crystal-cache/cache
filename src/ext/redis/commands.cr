module Redis
  module Commands
    # Remove all keys from the current database.
    def flushdb
      run({"flushdb"})
    end
  end
end
