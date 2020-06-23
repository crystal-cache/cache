# Changelog

## [...]

## 0.9.0

* Ignore `compress` options for other then `MemoryStore(String, String)`
* Fix `MemoryStore(K, V)` can store any serializable Crystal object.

## 0.8.0

* Crystal 0.35.0 support

## 0.7.0

* Crystal 0.34.0 support

## 0.6.0

* Crystal 0.32.0 support

## 0.5.0

* Allow `Redis::PooledClient` in `RedisStore`
* Compress data with Zlib in `MemoryStore`

## 0.4.0

* Crystal 0.30 support
* Use latest Redis and Memcached shards

## 0.3.0

* Crystal 0.27 support

## 0.2.1

* Use crystal-redis 2.1.0

## 0.2.0

* add `.clear` method which deletes all entries from the cache.

## 0.1.0

* Crystal 0.26 support
* Add `FileStore` which stores everything on the filesystem
* Add method to delete an entry in the cache
* Bug fixes and other improvements

## 0.0.7

* Memcached support

## 0.0.6

* Crystal 0.25 support

## 0.0.5

* Add NullStore - store implementation which doesn't actually store anything

## 0.0.4

* Redis support improvements

## 0.0.3

* Redis support

## 0.0.2

* Add expires in

## 0.0.1

* Initial release
