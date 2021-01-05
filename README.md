# Caché

A key/value store where pairs can expire after a specified interval

[![Build Status](https://img.shields.io/travis/crystal-cache/cache.svg?style=flat)](https://travis-ci.org/crystal-cache/cache)
[![GitHub release](https://img.shields.io/github/release/crystal-cache/cache.svg)](https://github.com/crystal-cache/cache/releases)
[![License](https://img.shields.io/github/license/crystal-cache/cache.svg)](https://github.com/crystal-cache/cache/blob/master/LICENSE)

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  cache:
    github: crystal-cache/cache
```

## Example

Caching means to store content generated during the request-response cycle
and to reuse it when responding to similar requests.

The first time the result is returned from the query it is stored in the query cache (in memory)
and the second time it's pulled from memory.

Memory cache can store any serializable Crystal objects.

Next example show how to get a single Github user and cache the result in memory.

```crystal
require "http/client"
require "json"
require "cache"

cache = Cache::MemoryStore(String, String).new(expires_in: 30.minutes)
github_client = HTTP::Client.new(URI.parse("https://api.github.com"))

# Define how an object is mapped to JSON.
class User
  include JSON::Serializable

  property login : String
  property id : Int32
end

username = "crystal-lang"

# First request.
# Getting data from Github and write it to cache.
user_json = cache.fetch("user_#{username}") do
  response = github_client.get("/users/#{username}")
  User.from_json(response.body).to_json
end

user = User.from_json(user_json)
user.id # => 6539796

# Second request.
# Getting data from cache.
user_json = cache.fetch("user_#{username}") do
  response = github_client.get("/users/#{username}")
  User.from_json(response.body).to_json
end

user = User.from_json(user_json)
user.id # => 6539796
```

## Usage

### Available stores

* [x] Null store
* [x] Memory
* [x] Filesystem

There are multiple cache store implementations,
each having its own additional features. See the classes
under the `/src/cache/stores` directory, e.g.

### Third-party store implementations

* [redis_cache](https://github.com/crystal-cache/postgres_cache)
* [memcached_cache](https://github.com/crystal-cache/memcached_cache)
* [postgres_cache](https://github.com/crystal-cache/postgres_cache)

### Commands

All store's implementations should support:

* `fetch`
* `write`
* `read`
* `delete`
* `clear`

#### fetch

Fetches data from the cache, using the given `key`. If there is data in the cache
with the given `key`, then that data is returned.

If there is no such data in the cache, then a `block` will be passed the `key`
and executed in the event of a cache miss.

Setting `:expires_in` will set an expiration time on the cache.
All caches support auto-expiring content after a specified number of seconds.
This value can be specified as an option to the constructor (in which case all entries will be affected),
or it can be supplied to the `fetch` or `write` method to effect just one entry.

#### write

Writes the `value` to the cache, with the `key`.

Optional `expires_in` will set an expiration time on the `key`.

> Options are passed to the underlying cache implementation.

```crystal
store = Cache::MemoryStore(String, String).new(12.hours)

store.write("foo", "bar")
```

#### read

Reads data from the cache, using the given `key`.

If there is data in the cache with the given `key`, then that data is returned.
Otherwise, `nil` is returned.

```crystal
store = Cache::MemoryStore(String, String).new(12.hours)
store.write("foo", "bar")

store.read("foo") # => "bar"
```

#### delete

Deletes an entry in the cache. Returns `true` if an entry is deleted.

> Options are passed to the underlying cache implementation.

```crystal
store = Cache::MemoryStore(String, String).new(12.hours)

store.write("foo", "bar")
store.read("foo") # => "bar"

store.delete("foo") # => true
store.read("foo") # => nil
```

#### clear

Deletes all items from the cache.

> Options are passed to the underlying cache implementation.

```crystal
store = Cache::MemoryStore(String, String).new(12.hours)

store.write("foo", "bar")
store.read("foo") # => "bar"

store.clear
store.read("foo") # => nil
```

### Memory

A cache store implementation which stores everything into memory in the
same process.

Can store any serializable Crystal object.

```crystal
cache = Cache::MemoryStore(String, Hash(String | Int32)).new(expires_in: 1.minute)
cache.fetch("data_key") do
  {"name" => "John", "age" => 18}
end
```

Cached data for `MemoryStore(String, String)` are compressed by default.
To turn off compression, pass `compress: false` to the initializer.

For another type of keys `compress` option ignored.

```crystal
cache = Cache::MemoryStore(String, String).new(expires_in: 1.minute, compress: false)
cache.fetch("today") do
  Time.utc.day_of_week
end
```

### Filesystem

A cache store implementation which stores everything on the filesystem.

```crystal
cache_path = "#{__DIR__}/cache"

cache = Cache::FileStore(String, String).new(expires_in: 12.hours, cache_path: cache_path)

cache.fetch("today") do
  Time.utc.day_of_week
end
```

### Null store

A cache store implementation which doesn't actually store anything. Useful in
development and test environments where you don't want caching turned on but
need to go through the caching interface.

```crystal
cache = Cache::NullStore(String, String).new(expires_in: 1.minute)
cache.fetch("today") do
  Time.utc.day_of_week
end
```

## Logging

For activation, simply setup the log to `:debug` level:

```crystal
Log.builder.bind "cache.*", :debug, Log::IOBackend.new
```

## Contributing

1. Fork it (<https://github.com/crystal-cache/cache/fork>)
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

* [mamantoha](https://github.com/mamantoha) Anton Maminov - creator, maintainer
