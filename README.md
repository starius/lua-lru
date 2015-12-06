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
cache = lru(100)
```

Create an instance of LRU cache for 100 elements of 1000 bytes:

```lua
lru = require 'lru`
cache = lru(100, 1000)
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

[license]: https://img.shields.io/badge/License-MIT-brightgreen.png
[travis]: https://travis-ci.org/starius/lua-lru
[build-status]: https://travis-ci.org/starius/lua-lru.png
[coveralls-page]: https://coveralls.io/github/starius/lua-lru
[coveralls-badge]: https://coveralls.io/repos/starius/lua-lru/badge.png?service=github
