Bridge = {
    name = nil,
    core = nil,
}

local function started(resource)
    return GetResourceState(resource) == 'started'
end

function Bridge.Resolve()
    local forced = Config.Framework

    if Bridge.name == 'qbox' and (forced == 'auto' or forced == 'qbox') and started('qbx_core') then
        return true
    end
    if Bridge.name == 'qb' and Bridge.core and (forced == 'auto' or forced == 'qb') and started('qb-core') then
        return true
    end
    if Bridge.name == 'esx' and Bridge.core and (forced == 'auto' or forced == 'esx') and started('es_extended') then
        return true
    end

    if (forced == 'auto' or forced == 'qbox') and started('qbx_core') then
        Bridge.name = 'qbox'
        Bridge.core = nil
        return true
    end

    if (forced == 'auto' or forced == 'qb') and started('qb-core') then
        Bridge.name = 'qb'
        local ok, core = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        Bridge.core = ok and core or nil
        return Bridge.core ~= nil
    end

    if (forced == 'auto' or forced == 'esx') and started('es_extended') then
        Bridge.name = 'esx'
        local ok, core = pcall(function()
            return exports['es_extended']:getSharedObject()
        end)
        Bridge.core = ok and core or nil
        return Bridge.core ~= nil
    end

    Bridge.name = nil
    Bridge.core = nil
    return false
end

function Bridge.T(key, ...)
    local locale = Locales[Config.Locale] or Locales.es or Locales.en or {}
    local fallback = Locales.en or {}
    local value = locale[key] or fallback[key] or key

    if select('#', ...) > 0 then
        return string.format(value, ...)
    end

    return value
end

function Bridge.UI()
    local locale = Locales[Config.Locale] or Locales.es or Locales.en or {}
    return locale.ui or (Locales.en and Locales.en.ui) or {}
end

Bridge.Resolve()

local frameworkResources = {
    qbx_core = 'qbox',
    ['qb-core'] = 'qb',
    es_extended = 'esx',
}

local function resetFramework(resource)
    local framework = frameworkResources[resource]
    if framework and Bridge.name == framework then
        Bridge.name = nil
        Bridge.core = nil
    end
end

local function resolveFramework(resource)
    if frameworkResources[resource] then
        Bridge.Resolve()
    end
end

if IsDuplicityVersion() then
    AddEventHandler('onResourceStop', resetFramework)
    AddEventHandler('onResourceStart', resolveFramework)
else
    AddEventHandler('onClientResourceStop', resetFramework)
    AddEventHandler('onClientResourceStart', resolveFramework)
end

if not Bridge.name then
    CreateThread(function()
        for _ = 1, 60 do
            Wait(250)
            if Bridge.Resolve() then
                return
            end
        end

        print(('^3[jrmy_tags]^7 %s'):format(Bridge.T('framework_missing')))
    end)
end
