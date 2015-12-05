

describe("LRU cache", function()

    it("loads 'lru' module", function()
        require 'lru'
    end)

    it("creates lru", function()
        local lru = require 'lru'
        local l = lru(100)
    end)

    it("is a map", function()
        local lru = require 'lru'
        local l = lru(100)
        l.foo = "bar"
        assert.equal("bar", l.foo)
        l.foo = "bar1" -- change value
        assert.equal("bar1", l.foo)
    end)

    it("resets key", function()
        local lru = require 'lru'
        local l = lru(100)
        l.foo = "bar"
        assert.equal("bar", l.foo)
        l.foo = nil
        assert.equal(nil, l.foo)
    end)

    it("iterates all elements", function()
        local lru = require 'lru'
        local l, lru_pairs = lru(100)
        l.foo = "bar"
        l.foo1 = "bar1"
        local map = {}
        for key, value in lru_pairs() do
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
        local l = lru(3)
        l[1] = 1
        assert.equal(1, l[1])
        l[2] = 2
        assert.equal(1, l[1])
        assert.equal(2, l[2])
        l[3] = 3
        assert.equal(1, l[1])
        assert.equal(2, l[2])
        assert.equal(3, l[3])
        l[4] = 4 -- eliminates 1
        assert.equal(nil, l[1])
        assert.equal(2, l[2])
        assert.equal(3, l[3])
        assert.equal(4, l[4])
        l[2] = 2 -- updates 2
        assert.equal(nil, l[1])
        assert.equal(3, l[3])
        assert.equal(4, l[4])
        assert.equal(2, l[2])
        l[5] = 5 -- updates 3
        assert.equal(nil, l[1])
        assert.equal(nil, l[3])
        assert.equal(4, l[4])
        assert.equal(2, l[2])
        assert.equal(5, l[5])
        l[5] = 6 -- updates 5
        assert.equal(nil, l[1])
        assert.equal(nil, l[3])
        assert.equal(4, l[4])
        assert.equal(2, l[2])
        assert.equal(6, l[5])
        l[2] = 3 -- updates 2
        assert.equal(nil, l[1])
        assert.equal(nil, l[3])
        assert.equal(4, l[4])
        assert.equal(6, l[5])
        assert.equal(3, l[2])
    end)

    it("doesn't leak memory #slow", function()
        -- add many large strings (~100Gb)
        local lru = require 'lru'
        local l = lru(3)
        local mib = ('x'):rep(1000000)
        for i = 1, 100000 do
            local key = i
            local value = mib:sub(i)
            l[i] = value
        end
    end)

end)
