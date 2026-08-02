local resourceName = GetCurrentResourceName()

local uiReady = false
local panelOpen = false
local panelFocusOwned = false
local panelGeneration = 0
local panelPayload = nil
local playerPayload = nil
local adminPayload = nil
local adminResultPayload = nil
local hasPlayerPayload = false
local hasAdminPayload = false
local hasAdminResultPayload = false
local pendingToasts = {}

local characterLoaded = false
local characterBlockedAt = -4000
local currentRevision = -1
local snapshotRequestedAt = 0
local snapshotRetryGeneration = 0
local snapshotRecoveryActive = false
local serverEpoch = 0
local serverEpochTimer = 0
local worldDefinitions = {}
local playerCache = {}
local candidates = {}
local lastPlayerRefresh = 0
local emptyFrameSent = true
local readinessMisses = 0

local renderConfig = Config.Render or {}
local maxDistance = math.max(1.0, tonumber(renderConfig.MaxDistance) or 18.0)
local maxDistanceSquared = maxDistance * maxDistance
local positionInterval = math.max(16, math.floor(tonumber(renderConfig.PositionInterval) or 33))
local candidateInterval = math.max(positionInterval, math.floor(tonumber(renderConfig.CandidateInterval) or 350))
local idleInterval = math.max(250, math.floor(tonumber(renderConfig.IdleInterval) or 750))
local playerRefreshInterval = math.max(candidateInterval, math.floor(tonumber(renderConfig.PlayerRefreshInterval) or 1000))
local maxVisible = math.max(1, math.floor(tonumber(renderConfig.MaxVisible) or 24))
local fadeStart = math.min(0.95, math.max(0.0, tonumber(renderConfig.FadeStart) or 0.55))
local minScale = math.min(1.0, math.max(0.25, tonumber(renderConfig.MinScale) or 0.78))
local headOffset = tonumber(renderConfig.HeadOffset) or 0.45
local minimumAlpha = math.min(255, math.max(0, math.floor(tonumber(renderConfig.MinimumAlpha) or 100)))

local allowedSymbols = { emoji = true, icon = true, none = true }
local allowedVariants = { royal = true, mono = true, candy = true, sakura = true, sticker = true, minimal = true, ribbon = true }
local allowedFonts = { display = true, mono = true, body = true }
local allowedEffects = { none = true, shimmer = true, glow = true, float = true, pulse = true }
local allowedKinds = { success = true, error = true, info = true, warning = true }
local backgroundExtensions = { png = true, jpg = true, jpeg = true, webp = true, gif = true }
local backgroundFits = { cover = true, contain = true, fill = true }
local backgroundPositions = { center = true, top = true, bottom = true, left = true, right = true }
local backgroundTints = { none = true, soft = true, medium = true, strong = true }
local backgroundMotions = { none = true, drift = true, pan = true, pulse = true }

local function safeString(value, fallback)
    if type(value) == 'string' and value ~= '' then
        return value
    end

    return fallback or ''
end

local function safeBackgroundFile(value)
    if type(value) ~= 'string' or #value < 5 or #value > 96 or value:find('..', 1, true) then
        return nil
    end
    if not value:match('^[a-z0-9][a-z0-9._-]+$') then
        return nil
    end
    local extension = value:match('%.([a-z0-9]+)$')
    return extension and backgroundExtensions[extension] and value or nil
end

local function backgroundDefinition(key)
    if type(key) ~= 'string' then
        return nil
    end
    local background = Config.Backgrounds and Config.Backgrounds[key]
    if type(background) ~= 'table' then
        return nil
    end
    local file = safeBackgroundFile(background.File)
    if not file then
        return nil
    end
    local fallback = safeBackgroundFile(background.Fallback)
    local animated = background.Animated == true or file:sub(-4) == '.gif'
    if not fallback and not animated then
        fallback = file
    end
    local opacity = tonumber(background.Opacity) or 0.65
    if opacity ~= opacity or opacity == math.huge or opacity == -math.huge then
        opacity = 0.65
    end

    return {
        file = file,
        fallback = fallback,
        animated = animated,
        fit = backgroundFits[background.Fit] and background.Fit or 'cover',
        position = backgroundPositions[background.Position] and background.Position or 'center',
        tint = backgroundTints[background.Tint] and background.Tint or 'medium',
        opacity = math.min(1.0, math.max(0.15, opacity)),
        motion = backgroundMotions[background.Motion] and background.Motion or 'none',
    }
