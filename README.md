# Caché

A key/value store where pairs can expire after a specified interval

[![Build Status](http://img.shields.io/travis/mamantoha/cache.svg?style=flat)](https://travis-ci.org/mamantoha/cache)
[![GitHub release](https://img.shields.io/github/release/mamantoha/cache.svg)](https://github.com/mamantoha/cache/releases)
[![License](https://img.shields.io/github/license/mamantoha/cache.svg)](https://github.com/mamantoha/cache/blob/master/LICENSE)

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  cache:
    github: mamantoha/cache
```

## Usage

### Available stores

* [x] Null store
* [x] Memory
* [x] Redis
* [ ] Memcached ([#2](https://github.com/mamantoha/cache/issues/2))

```crystal
require "cache"
```

There are multiple cache store implementations,
each having its own additional features. See the classes
under the `/src/cache/stores` directory, e.g.

All implementations should support method `fetch`.

Fetches data from the cache, using the given `key`. If there is data in the cache
with the given `key`, then that data is returned.

If there is no such data in the cache, then a `block` will be passed the `key`
and executed in the event of a cache miss.

Setting `:expires_in` will set an expiration time on the cache.
All caches support auto-expiring content after a specified number of seconds.
This value can be specified as an option to the constructor (in which case all entries will be affected),
or it can be supplied to the `fetch` or `write` method to effect just one entry.

### Memory

A cache store implementation which stores everything into memory in the
same process.

Can store any serializable Crystal object.

```crystal
cache = Cache::MemoryStore(String, String).new(expires_in: 1.minute)
cache.fetch("today") do
  Time.now.day_of_week
end
```

### Redis

A cache store implementation which stores data in Redis.

```crystal
cache = Cache::RedisStore(String, String).new(expires_in: 1.minute)
cache.fetch("today") do
  Time.now.day_of_week
end
```

This assumes Redis was started with a default configuration, and is listening on localhost, port 6379.

You can connect to `Redis` by instantiating the Redis class.

If you need to connect to a remote server or a different port, try:

```crystal
redis = Redis.new(host: "10.0.1.1", port: 6380, password: "my-secret-pw", database: "my-database")
cache = Cache::RedisStore(String, String).new(expires_in: 1.minute, cache: redis)
```
### Null store

A cache store implementation which doesn't actually store anything. Useful in
development and test environments where you don't want caching turned on but
need to go through the caching interface.

```crystal
cache = Cache::NullStore(String, String).new(expires_in: 1.minute)
cache.fetch("today") do
  Time.now.day_of_week
end
```

## Contributing

1. Fork it ( https://github.com/mamantoha/cache/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [mamantoha](https://github.com/mamantoha) Anton Maminov - creator, maintainer
