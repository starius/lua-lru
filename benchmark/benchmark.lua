-- lua-lru, LRU cache in Lua
-- Copyright (c) 2015 Boris Nagaev
-- See the LICENSE file for terms of use.

local lru

-- fix for resty.lrucache
ngx = {
    now = os.clock
}

local impl = arg[1]
if impl then
    lru = require(impl)
else
    lru = {
        new = function()
            return {
                set = function()
                end,
                get = function(_, x)
                    return x+1
                end,
            }
        end
    }
end

-- fix for Lua-LRU-Cache
if impl == 'LRUCache' then
    lru.new0 = lru.new
    function lru.new(max_size,expire)
        return lru:new0(max_size,expire)
    end
end

local cache = lru.new(1000)

for i = 1, 10000000 do
    local max = (i % 10 < 5) and 10000 or 1000
    local x = math.random(1, 10000)
    local v = cache:get(x)
    if v then
        assert(v == x + 1)
    else
        cache:set(x, x+1)
    end
end
