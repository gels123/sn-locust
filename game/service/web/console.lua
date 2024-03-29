local skynet = require "skynet"

local function console_raw(func, ...)
    local args = {...}
    skynet.fork(function()
        local webSvr = svrAddrMgr.getSvr(svrAddrMgr.webSvr)
        skynet.send(webSvr, "lua", "broadcast", "console", {func=func, args = args})
    end)
end

local console = setmetatable({}, {__index = function(t,k)
    t[k] = function(...)
        return console_raw(k, ...)
    end
    return t[k]
end})

return console