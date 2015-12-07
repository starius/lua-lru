#!/bin/bash

# download LuaRestyLrucacheLibrary and Lua-LRU-Cache
[ ! -f lrucache.lua ] && wget https://raw.githubusercontent.com/openresty/lua-resty-lrucache/6d74ab1dbfb04ccce2e32be70959ce1fc54185de/lib/resty/lrucache.lua
[ ! -f pureffi.lua ] && wget https://raw.githubusercontent.com/openresty/lua-resty-lrucache/6d74ab1dbfb04ccce2e32be70959ce1fc54185de/lib/resty/lrucache/pureffi.lua

# download Lua-LRU-Cache
[ ! -f LRUCache.lua ] && wget -O LRUCache.lua https://raw.githubusercontent.com/kenshinx/Lua-LRU-Cache/de2531481cf371f5472bbbd137a2545321e62e22/lru.lua

lscpu

luajit -v

echo '--------'
echo 'no cache'
time luajit benchmark.lua

echo '--------'
echo 'lua-lru'
time luajit benchmark.lua lru

echo '--------'
echo 'LuaRestyLrucacheLibrary.lrucache'
time luajit benchmark.lua lrucache

echo '--------'
echo 'LuaRestyLrucacheLibrary.pureffi'
time luajit benchmark.lua pureffi

# takes too much time
#echo '--------'
#echo 'LRUCache.lua'
#time luajit benchmark.lua LRUCache
