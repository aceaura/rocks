local pathJoin = require('pathjoin').pathJoin
local uv = require('luv')

local function getPath()
    local caller = debug.getinfo(2, "S").source
    if caller:sub(1, 1) == "@" then return caller:sub(2) end
    error("Unknown file path type: " .. caller)
end

local function getDir()
    local caller = debug.getinfo(2, "S").source
    if caller:sub(1, 1) == "@" then return pathJoin(caller:sub(2), "..") end
    error("Unknown file path type: " .. caller)
end

local function innerResolve(path, resolveOnly)
    local caller = debug.getinfo(2, "S").source
    if caller:sub(1, 1) == "@" then
        path = pathJoin(caller:sub(2), "..", path)
        if resolveOnly then return path end
        local fd = assert(uv.fs_open(path, "r", 420))
        local stat = assert(uv.fs_fstat(fd))
        local data = assert(uv.fs_read(fd, stat.size, 0))
        uv.fs_close(fd)
        return data, path
    end
end

local function resolve(path) return innerResolve(path, true) end

local function load(path) return innerResolve(path, false) end

local function getProp(self, key)
    if key == "path" then return getPath() end
    if key == "dir" then return getDir() end
end

return setmetatable({resolve = resolve, load = load}, {__index = getProp})
