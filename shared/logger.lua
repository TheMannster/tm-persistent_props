TM = TM or {}
TM.Log = {}

local RESOURCE = GetCurrentResourceName()
local VERSION  = GetResourceMetadata(RESOURCE, 'version', 0) or '?.?.?'

local function p(s)
    print(s .. '^7')
end

function TM.Log.banner()
    if Config and Config.ShowStartupBanner == false then return end
    p('')
    p('^5====================================================')
    p('^5  TM-PERSISTENT_PROPS ^7v' .. VERSION)
    p('^5  Player-placed persistent prop system')
    p('^5====================================================')
end

function TM.Log.footer(info)
    if Config and Config.ShowStartupBanner == false then return end
    p('^5----------------------------------------------------')
    p(('^2  Started ^7- ^2%s'):format(info or 'ready'))
    p('^5====================================================')
    p('')
end

function TM.Log.info(tag, msg)
    p(('^5[TM:%s]^7 %s'):format(tag, msg))
end

function TM.Log.warn(tag, msg)
    p(('^3[TM:%s WARN]^7 %s'):format(tag, msg))
end

function TM.Log.err(tag, msg)
    p(('^1[TM:%s ERR]^7 %s'):format(tag, msg))
end
