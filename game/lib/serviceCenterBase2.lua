--[[
    服务中心基类(myScheduler版)
    Created by Gels on 2021/8/26.
]]
local skynet = require("skynet")
local mc = require("skynet.multicast")
local skynetQueue = require("skynet.queue")
local serviceCenterBase = class("serviceCenterBase")

-- 获取单例
local instance = nil  
function serviceCenterBase.shareInstance(cc)
    if not instance then
        instance = cc.new()
    end
    return instance
end

-- 构造函数
function serviceCenterBase:ctor()
    -- 王国ID
    self.kid = nil
    -- 计时器
    self.myTimer = nil
    -- 开始频道
    self.startChannel = nil
    -- 串行队列
    self.sq = nil
    -- 是否停服中
    self.stoping = false
    -- 是否已停服
    self.stoped = false
    -- 不返回数据的指令集
    self.sendCmd = {
        ["dispatchmsg"] = true,
    }
end

-- 初始化
function serviceCenterBase:init(kid)
    Log.i("====serviceCenterBase:init begin:", kid, self.class.__cname)

    -- 初始化王国ID
    self.kid = tonumber(kid)
    -- 初始化计时器
    self.myTimer = require("myScheduler").new()
    -- 订阅服务器启动服务频道
    self:subscribeStartService()

    Log.i("====serviceCenterBase:init end:", kid, self.class.__cname)
end

-- 获取王国ID
function serviceCenterBase:getKid()
    return self.kid
end

-- 获取定时器模块实例
function serviceCenterBase:getTimerModule()
    return self.myTimer
end

-- 获取是否已停服
function serviceCenterBase:getStoped()
    return self.stoped
end

-- 订阅服务器启动服务频道
function serviceCenterBase:subscribeStartService()
    local startSvr = svrAddrMgr.getSvr(svrAddrMgr.startSvr, self.kid)
    local channelID = skynet.call(startSvr, "lua", "getChannel")
    if channelID then
        self.startChannel = mc.new({
            channel = channelID,
            dispatch = function (channel, source, ...)
                self.startChannel:unsubscribe()
                self:start()
            end
        })
        self.startChannel:subscribe()
    end
end

-- 开始服务
function serviceCenterBase:start()
    Log.i("=== serviceCenterBase:start begin:", self.kid, self.class.__cname)

    if self.myTimer then
        self.myTimer:start()
    end

    Log.i("=== serviceCenterBase:start end:", self.kid, self.class.__cname)
end

-- 停止服务
function serviceCenterBase:stop()
    Log.i("=== serviceCenterBase:stop begin ===", self.kid, self.class.__cname)

    -- 标记停服中
    if self.stoping then
        return
    end
    self.stoping = true
    -- 标记已停服
    self.stoped = true
    if self.myTimer then
        self.myTimer:pause()
    end

    Log.i("=== serviceCenterBase:stop end ===", self.kid, self.class.__cname)
end

-- 杀死服务
function serviceCenterBase:kill()
    Log.i("=== serviceCenterBase:kill begin ===", self.kid, self.class.__cname)

    self:stop()
    skynet.exit() -- skynet.kill(skynet.self())

    Log.i("=== serviceCenterBase:kill begin ===", self.kid, self.class.__cname)
end

-- 分发客户端指令
function serviceCenterBase:dispatchmsg(aid, req)

end

-- 分发服务端调用
function serviceCenterBase:dispatchCmd(session, source, cmd, ...)
    -- Log.d("serviceCenterBase:dispatchCmd", session, source, cmd, ...)
    local func = instance and instance[cmd]
    if func then
        if self.sendCmd[cmd] then
            xpcall(func, svrFunc.exception, self, ...)
        else
            self:ret(xpcall(func, svrFunc.exception, self, ...))
        end
    else
        self:ret()
        Log.e("serviceCenterBase:dispatchCmd error: cmd not found:", cmd, ...)
    end
end

-- 返回数据
function serviceCenterBase:ret(ok, ...)
    if ok then
        skynet.ret(skynet.pack(...))
    else
        skynet.ret(skynet.pack())
    end
end

-- 获取串行队列
function serviceCenterBase:getSq(type)
    if not self.sq then
        self.sq = {}
    end
    if not self.sq[type] then
        self.sq[type] = skynetQueue()
    end
    return self.sq[type]
end

-- 删除串行队列
function serviceCenterBase:delSq(type)
    if self.sq then
        self.sq[type] = nil
    end
end

return serviceCenterBase