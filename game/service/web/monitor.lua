local skynet = require "skynet"
local svrAddrMgr = require "svrAddrMgr"
local snax = require "skynet.snax"

local monitor = {}
local stats_service = {}
local counter_service = {}
local sessions = {}

local function queryservice(name, type)
    local s
    if type then
        if not stats_service[type] then stats_service[type] = {} end
        s = stats_service[type][name]
        if not s then
            local webSvr = svrAddrMgr.getSvr(svrAddrMgr.webSvr)
            local addr = skynet.call(webSvr, "lua", "stats_service", type, name)
            s = snax.bind(addr, 'stats')
            stats_service[type][name] = s
        end
        return s
    end
    s = counter_service[name]
    if s then
        return s
    end
    local webSvr = svrAddrMgr.getSvr(svrAddrMgr.webSvr)
    local addr = skynet.call(webSvr, "lua", "counter_service", name)
    s = snax.bind(addr, 'counter')
    counter_service[name] = s
    return s
end

function monitor.incr(name, num)
    assert(name)
    local s = queryservice(name)
    if type(num) ~= "number" then
        num = 1
    end
    s.post.incr(num)
end

function monitor.decr(name, num)
    assert(name)
    local s = queryservice(name)
    if type(num) ~= "number" then
        num = 1
    end
    s.post.decr(num or 1)
end

function monitor.set(name, cnt)
    assert(name)
    local s = queryservice(name)
    assert(type(cnt) == "number")
    s.post.set(cnt)
end

function monitor.time(type, name, session)
    assert(type and name and session)
    sessions[session] = {type = type, name = name}
    local s = queryservice(name, type)
    s.post.time(skynet.self(), session)
end

function monitor.endtime(session, size, is_failed)
    assert(session)
    local info = sessions[session]
    assert(info, 'session not record.')
    sessions[session] = nil
    local s = queryservice(info.name, info.type)
    s.post.endtime(skynet.self(), session, size or 0, is_failed)
end

return monitor