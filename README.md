# lua-lru, LRU cache in Lua

[![Build Status][build-status]][travis]
[![Coverage Status][coveralls-badge]][coveralls-page]
[![License][license]](LICENSE)

LRU cache:

![LRU cache](https://i.imgur.com/TKuaXlo.png)

LRU cache is implemented using a doubly linked list and
a hash map. Hash Map maps a key to a corresponding tuple.
Doubly Linked List is used to store list of tuples
(`value`, `previous`, `next`, `key`, `size_in_bytes`).
`key` is needed in a tuple to be able to remove an element from
the hash map. Field `size_in_bytes` is optional and is used
if sizes in bytes are counted (and constrained) as well as
the number of elements.

Create an instance of LRU cache for 100 elements:

```lua
lru = require 'lru`
cache = lru.new(100)
```

Create an instance of LRU cache for 100 elements of 1000 bytes:

```lua
lru = require 'lru`
cache = lru.new(100, 1000)
```

Methods:

  * `cache:set(key, value, size_in_bytes)` add or update an
    element. If `key` is not in `cache`, creates new element.
    Otherwise, updates the value of the existing element.
    In both cases, moves the element to the head of the queue.

    If the cache was full, the tail of the queue is removed.
    If the cache has the limit of bytes used by its elements,
    it is enforced as well: the elements are removed until
    enough space is freed. If the size of the element being
    added or updated is greater than the limit, the error
    is thrown. Argument `size_in_bytes` defaults to `#value`.

    If `value` is `nil`, it doesn't occupy a slot.

  * `cache:get(key)` returns the value corresponding to the key.
    If `key` is not in `cache`, returns `nil`.
    Otherwise moves the element to the head of the queue.

  * `cache:delete(key)` same as `cache:set(key, nil)`

  * `cache:pairs()` returns key-value iterator. Example:

    ```lua
    for key, value in cache:pairs() do
        ...
    end

    -- Lua >= 5.2
    for key, value in pairs(cache) do
        ...
    end
    ```

## Comparison with other implementations

I have found two other implementations of LRU in Lua.

  * [lua-resty-lrucache][resty-lru] uses FFI.
  * [Lua-LRU-Cache][Lua-LRU-Cache] is written in pure Lua
    but turned out to be rather slow.

Both `lua-resty-lrucache` and `Lua-LRU-Cache` provide `ttl`
for the elements, but do not provide `size_in_bytes`.

This library (`lua-lru`) seems to be faster than
`lua-resty-lrucache` and `Lua-LRU-Cache`.

The benchmark runs `cache:set` with random keys 1kk times,
alternating ranges [1;1000] and [1;10000] with period 5.
Source of the benchmark can be found in `benchmark/` directory.

Results:

```
$ ./benchmark.sh

LuaJIT 2.0.3 -- Copyright (C) 2005-2014 Mike Pall. http://luajit.org/
--------
no cache

real    0m1.129s
user    0m1.124s
sys     0m0.000s
--------
lua-lru

real    0m7.812s
user    0m7.616s
sys     0m0.176s
--------
LuaRestyLrucacheLibrary.lrucache

real    0m10.751s
user    0m10.729s
sys     0m0.000s
--------
LuaRestyLrucacheLibrary.pureffi

real    0m15.833s
user    0m15.797s
sys     0m0.004s
--------
LRUCache.lua
... too slow
```

[license]: https://img.shields.io/badge/License-MIT-brightgreen.png
[travis]: https://travis-ci.org/starius/lua-lru
[build-status]: https://travis-ci.org/starius/lua-lru.png
[coveralls-page]: https://coveralls.io/github/starius/lua-lru
[coveralls-badge]: https://coveralls.io/repos/starius/lua-lru/badge.png?service=github
[resty-lru]: https://github.com/openresty/lua-resty-lrucache
[Lua-LRU-Cache]: https://github.com/kenshinx/Lua-LRU-Cache
