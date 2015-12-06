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

for i = 1, 1000000 do
    local key
    for j = 1, 5 do
        local x = math.random(1, 10000)
        cache:set(x, x+1)
        key = x
    end
    for j = 1, 5 do
        local x = math.random(1, 1000)
        cache:set(x, x+1)
    end
    assert(cache:get(key) == key+1)
end
