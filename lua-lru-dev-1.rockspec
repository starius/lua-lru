package = "lua-lru"
version = "dev-1"
source = {
    url = "git://github.com/starius/lua-lru.git"
}
description = {
    summary = "LRU cache in Lua",
    license = "MIT",
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
