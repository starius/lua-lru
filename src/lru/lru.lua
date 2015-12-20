-- lua-lru, LRU cache in Lua
-- Copyright (c) 2015 Boris Nagaev
-- See the LICENSE file for terms of use.

local lru = {}

function lru.new(max_size, max_bytes)
    local bytes_used = 0

    -- map is a hash map from keys to tuples
    local map = {}
    -- array of size max_size * TUPLE_SIZE
    local list = {}

    -- shifts of tuple members
    -- tuple: value, prev, next, key
    -- prev and next are indices of tuples
    local VALUE = 0
    local PREV = 1
    local NEXT = 2
    local KEY = 3
    local BYTES = max_bytes and 4 or nil
    --
    local TUPLE_SIZE = max_bytes and 5 or 4

    local DUMMY = {} -- dummy key and dummy value

    local min_tuple = 1
    local max_tuple = (max_size - 1) * TUPLE_SIZE + 1
    for tuple = min_tuple, max_tuple, TUPLE_SIZE do
        list[tuple + VALUE] = DUMMY
        list[tuple + PREV] = tuple - TUPLE_SIZE
        list[tuple + NEXT] = tuple + TUPLE_SIZE
        list[tuple + KEY] = DUMMY
        if max_bytes then
            list[tuple + BYTES] = 0
        end
    end
    list[min_tuple + PREV] = max_tuple
    list[max_tuple + NEXT] = min_tuple

    -- cyclic doubly-linked list
    -- head is the oldest element in the cache
    -- head is elided
    -- new elements are inseted before head
    local head = min_tuple

    -- functions depending on max_bytes
    local remove, elide, set, delete, setNewest

    if max_bytes then

        function remove(tuple, removed_key)
            local removed_bytes = list[tuple + BYTES]
            bytes_used = bytes_used - removed_bytes
            map[removed_key] = nil
            list[tuple + KEY] = DUMMY
            list[tuple + VALUE] = DUMMY
            list[tuple + BYTES] = 0
        end

        function elide(new_key, new_value, new_bytes)
            assert(new_bytes <= max_bytes, "Too large object")
            local elided = head
            repeat
                local removed_key = list[elided + KEY]
                remove(elided, removed_key)
                elided = list[elided + NEXT]
            until bytes_used + new_bytes <= max_bytes
            map[new_key] = head
            list[head + KEY] = new_key
            list[head + VALUE] = new_value
            list[head + BYTES] = new_bytes
            bytes_used = bytes_used + new_bytes
            head = list[head + NEXT]
        end

        function set(_, key, value, bytes)
            assert(key ~= nil, "Key may not be nil")
            bytes = bytes or #value
            if value == nil then
                delete(_, key)
            else
                local tuple = map[key]
                if tuple then
                    local old_bytes = list[head + BYTES]
                    if old_bytes + bytes > max_bytes then
                        -- elide other elemeents to get space
                        remove(tuple, key)
                        setNewest(tuple)
                        head = tuple
                        elide(key, value, bytes)
                    else
                        -- only update value
                        setNewest(tuple)
                        list[tuple + VALUE] = value
                        bytes_used = bytes_used
                            + bytes - old_bytes
                    end
                else
                    elide(key, value, bytes)
                end
            end
        end

    else

        function remove(tuple, removed_key)
            map[removed_key] = nil
            list[tuple + KEY] = DUMMY
            list[tuple + VALUE] = DUMMY
        end

        function elide(new_key, new_value)
            local removed_key = list[head + KEY]
            map[removed_key] = nil
            map[new_key] = head
            list[head + KEY] = new_key
            list[head + VALUE] = new_value
            head = list[head + NEXT]
        end

        function set(_, key, value)
            assert(key ~= nil, "Key may not be nil")
            if value == nil then
                delete(_, key)
            else
                local tuple = map[key]
                if tuple then
                    setNewest(tuple)
                    list[tuple + VALUE] = value
                else
                    elide(key, value)
                end
            end
        end

    end

    -- move before head
    function setNewest(tuple)
        if tuple == head then
            head = list[head + NEXT]
        else
            -- cut
            local tuple_old_prev = list[tuple + PREV]
            local tuple_old_next = list[tuple + NEXT]
            list[tuple_old_prev + NEXT] = tuple_old_next
            list[tuple_old_next + PREV] = tuple_old_prev
            -- insert
            local head_old_prev = list[head + PREV]
            list[head_old_prev + NEXT] = tuple
            list[tuple + PREV] = head_old_prev
            list[head + PREV] = tuple
            list[tuple + NEXT] = head
        end
    end

    function delete(_, key)
        assert(key ~= nil, "Key may not be nil")
        local tuple = map[key]
        if tuple then
            remove(tuple, key)
            setNewest(tuple)
            head = tuple
        end
    end

    local function get(_, key)
        local tuple = map[key]
        if not tuple then
            return nil
        end
        setNewest(tuple)
        return list[tuple + VALUE]
    end

    -- returns iterator for keys and values
    local function lru_pairs()
        return coroutine.wrap(function()
            for tuple = min_tuple, max_tuple, TUPLE_SIZE do
                local key = list[tuple + KEY]
                local value = list[tuple + VALUE]
                if key ~= DUMMY then
                    coroutine.yield(key, value)
                end
            end
        end)
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
