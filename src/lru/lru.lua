-- lua-lru, LRU cache in Lua
-- Copyright (c) 2015 Boris Nagaev
-- See the LICENSE file for terms of use.

local function lru(max_size, max_bytes)

    -- current size
    local size = 0
    local bytes_used = 0

    -- storage is a hash mapping keys to tuples
    -- tuple: value, prev, next, key
    -- prev and next are pointers to tuples
    local storage = {}

    -- indices of tuple
    local VALUE = 1
    local PREV = 2
    local NEXT = 3
    local KEY = 4
    local BYTES = 5

    -- newest and oldest are ends of double-linked list
    local newest = nil -- first
    local oldest = nil -- last

    -- remove a tuple from linked list
    local function cut(tuple)
        local tuple_prev = tuple[PREV]
        local tuple_next = tuple[NEXT]
        tuple[PREV] = nil
        tuple[NEXT] = nil
        if tuple_prev and tuple_next then
            tuple_prev[NEXT] = tuple_next
            tuple_next[PREV] = tuple_prev
        elseif tuple_prev then
            -- tuple is the oldest element
            tuple_prev[NEXT] = nil
            oldest = tuple_prev
        elseif tuple_next then
            -- tuple is the newest element
            tuple_next[PREV] = nil
            newest = tuple_next
        else
            -- tuple is the only element
            newest = nil
            oldest = nil
        end
    end

    -- insert a tuple to the newest end
    local function setNewest(tuple)
        if not newest then
            newest = tuple
            oldest = tuple
        else
            tuple[NEXT] = newest
            newest[PREV] = tuple
            newest = tuple
        end
    end

    local function del(key, tuple)
        storage[key] = nil
        cut(tuple)
        size = size - 1
        bytes_used = bytes_used - (tuple[BYTES] or 0)
    end

    local function makeFreeSpace(bytes)
        while size + 1 > max_size or
            (max_bytes and bytes_used + bytes > max_bytes)
        do
            assert(oldest, "not enough storage for cache")
            del(oldest[KEY], oldest)
        end
    end

    local function get(_, key)
        local tuple = storage[key]
        if not tuple then
            return nil
        end
        cut(tuple)
        setNewest(tuple)
        return tuple[VALUE]
    end

    local function set(_, key, value, bytes)
        local tuple = storage[key]
        if tuple then
            del(key, tuple)
        end
        if value ~= nil then
            -- the value is not removed
            bytes = max_bytes and (bytes or #value) or 0
            makeFreeSpace(bytes)
            local tuple1 = {
                value,
                nil,
                nil,
                key,
                max_bytes and bytes,
            }
            size = size + 1
            bytes_used = bytes_used + bytes
            setNewest(tuple1)
            storage[key] = tuple1
        end
    end

    local function delete(_, key)
        return set(_, key, nil)
    end

    local function mynext(storage1, prev_key)
        local key, tuple = next(storage1, prev_key)
        return key, tuple and tuple[VALUE]
    end

    -- returns iterator for keys and values
    local function lru_pairs()
        return mynext, storage, nil
    end

    local mt = {
        __index = {
            get = get,
            set = set,
            delete = delete,
            pairs = lru_pairs,
        },
        __pairs = lru_pairs,
    }

    return setmetatable({}, mt)
end

return lru
