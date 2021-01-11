# lua-lru, LRU cache in Lua

[![Build Status][build-status]][travis]
[![Coverage Status][coveralls-badge]][coveralls-page]
[![Luacheck](https://github.com/starius/lua-lru/workflows/Luacheck/badge.svg)](https://github.com/starius/lua-lru/actions)
[![License][license]](LICENSE)

Install:

```
$ luarocks install lua-lru
```

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
lru = require 'lru'
cache = lru.new(100)
```

Create an instance of LRU cache for 100 elements of
1000 bytes totally:

```lua
lru = require 'lru'
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

    Complexity:

      * O(1) if cache doesn't have `size_in_bytes` limit,
      * amortized O(1) if cache has `size_in_bytes` limit.

  * `cache:get(key)` returns the value corresponding to the key.
    If `key` is not in `cache`, returns `nil`.
    Otherwise moves the element to the head of the queue.

    Complexity: O(1).

  * `cache:delete(key)` same as `cache:set(key, nil)`

    Complexity: O(1).

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

    Complexity:

      * O(1) to create an iterator,
      * O(cache size) to visit all elements.

## Comparison with other implementations

I have found two other implementations of LRU in Lua.

  * [lua-resty-lrucache][resty-lru] uses FFI.
  * [Lua-LRU-Cache][Lua-LRU-Cache] is written in pure Lua
    but turned out to be rather slow.

Both `lua-resty-lrucache` and `Lua-LRU-Cache` provide `ttl`
for the elements, but do not provide `size_in_bytes`.

This library (`lua-lru`) seems to be faster than
`lua-resty-lrucache` and `Lua-LRU-Cache`.

The benchmark runs `cache:get` with random keys 1kk times,
alternating ranges [1;1000] and [1;10000] with period 5.
In case of cache hit it compares the cached value with
the expected value. Otherwise it calls `cache:set`.
Source of the benchmark can be found in `benchmark/` directory.

Results:

```
$ ./benchmark.sh

Architecture:          x86_64
CPU op-mode(s):        32-bit, 64-bit
Byte Order:            Little Endian
CPU(s):                8
On-line CPU(s) list:   0-7
Thread(s) per core:    2
Core(s) per socket:    4
Socket(s):             1
NUMA node(s):          1
Vendor ID:             GenuineIntel
CPU family:            6
Model:                 62
Stepping:              4
CPU MHz:               2800.232
BogoMIPS:              5599.82
Virtualization:        VT-x
L1d cache:             32K
L1i cache:             32K
L2 cache:              256K
L3 cache:              10240K
NUMA node0 CPU(s):     0-7

LuaJIT 2.0.3 -- Copyright (C) 2005-2014 Mike Pall. http://luajit.org/
--------
no cache

real    0m0.219s
user    0m0.216s
sys     0m0.000s
--------
lua-lru

real    0m2.747s
user    0m2.724s
sys     0m0.000s
--------
LuaRestyLrucacheLibrary.lrucache

real    0m5.403s
user    0m5.384s
sys     0m0.004s
--------
LuaRestyLrucacheLibrary.pureffi

real    0m8.813s
user    0m8.785s
sys     0m0.000s
--------
LRUCache.lua
... too slow, waited for 10 hours
```

Both `lua-lru` and `resty-lru` are compiled by LuaJIT perfectly:

```
$ luajit -v
LuaJIT 2.1.0-alpha -- Copyright (C) 2005-2015 Mike Pall. http://luajit.org/

$ luajit -jp=v benchmark.lua lru
99%  Compiled

$ luajit -jp=v benchmark.lua lrucache
92%  Compiled
8%  Garbage Collector

$ luajit -jp=v benchmark.lua pureffi
98%  Compiled
```

[license]: https://img.shields.io/badge/License-MIT-brightgreen.png
[travis]: https://travis-ci.org/starius/lua-lru
[build-status]: https://travis-ci.org/starius/lua-lru.png
[coveralls-page]: https://coveralls.io/github/starius/lua-lru
[coveralls-badge]: https://coveralls.io/repos/starius/lua-lru/badge.png?service=github
[resty-lru]: https://github.com/openresty/lua-resty-lrucache
[Lua-LRU-Cache]: https://github.com/kenshinx/Lua-LRU-Cache
