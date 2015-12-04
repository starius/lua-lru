
local function lru(max_size)

    -- current size
    local size = 0

    -- storage is a hash mapping keys to tuples
    -- tuple: value, prev, next, key
    -- prev and next are pointers to tuples
    local storage = {}

    -- indices of tuple
    local VALUE = 1
    local PREV = 2
    local NEXT = 3
    local KEY = 4

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

    local function get(_, key)
        local tuple = storage[key]
        if not tuple then
            return nil
        end
        cut(tuple)
        setNewest(tuple)
        return tuple[VALUE]
    end

    local function set(_, key, value)
        local tuple = storage[key]
        if tuple then
            cut(tuple)
        else
            if size == max_size then
                local oldest_key = oldest[KEY]
                storage[oldest_key] = nil
                cut(oldest)
            else
                size = size + 1
            end
            tuple = {nil, nil, nil, key}
        end
        tuple[VALUE] = value
        setNewest(tuple)
        storage[key] = tuple
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
        __index = get,
        __newindex = set,
        __pairs = lru_pairs,
    }

    return setmetatable({}, mt), lru_pairs
end

return lru
