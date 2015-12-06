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
                end
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


local function genTestData()
    return coroutine.wrap(function()
        for i = 1, 1000000 do
            for j = 1, 5 do
                coroutine.yield(math.random(1, 10000))
            end
            for j = 1, 5 do
                coroutine.yield(math.random(1, 1000))
            end
        end
    end)
end

local cache = lru.new(1000)

for x in genTestData() do
    cache:set(x, x+1)
end
