package = "lua-lru"
version = "dev-1"
source = {
    url = "git://github.com/starius/lua-lru.git"
}
description = {
    summary = "LRU cache in Lua",
    license = "MIT",
    homepage = "https://github.com/starius/lua-lru",
    detailed = [[
lua-lru, LRU cache in Lua

LRU cache is implemented using a doubly linked list and
a hash map. Hash Map maps a key to a corresponding tuple.
Doubly Linked List is used to store list of tuples
(value, previous, next, key, size_in_bytes).
Key is needed in a tuple to be able to remove an element from
the hash map. Field size_in_bytes is optional and is used
if sizes in bytes are counted (and constrained) as well as
the number of elements.

Create an instance of LRU cache for 100 elements:

    lru = require 'lru'
    cache = lru.new(100)

Create an instance of LRU cache for 100 elements of
1000 bytes totally:

    lru = require 'lru'
    cache = lru.new(100, 1000)

Methods:

  * cache:set(key, value, [size_in_bytes])
  * cache:get(key)
  * cache:delete(key)
  * cache:pairs() or pairs(cache) for Lua >= 5.2
]],
}
dependencies = {
    "lua >= 5.1",
}
build = {
    type = "builtin",
    modules = {
        ['lru'] = 'src/lru/lru.lua',
    },
}