end

local function safeInteger(value)
    local number = tonumber(value)
    if not number or number ~= number or number == math.huge or number == -math.huge then
        return nil
    end

    if number < 1 or number > 9007199254740991 or number ~= math.floor(number) then
        return nil
    end

    return number
end

local function timerElapsed(now, previous)
    local elapsed = now - previous
    if elapsed < 0 then
        elapsed = elapsed + 4294967296
    end
    return elapsed
end

local function syncServerClock(value)
    local epoch = tonumber(value)
    if not epoch or epoch ~= epoch or epoch == math.huge or epoch == -math.huge or epoch < 1 then
        return
    end
    serverEpoch = math.floor(epoch)
    serverEpochTimer = GetGameTimer()
end

local function currentServerTime()
    if serverEpoch < 1 then
        return nil
    end
    local elapsed = timerElapsed(GetGameTimer(), serverEpochTimer)
    return serverEpoch + math.floor(elapsed / 1000)
end

local function nuiMessage(action, payload)
    if not uiReady then
        return
    end

    local message = payload or {}
    message.action = action
    SendNUIMessage(message)
end

local function sortedDefinitions()
    local entries = {}

    for _, definition in pairs(worldDefinitions) do
        entries[#entries + 1] = definition
    end

    table.sort(entries, function(left, right)
        return left.serverId < right.serverId
    end)

    return entries
end

local function buildDefinition(state, fallbackServerId)
    if type(state) ~= 'table' then
        return nil
    end

    local serverId = safeInteger(fallbackServerId ~= nil and fallbackServerId or state.serverId)
    local grantId = safeInteger(state.grantId)
    local styleKey = type(state.styleKey) == 'string' and state.styleKey or nil
    local style = styleKey and Config.Styles and Config.Styles[styleKey] or nil

    if not serverId or not grantId or type(style) ~= 'table' then
        return nil
    end

    local toneKey = type(style.Tone) == 'string' and style.Tone or 'rose'
    local tone = Config.Tones and Config.Tones[toneKey] or nil

    if type(tone) ~= 'table' then
        toneKey = Config.Tones and Config.Tones.rose and 'rose' or next(Config.Tones or {})
        tone = toneKey and Config.Tones[toneKey] or {}
    end

    local symbol = allowedSymbols[style.Symbol] and style.Symbol or 'icon'
    local variant = allowedVariants[style.Variant] and style.Variant or 'candy'
    local font = allowedFonts[style.Font] and style.Font or 'body'
    local effect = allowedEffects[style.Effect] and style.Effect or 'none'
    local expiresAt = tonumber(state.expiresAt)

    if expiresAt then
        expiresAt = math.max(0, math.floor(expiresAt))
    end

    return {
        serverId = serverId,
        grantId = grantId,
        styleKey = styleKey,
        name = safeString(style.Name, styleKey),
        label = safeString(state.label, safeString(style.Label, styleKey)),
        subtitle = safeString(state.subtitle, safeString(style.Subtitle)),
        emoji = safeString(state.emoji, safeString(style.Emoji)),
        symbol = symbol,
        icon = safeString(style.Icon, 'tag'),
        variant = variant,
        tone = toneKey,
        font = font,
        effect = effect,
        background = backgroundDefinition(style.Background),
        uppercase = style.Uppercase == true,
        priority = tonumber(style.Priority) or 0,
        accent = safeString(tone.Accent),
        surface = safeString(tone.Surface),
        border = safeString(tone.Border),
        text = safeString(tone.Text),
        afk = state.afk == true,
        afkLabel = Bridge.T('afk_short'),
        afkIcon = safeString(Config.AFK and Config.AFK.Icon, 'moon'),
        afkEmoji = safeString(Config.AFK and Config.AFK.Emoji, '💤'),
        expiresAt = expiresAt,
        showServerId = renderConfig.ShowServerId == true,
    }
end

local function sendWorldSync()
    nuiMessage('worldSync', {
        revision = math.max(0, currentRevision),
        entries = sortedDefinitions(),
    })
end

local function acquirePanelFocus()
    if panelFocusOwned then
        return
    end

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    panelFocusOwned = true
end

local function releasePanelFocus()
    if not panelFocusOwned then
        return
    end

    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    panelFocusOwned = false
end

local function closePanel(immediate)
    panelGeneration = panelGeneration + 1
    panelOpen = false
    panelPayload = nil
    playerPayload = nil
    adminPayload = nil
    adminResultPayload = nil
    hasPlayerPayload = false
    hasAdminPayload = false
    hasAdminResultPayload = false
    pendingToasts = {}
    releasePanelFocus()

    if immediate then
        nuiMessage('resetPanel')
    else
        nuiMessage('close')
    end
end

local function replayUi()
    sendWorldSync()

    if panelOpen then
        nuiMessage('open', { payload = panelPayload })

        if hasPlayerPayload then
            nuiMessage('playerData', { payload = playerPayload })
        end

        if hasAdminPayload then
            nuiMessage('adminData', { payload = adminPayload })
        end

        if hasAdminResultPayload then
            nuiMessage('adminResult', adminResultPayload)
        end

        for index = 1, #pendingToasts do
            nuiMessage('toast', pendingToasts[index])
        end

        pendingToasts = {}
    else
        nuiMessage('resetPanel')
    end
end

local function frameworkNotification(message, kind)
    if Bridge.name == 'qbox' then
        local qboxKind = kind == 'info' and 'inform' or kind
        local ok = pcall(function()
            exports.qbx_core:Notify(message, qboxKind, 5000)
        end)

        if ok then
            return
        end
    elseif Bridge.name == 'qb' and Bridge.core and Bridge.core.Functions and Bridge.core.Functions.Notify then
        local qbKind = kind == 'info' and 'primary' or kind
        local ok = pcall(Bridge.core.Functions.Notify, message, qbKind, 5000)

        if ok then
            return
        end
    elseif Bridge.name == 'esx' and Bridge.core and Bridge.core.ShowNotification then
        local ok = pcall(Bridge.core.ShowNotification, message)

        if ok then
            return
        end
    end

    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
end

local function translate(key, args)
    if type(key) ~= 'string' or key == '' then
        return Bridge.T('invalid_request')
    end

    local ok, message

    if type(args) == 'table' then
        ok, message = pcall(Bridge.T, key, table.unpack(args))
    elseif args ~= nil then
        ok, message = pcall(Bridge.T, key, args)
    else
        ok, message = pcall(Bridge.T, key)
    end

    return ok and message or key
end

local function notify(kind, key, args)
    kind = allowedKinds[kind] and kind or 'info'
    local message = translate(key, args)
    local payload = { kind = kind, message = message }

    if panelOpen then
        if uiReady then
            nuiMessage('toast', payload)
        else
            pendingToasts[#pendingToasts + 1] = payload
            if #pendingToasts > 8 then
                table.remove(pendingToasts, 1)
            end
        end
    else
        frameworkNotification(message, kind)
    end
end

local function requestSnapshot(force)
    if not characterLoaded then
        return false
    end

    local now = GetGameTimer()
    if not force and timerElapsed(now, snapshotRequestedAt) < 1000 then
        return false
    end

    snapshotRequestedAt = now
    TriggerServerEvent('jrmy_tags:sv:requestSnapshot')
    return true
end

local function recoverSnapshot()
    if snapshotRecoveryActive then
        return
    end

    snapshotRecoveryActive = true
    snapshotRetryGeneration = snapshotRetryGeneration + 1
    local generation = snapshotRetryGeneration
    CreateThread(function()
        for _ = 1, 4 do
            if not characterLoaded or snapshotRetryGeneration ~= generation then
                return
            end
            requestSnapshot(false)
            Wait(1100)
        end
        if snapshotRetryGeneration == generation then
            snapshotRecoveryActive = false
        end
    end)
end

local function clearWorld(sendUi)
    worldDefinitions = {}
    candidates = {}
    currentRevision = -1
    emptyFrameSent = true

    if sendUi then
        sendWorldSync()
        nuiMessage('worldFrame', { entries = {} })
    end
end

local function loadCharacter()
    if characterLoaded then
        return
    end

    characterLoaded = true
    currentRevision = -1
    snapshotRequestedAt = 0
    snapshotRetryGeneration = snapshotRetryGeneration + 1
    snapshotRecoveryActive = false
    TriggerServerEvent('jrmy_tags:sv:ready')
end

local function unloadCharacter()
    if not characterLoaded then
        return
    end

    TriggerServerEvent('jrmy_tags:sv:unloaded')
    characterLoaded = false
    characterBlockedAt = GetGameTimer()
    snapshotRetryGeneration = snapshotRetryGeneration + 1
    snapshotRecoveryActive = false
    closePanel(true)
    clearWorld(true)
end

local function characterReady()
    Bridge.Resolve()

    if Bridge.name == 'qbox' or Bridge.name == 'qb' then
        local state = LocalPlayer and LocalPlayer.state
        if state and state.isLoggedIn ~= nil then
            return state.isLoggedIn == true
        end

        if Bridge.name == 'qb' and Bridge.core and Bridge.core.Functions and Bridge.core.Functions.GetPlayerData then
            local ok, data = pcall(Bridge.core.Functions.GetPlayerData)
            return ok and type(data) == 'table' and type(data.citizenid) == 'string' and data.citizenid ~= ''
        end

        return false
    end

    if Bridge.name == 'esx' and Bridge.core then
        if Bridge.core.IsPlayerLoaded then
            local ok, loaded = pcall(Bridge.core.IsPlayerLoaded)
            if ok then
                return loaded == true
            end
        end

        if Bridge.core.GetPlayerData then
            local ok, data = pcall(Bridge.core.GetPlayerData)
            return ok and type(data) == 'table' and type(data.identifier) == 'string' and data.identifier ~= ''
        end
    end

    return false
end

local function refreshPlayerCache(force)
    local now = GetGameTimer()
    if not force and timerElapsed(now, lastPlayerRefresh) < playerRefreshInterval then
        return
    end

    local refreshed = {}

    for _, player in ipairs(GetActivePlayers()) do
        local serverId = GetPlayerServerId(player)
        if serverId and serverId > 0 then
            refreshed[#refreshed + 1] = { player = player, serverId = serverId }
        end
    end

    playerCache = refreshed
    lastPlayerRefresh = now
end

local function rebuildCandidates()
    if not characterLoaded or next(worldDefinitions) == nil then
        candidates = {}
        return
    end

    refreshPlayerCache(false)

    local localPlayer = PlayerId()
    local localPed = PlayerPedId()
    if not DoesEntityExist(localPed) then
        candidates = {}
        return
    end

    local localCoords = GetEntityCoords(localPed)
    local nextCandidates = {}
    local currentTime = currentServerTime()

    for index = 1, #playerCache do
        local cached = playerCache[index]
        local definition = worldDefinitions[cached.serverId]

        if definition and (not currentTime or not definition.expiresAt or definition.expiresAt <= 0 or definition.expiresAt > currentTime) then
            local isSelf = cached.player == localPlayer

            if not isSelf or renderConfig.ShowSelf == true then
                local targetPed = GetPlayerPed(cached.player)

                local entityExists = DoesEntityExist(targetPed)
                local renderVisible = entityExists and (isSelf or renderConfig.HideInvisible ~= true or IsEntityVisible(targetPed) and GetEntityAlpha(targetPed) >= minimumAlpha)

                if renderVisible then
                    local targetCoords = GetEntityCoords(targetPed)
                    local dx = localCoords.x - targetCoords.x
                    local dy = localCoords.y - targetCoords.y
                    local dz = localCoords.z - targetCoords.z
                    local distanceSquared = dx * dx + dy * dy + dz * dz

                    if distanceSquared <= maxDistanceSquared then
                        local hasLineOfSight = isSelf or renderConfig.RequireLineOfSight ~= true or HasEntityClearLosToEntity(localPed, targetPed, 17)

                        if hasLineOfSight then
                            nextCandidates[#nextCandidates + 1] = {
                                player = cached.player,
                                serverId = cached.serverId,
                                ped = targetPed,
                                distanceSquared = distanceSquared,
                                isSelf = isSelf,
                                priority = definition.priority,
                                headBone = GetPedBoneIndex(targetPed, 31086),
                            }
                        end
                    end
                end
            end
        end
    end

    table.sort(nextCandidates, function(left, right)
        if left.isSelf ~= right.isSelf then
            return left.isSelf
        end

        if left.distanceSquared == right.distanceSquared then
            return left.priority > right.priority
        end

        return left.distanceSquared < right.distanceSquared
    end)

    while #nextCandidates > maxVisible do
        nextCandidates[#nextCandidates] = nil
    end

    candidates = nextCandidates
end

local function sendEmptyFrame()
    if emptyFrameSent then
        return
    end

    nuiMessage('worldFrame', { entries = {} })
    emptyFrameSent = true
end

local function renderFrame()
    if not uiReady or not characterLoaded or next(worldDefinitions) == nil then
        sendEmptyFrame()
        return
    end

    if renderConfig.HideWhenPaused == true and IsPauseMenuActive() then
        sendEmptyFrame()
        return
    end

    local localCoords = GetEntityCoords(PlayerPedId())
    local entries = {}

    for index = 1, #candidates do
        local candidate = candidates[index]
        local definition = worldDefinitions[candidate.serverId]
        local ped = candidate.ped

        if definition and DoesEntityExist(ped) then
            local targetCoords = GetEntityCoords(ped)
            local dx = localCoords.x - targetCoords.x
            local dy = localCoords.y - targetCoords.y
            local dz = localCoords.z - targetCoords.z
            local distanceSquared = dx * dx + dy * dy + dz * dz

            if distanceSquared <= maxDistanceSquared then
                local headCoords

                if candidate.headBone and candidate.headBone ~= -1 then
                    headCoords = GetWorldPositionOfEntityBone(ped, candidate.headBone)
                    headCoords = vector3(headCoords.x, headCoords.y, headCoords.z + headOffset)
                else
                    headCoords = vector3(targetCoords.x, targetCoords.y, targetCoords.z + 1.0 + headOffset)
                end

                local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(headCoords.x, headCoords.y, headCoords.z)

                if onScreen then
                    local ratio = math.min(1.0, math.sqrt(distanceSquared) / maxDistance)
                    local scale = 1.0 - ratio * (1.0 - minScale)
                    local opacity = 1.0

                    if ratio > fadeStart then
                        opacity = math.max(0.06, 1.0 - ((ratio - fadeStart) / (1.0 - fadeStart)))
                    end

                    entries[#entries + 1] = {
                        serverId = candidate.serverId,
                        x = screenX,
                        y = screenY,
                        scale = scale,
                        opacity = opacity,
                        talking = renderConfig.VoiceIndicator == true and NetworkIsPlayerTalking(candidate.player) or false,
                    }
                end
            end
        end
    end

    if #entries == 0 then
        sendEmptyFrame()
    else
        nuiMessage('worldFrame', { entries = entries })
        emptyFrameSent = false
    end
end

local function requestPlayerPanel()
    if not characterLoaded then
        notify('error', 'identity_unavailable')
        return false
    end

    TriggerServerEvent('jrmy_tags:sv:openPlayer')
    return true
end

local function requestAdminPanel()
    if not characterLoaded then
        notify('error', 'identity_unavailable')
        return false
    end

    TriggerServerEvent('jrmy_tags:sv:openAdmin')
    return true
end

local function toggleVisibility(desired)
    if not characterLoaded then
        notify('error', 'identity_unavailable')
        return false
    end
    if desired ~= nil and type(desired) ~= 'boolean' then
        return false
    end

    TriggerServerEvent('jrmy_tags:sv:toggle', desired)
    return true
end

local function toggleAfk(desired)
    if not characterLoaded or not Config.AFK or Config.AFK.Enabled ~= true then
        return false
    end
    if desired ~= nil and type(desired) ~= 'boolean' then
        return false
    end

    TriggerServerEvent('jrmy_tags:sv:setAfk', desired)
    return true
end

RegisterNetEvent('jrmy_tags:cl:snapshot', function(revision, states, serverTime)
    if not characterLoaded then
        return
    end

    revision = tonumber(revision)
    if not revision then
        recoverSnapshot()
        return
    end

    revision = math.max(0, math.floor(revision))
    if revision < currentRevision then
        return
    end
    snapshotRetryGeneration = snapshotRetryGeneration + 1
    snapshotRecoveryActive = false
    syncServerClock(serverTime)

    local nextDefinitions = {}

    if type(states) == 'table' then
        for _, state in pairs(states) do
            local definition = buildDefinition(state)
            if definition then
                nextDefinitions[definition.serverId] = definition
            end
        end
    end

    worldDefinitions = nextDefinitions
    currentRevision = revision
    candidates = {}
    refreshPlayerCache(true)
    rebuildCandidates()
    sendWorldSync()
end)

RegisterNetEvent('jrmy_tags:cl:delta', function(revision, serverId, state, serverTime)
    if not characterLoaded then
        return
    end

    revision = tonumber(revision)
    serverId = safeInteger(serverId)

    if not revision or not serverId then
        recoverSnapshot()
        return
    end

    revision = math.max(0, math.floor(revision))

    if revision <= currentRevision then
        return
    end

    if currentRevision < 0 or revision ~= currentRevision + 1 then
        recoverSnapshot()
        return
    end
    syncServerClock(serverTime)

    if state == nil then
        currentRevision = revision
        worldDefinitions[serverId] = nil
        nuiMessage('worldRemove', { revision = revision, serverId = serverId })
    else
        local definition = buildDefinition(state, serverId)
        if not definition then
            recoverSnapshot()
            return
        end

        currentRevision = revision
        worldDefinitions[serverId] = definition
        nuiMessage('worldSet', { revision = revision, entry = definition })
    end

end)

RegisterNetEvent('jrmy_tags:cl:open', function(payload)
    if not characterLoaded or type(payload) ~= 'table' or payload.mode ~= 'player' and payload.mode ~= 'admin' then
        return
    end

    panelGeneration = panelGeneration + 1
    local generation = panelGeneration
    panelPayload = payload
    playerPayload = nil
    adminPayload = nil
    adminResultPayload = nil
    hasPlayerPayload = false
    hasAdminPayload = false
    hasAdminResultPayload = false
    pendingToasts = {}
    panelOpen = true
    nuiMessage('open', { payload = panelPayload })

    CreateThread(function()
        Wait(3000)
        if panelOpen and panelGeneration == generation and not panelFocusOwned then
            closePanel(true)
        end
    end)
end)

RegisterNetEvent('jrmy_tags:cl:playerData', function(payload)
    if not characterLoaded or type(payload) ~= 'table' then
        return
    end
    playerPayload = payload
    hasPlayerPayload = true
    nuiMessage('playerData', { payload = playerPayload })
end)

RegisterNetEvent('jrmy_tags:cl:adminData', function(payload)
    if not characterLoaded or type(payload) ~= 'table' then
        return
    end
    adminPayload = payload
    hasAdminPayload = true
    nuiMessage('adminData', { payload = adminPayload })
end)

RegisterNetEvent('jrmy_tags:cl:adminResult', function(operation, ok)
    adminResultPayload = { operation = safeString(operation, 'unknown'), ok = ok == true }
    hasAdminResultPayload = true
    nuiMessage('adminResult', adminResultPayload)
end)

RegisterNetEvent('jrmy_tags:cl:notify', function(kind, key, args)
    notify(kind, key, args)
end)

RegisterNUICallback('ready', function(_, callback)
    uiReady = true
    replayUi()

    if characterLoaded then
        requestSnapshot(false)
    end

    callback({ ok = true })
end)

RegisterNUICallback('opened', function(_, callback)
    local accepted = characterLoaded and panelOpen and uiReady
    if accepted then
        acquirePanelFocus()
    end
    callback({ ok = accepted })
end)

RegisterNUICallback('close', function(_, callback)
    closePanel(false)
    callback({ ok = true })
end)

RegisterNUICallback('select', function(data, callback)
    local grantId = type(data) == 'table' and safeInteger(data.grantId or data.id) or nil
    local accepted = characterLoaded and grantId ~= nil

    if accepted then
        TriggerServerEvent('jrmy_tags:sv:select', grantId)
    end

    callback({ ok = accepted })
end)

RegisterNUICallback('toggleVisibility', function(data, callback)
    local desired = nil
    if type(data) == 'table' and type(data.visible) == 'boolean' then
        desired = data.visible
    end
    callback({ ok = toggleVisibility(desired) })
end)

RegisterNUICallback('toggleAfk', function(data, callback)
    local desired = nil
    if type(data) == 'table' and type(data.afk) == 'boolean' then
        desired = data.afk
    end
    callback({ ok = toggleAfk(desired) })
end)

RegisterNUICallback('adminRefresh', function(data, callback)
    local accepted = characterLoaded and panelOpen

    if accepted then
        TriggerServerEvent('jrmy_tags:sv:adminRefresh', type(data) == 'table' and data or {})
    end

    callback({ ok = accepted })
end)

RegisterNUICallback('adminSave', function(data, callback)
    local accepted = characterLoaded and panelOpen and type(data) == 'table'

    if accepted then
        TriggerServerEvent('jrmy_tags:sv:adminSave', data)
    end

    callback({ ok = accepted })
end)

RegisterNUICallback('adminDelete', function(data, callback)
    local accepted = characterLoaded and panelOpen and type(data) == 'table'

    if accepted then
        TriggerServerEvent('jrmy_tags:sv:adminDelete', data)
    end

    callback({ ok = accepted })
end)

local commands = Config.Commands or {}

if type(commands.Player) == 'string' and commands.Player ~= '' then
    RegisterCommand(commands.Player, requestPlayerPanel, false)
end

if type(commands.Toggle) == 'string' and commands.Toggle ~= '' then
    RegisterCommand(commands.Toggle, function()
        toggleVisibility()
    end, false)
end

if type(commands.Admin) == 'string' and commands.Admin ~= '' then
    RegisterCommand(commands.Admin, requestAdminPanel, false)
end

if Config.AFK and Config.AFK.Enabled == true and type(commands.AFK) == 'string' and commands.AFK ~= '' then
    RegisterCommand(commands.AFK, function()
        toggleAfk()
    end, false)
end

if type(Config.OpenKey) == 'string' and Config.OpenKey ~= '' and type(commands.Player) == 'string' and commands.Player ~= '' then
    RegisterKeyMapping(commands.Player, Bridge.T('key_mapping'), 'keyboard', Config.OpenKey)
end

exports('OpenPlayer', requestPlayerPanel)
exports('OpenAdmin', requestAdminPanel)
exports('ToggleVisibility', toggleVisibility)
exports('ToggleAFK', toggleAfk)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Bridge.Resolve()
    if Bridge.name == 'qbox' or Bridge.name == 'qb' then
        loadCharacter()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if Bridge.name == 'qbox' or Bridge.name == 'qb' then
        unloadCharacter()
    end
end)

RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
    if Bridge.name == 'qbox' then
        unloadCharacter()
    end
end)

RegisterNetEvent('esx:playerLoaded', function()
    Bridge.Resolve()
    if Bridge.name == 'esx' then
        loadCharacter()
    end
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    if Bridge.name == 'esx' then
        unloadCharacter()
    end
end)

AddEventHandler('onClientResourceStop', function(stoppedResource)
    if stoppedResource ~= resourceName then
        return
    end

    if characterLoaded then
        TriggerServerEvent('jrmy_tags:sv:unloaded')
    end

    panelOpen = false
    releasePanelFocus()
    SendNUIMessage({ action = 'resetPanel' })
end)

CreateThread(function()
    while true do
        local ready = characterReady()

        if ready then
            readinessMisses = 0
            if not characterLoaded and timerElapsed(GetGameTimer(), characterBlockedAt) >= 4000 then
                loadCharacter()
            end
        elseif characterLoaded then
            readinessMisses = readinessMisses + 1
            if readinessMisses >= 3 then
                readinessMisses = 0
                unloadCharacter()
            end
        else
            readinessMisses = 0
        end

        Wait(characterLoaded and 1000 or 250)
    end
end)

CreateThread(function()
    while true do
        if characterLoaded and next(worldDefinitions) ~= nil then
            rebuildCandidates()
            Wait(candidateInterval)
        else
            candidates = {}
            Wait(idleInterval)
        end
    end
end)

CreateThread(function()
    while true do
        if characterLoaded and next(worldDefinitions) ~= nil and #candidates > 0 then
            renderFrame()
            Wait(positionInterval)
        elseif characterLoaded and next(worldDefinitions) ~= nil then
            sendEmptyFrame()
            Wait(candidateInterval)
        else
            sendEmptyFrame()
            Wait(idleInterval)
        end
    end
end)
