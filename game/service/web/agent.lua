require("quickframework.init")
local skynet = require "skynet"

local script, host, uid = ...
uid = tonumber(uid)
assert(script and host and uid)

require(script)

_G.agent =
{
    uid = uid,
    host = host
}

local CMD = {}

function CMD.exit()
    --if type(_G.exit) == 'function' then
    --    _G.exit()
    --end
    skynet.exit()
end

skynet.start(function()
    skynet.dispatch("lua", function(_,_,cmd)
        local f = CMD[cmd]
        assert(f, cmd)
    end)
    skynet.fork(function()
        if type(_G.main) == "function" then
            _G.main(host, uid)
        end
    end)
end)
