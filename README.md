# Caché

A key/value store where pairs can expire after a specified interval

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  cache:
    github: mamantoha/cache
```

## Usage

### Available stores

* [x] Memory
* [] File
* [] Redis
* [] MemcahedStore

```crystal
require "cache"
```

```crystal
# Set all values to expire after one minute.
cache = Cache::MemoryStore(String, String).new(expires_in: 1.minute)
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
