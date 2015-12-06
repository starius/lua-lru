-- lua-lru, LRU cache in Lua
-- Copyright (c) 2015 Boris Nagaev
-- See the LICENSE file for terms of use.

describe("LRU cache", function()

    it("loads 'lru' module", function()
        require 'lru'
    end)

    it("creates lru", function()
        local lru = require 'lru'
        local l = lru.new(100)
    end)

    it("is a map", function()
        local lru = require 'lru'
        local l = lru.new(100)
        l:set("foo", "bar")
        assert.equal("bar", l:get("foo"))
        l:set("foo", "bar1") -- change value
        assert.equal("bar1", l:get("foo"))
    end)

    it("resets key", function()
        local lru = require 'lru'
        local l = lru.new(100)
        l:set("foo", "bar")
        assert.equal("bar", l:get("foo"))
        l:set("foo", nil)
        assert.equal(nil, l:get("foo"))
    end)

    it("#iterates all elements", function()
        local lru = require 'lru'
        local l = lru.new(100)
        l:set("foo", "bar")
        l:set("foo1", "bar1")
        local map = {}
        for key, value in l:pairs() do
            map[key] = value
        end
        assert.same({foo="bar", foo1="bar1"}, map)
        if _VERSION >= "Lua 5.2" then
            local map = {}
            for key, value in pairs(l) do
                map[key] = value
            end
            assert.same({foo="bar", foo1="bar1"}, map)
        end
    end)

    it("eliminates old elements", function()
        local lru = require 'lru'
        local l = lru.new(3)
        l:set(1, 1)
        assert.equal(1, l:get(1))
        l:set(2, 2)
        assert.equal(1, l:get(1))
        assert.equal(2, l:get(2))
        l:set(3, 3)
        assert.equal(1, l:get(1))
        assert.equal(2, l:get(2))
        assert.equal(3, l:get(3))
        l:set(4, 4) -- eliminates 1
        assert.equal(nil, l:get(1))
        assert.equal(2, l:get(2))
        assert.equal(3, l:get(3))
        assert.equal(4, l:get(4))
        l:set(2, 2) -- updates 2
        assert.equal(nil, l:get(1))
        assert.equal(3, l:get(3))
        assert.equal(4, l:get(4))
        assert.equal(2, l:get(2))
        l:set(5, 5) -- eliminates 3
        assert.equal(nil, l:get(1))
        assert.equal(nil, l:get(3))
        assert.equal(4, l:get(4))
        assert.equal(2, l:get(2))
        assert.equal(5, l:get(5))
        l:set(5, 6) -- updates 5
        assert.equal(nil, l:get(1))
        assert.equal(nil, l:get(3))
        assert.equal(4, l:get(4))
        assert.equal(2, l:get(2))
        assert.equal(6, l:get(5))
        l:set(2, 3) -- updates 2
        assert.equal(nil, l:get(1))
        assert.equal(nil, l:get(3))
        assert.equal(4, l:get(4))
        assert.equal(6, l:get(5))
        assert.equal(3, l:get(2))
    end)

    it("doesn't leak memory (large values) #slow", function()
        -- add many large strings (~100Gb)
        local lru = require 'lru'
        local l = lru.new(3)
        local mib = ('x'):rep(1000000)
        for i = 1, 100000 do
            local key = i
            local value = mib:sub(i)
            l:set(key, value)
        end
    end)

    it("doesn't leak memory (large keys) #slow", function()
        -- add many large strings (~100Gb)
        local lru = require 'lru'
        local l = lru.new(3)
        local mib = ('x'):rep(1000000)
        for i = 1, 100000 do
            local key = mib:sub(i)
            local value = i
            l:set(key, value)
        end
    end)

    it("does #remember elements", function()
        math.randomseed(0)
        local lru = require 'lru'
        local MAX_KEY = 10000000
        local N = 1000
        local M = 100
        local cache = lru.new(M)
        local ring = {}
        for i = 0, N do
            local key = math.random(1, MAX_KEY)
            cache:set(key, key * 2)
            ring[i % M + 1] = key
            local all_keys_map = {}
            for k, v in cache:pairs() do
                all_keys_map[k] = v
            end
            for _, k in ipairs(ring) do
                assert.equal(2 * k, all_keys_map[k])
            end
        end
    end)

    it("removes elemenets in #fifo order", function()
        local lru = require 'lru'
        local cache = lru.new(10)
        local elements = {
            849811,  9140878, 3135321, 3071444,
            4098914, 5635468, 3525615, 9220377,
            2702523, 3699515, 9011105, 2966237,
        }
        for _, e in ipairs(elements) do
            cache:set(e, true)
        end
        assert.equal(true, cache:get(3135321))
    end)

    it("frees a slot when removing an element", function()
        local lru = require 'lru'
        local l = lru.new(3)
        l:set(1, 1)
        l:set(2, 2)
        l:set(3, 3)
        l:set(3, nil) -- size is 2 here: {1, 2}
        l:set(4, 4)
        assert.equal(1, l:get(1))
        assert.equal(2, l:get(2))
        assert.equal(nil, l:get(3))
        assert.equal(4, l:get(4))
    end)

    it("has method `delete`", function()
        local lru = require 'lru'
        local l = lru.new(3)
        l:set(1, 1)
        l:set(2, 2)
        l:set(3, 3)
        l:delete(3)
        l:set(4, 4)
        assert.equal(1, l:get(1))
        assert.equal(2, l:get(2))
        assert.equal(nil, l:get(3))
        assert.equal(4, l:get(4))
    end)

    it("optionally counts size in bytes", function()
        local lru = require 'lru'
        local l = lru.new(3, 100)
        l:set(1, 1, 50)
        l:set(2, 2, 50)
        l:set(3, 3, 50)
        assert.equal(nil, l:get(1))
        assert.equal(2, l:get(2))
        assert.equal(3, l:get(3))
    end)

    it("size in bytes is #length by default", function()
        local lru = require 'lru'
        local l = lru.new(3, 10)
        l:set(1, "12345")
        l:set(2, "67890")
        l:set(3, "x")
        assert.equal(nil, l:get(1))
        assert.equal("67890", l:get(2))
        assert.equal("x", l:get(3))
    end)

    it("throws if an element is too #large", function()
        local lru = require 'lru'
        local l = lru.new(3, 10)
        assert.has_error(function()
            l:set(1, "12345678901")
        end)
    end)

end)
