local databaseReady = false
local namespaceValue = nil
local revision = 0
local tokenSequence = 0
local limits = {}
local identityLocks = {}
local identityLockDepth = {}
local sourceIdentities = {}
local hydratedSources = {}
local activeStates = {}
local afkStates = {}
local adminSessions = {}
local pendingReady = {}
local pendingRecoveries = {}
local sourceCycles = {}

local function debugLog(value)
    if Config.Debug then
        print(('^5[jrmy_tags]^7 %s'):format(tostring(value)))
    end
end

local function trim(value)
    if type(value) ~= 'string' then
        return ''
    end

    return value:match('^%s*(.-)%s*$') or ''
end

local function cleanText(value, maximum)
    if value == nil then
        return nil
    end
    if type(value) ~= 'string' then
        return false
    end

    value = trim(value:gsub('[%z\1-\31\127]', ''))
    if value == '' then
        return nil
    end
    if value:find('[<>]') then
        return false
    end

    local ok, length = pcall(utf8.len, value)
    if not ok or not length then
        return false
    end
    if length > maximum then
        local boundary = utf8.offset(value, maximum + 1)
        if boundary then
            value = value:sub(1, boundary - 1)
        end
    end

    return value
end

local function positiveInteger(value)
    local number = tonumber(value)
    if not number or number ~= number or number == math.huge or number == -math.huge then
        return nil
    end
    if number < 1 or number > 9007199254740991 or number ~= math.floor(number) then
        return nil
    end
    return number
end

local function databaseBoolean(value)
    return value == true or value == 1 or value == '1'
end

local function stableHash(value)
    local first = 5381
    local second = 52711
    for index = 1, #value do
        local byte = value:byte(index)
        first = (first * 33 + byte) % 4294967296
        second = (second * 65599 + byte + index) % 4294967296
    end

    return ('%08x%08x'):format(first, second)
end

local function storageNamespace()
    if namespaceValue then
        return namespaceValue
    end

    local seed = trim(tostring(Config.StorageNamespace or ''))
    if seed == '' then
        seed = trim(GetConvar('sv_licenseKey', ''))
    end
    if seed == '' then
        seed = trim(GetConvar('sv_projectName', ''))
    end
    if seed == '' then
        seed = GetCurrentResourceName()
    end

    namespaceValue = stableHash(seed)
    return namespaceValue
end

local function licenseOf(sourceId)
    for _, identifier in ipairs(GetPlayerIdentifiers(sourceId)) do
        if identifier:sub(1, 8) == 'license:' then
            return identifier
        end
    end

    return nil
end

local function characterName(data, fallback)
    local info = data and data.charinfo
    if type(info) == 'table' then
        local first = cleanText(info.firstname, 40)
        local last = cleanText(info.lastname, 40)
        local name = trim(('%s %s'):format(first or '', last or ''))
        if name ~= '' then
            return cleanText(name, 80) or fallback
        end
    end

    return cleanText(fallback, 80) or 'Player'
end

local function identityOf(sourceId)
    sourceId = tonumber(sourceId)
    if not sourceId or sourceId < 1 or not GetPlayerName(sourceId) then
        return nil
    end

    if Config.IdentityScope == 'license' then
        local identifier = licenseOf(sourceId)
        if not identifier then
            return nil
        end

        return {
            type = 'license',
            identifier = identifier,
            name = cleanText(GetPlayerName(sourceId), 80) or 'Player',
        }
    end

    if not Bridge.name then
        Bridge.Resolve()
    end

    if Bridge.name == 'qbox' then
        local ok, player = pcall(function()
            return exports.qbx_core:GetPlayer(sourceId)
        end)
        local data = ok and player and player.PlayerData
        if data and data.citizenid then
            return {
                type = 'character',
                identifier = tostring(data.citizenid),
                name = characterName(data, GetPlayerName(sourceId)),
            }
        end
    elseif Bridge.name == 'qb' and Bridge.core and Bridge.core.Functions then
        local player = Bridge.core.Functions.GetPlayer(sourceId)
        local data = player and player.PlayerData
        if data and data.citizenid then
            return {
                type = 'character',
                identifier = tostring(data.citizenid),
                name = characterName(data, GetPlayerName(sourceId)),
            }
        end
    elseif Bridge.name == 'esx' and Bridge.core then
        local player = Bridge.core.GetPlayerFromId(sourceId)
        if player then
            local okIdentifier, identifier = pcall(function()
                return player.getIdentifier()
            end)
            if not okIdentifier or not identifier then
                identifier = player.identifier
            end
            if identifier then
                local okName, name = pcall(function()
                    return player.getName()
                end)
                return {
                    type = 'character',
                    identifier = tostring(identifier),
                    name = cleanText(okName and name or GetPlayerName(sourceId), 80) or 'Player',
                }
            end
        end
    end

    return nil
end

local function identityKey(identity)
    return identity.type .. '\0' .. identity.identifier
end

local function sameIdentity(first, second)
    return first and second and first.type == second.type and first.identifier == second.identifier
end

local function cloneIdentity(identity)
    return {
        type = identity.type,
        identifier = identity.identifier,
        name = identity.name,
    }
end

local function frameworkAdmin(sourceId)
    if not Bridge.name then
        Bridge.Resolve()
    end

    if Bridge.name == 'qbox' then
        for group, enabled in pairs(Config.AdminGroups or {}) do
            if enabled then
                local okPermission, allowedPermission = pcall(function()
                    return exports.qbx_core:HasPermission(sourceId, group)
                end)
                if okPermission and allowedPermission then
                    return true
                end
            end
        end
    elseif Bridge.name == 'qb' and Bridge.core and Bridge.core.Functions and Bridge.core.Functions.HasPermission then
        for group, enabled in pairs(Config.AdminGroups or {}) do
            if enabled then
                local ok, allowed = pcall(function()
                    return Bridge.core.Functions.HasPermission(sourceId, group)
                end)
                if ok and allowed then
                    return true
                end
            end
        end
    elseif Bridge.name == 'esx' and Bridge.core then
        local player = Bridge.core.GetPlayerFromId(sourceId)
        if player then
            local ok, group = pcall(function()
                return player.getGroup()
            end)
            if ok and Config.AdminGroups and Config.AdminGroups[group] then
                return true
            end
        end
    end

    return false
end

local function isAdmin(sourceId)
    sourceId = tonumber(sourceId)
    if not sourceId or sourceId < 1 or not GetPlayerName(sourceId) then
        return false
    end
    if type(Config.AdminAce) == 'string' and Config.AdminAce ~= '' and IsPlayerAceAllowed(sourceId, Config.AdminAce) then
        return true
    end

    local ok, allowed = pcall(frameworkAdmin, sourceId)
    return ok and allowed == true
end

local function notify(sourceId, kind, key, ...)
    TriggerClientEvent('jrmy_tags:cl:notify', sourceId, kind, key, { ... })
end

local function timerElapsed(now, previous)
    local elapsed = now - previous
    if elapsed < 0 then
        elapsed = elapsed + 4294967296
    end
    return elapsed
end

local function limited(sourceId, action, milliseconds)
    local now = GetGameTimer()
    limits[sourceId] = limits[sourceId] or {}
    local bucket = limits[sourceId]
    local previous = bucket[action]
    if previous and timerElapsed(now, previous) < milliseconds then
        local shouldRespond = not bucket.noticeAll or timerElapsed(now, bucket.noticeAll) >= 1000
        if shouldRespond then
            bucket.noticeAll = now
        end
        return true, shouldRespond
    end
    if bucket.all and timerElapsed(now, bucket.all) < 400 then
        local shouldRespond = not bucket.noticeAll or timerElapsed(now, bucket.noticeAll) >= 1000
        if shouldRespond then
            bucket.noticeAll = now
        end
        return true, shouldRespond
    end

    bucket[action] = now
    bucket.all = now
    return false, false
end

local function cycleOf(sourceId)
    return sourceCycles[sourceId] or 0
end

local function cycleMatches(sourceId, cycle)
    return cycleOf(sourceId) == cycle and GetPlayerName(sourceId) ~= nil
end

local function newToken(prefix, sourceId)
    tokenSequence = tokenSequence + 1
    return ('%s:%s:%s:%s:%s'):format(prefix, sourceId, GetGameTimer(), tokenSequence, math.random(100000, 999999))
end

local function withIdentityLock(identity, callable)
    local key = identityKey(identity)
    local depth = (identityLockDepth[key] or 0) + 1
    if depth > 6 then
        return false
    end
    identityLockDepth[key] = depth
    local previous = identityLocks[key]
    local gate = promise.new()
    identityLocks[key] = gate

    if previous then
        Citizen.Await(previous)
    end

    local results = table.pack(pcall(callable))
    gate:resolve(true)
    identityLockDepth[key] = math.max(0, (identityLockDepth[key] or 1) - 1)
    if identityLockDepth[key] == 0 then
        identityLockDepth[key] = nil
    end
    if identityLocks[key] == gate then
        identityLocks[key] = nil
    end

    if not results[1] then
        print(('^1[jrmy_tags]^7 %s'):format(tostring(results[2])))
        return false
    end

    return true, table.unpack(results, 2, results.n)
end

local function stylePriority(styleKey)
    local style = Config.Styles and Config.Styles[styleKey]
    return tonumber(style and style.Priority) or 0
end

local backgroundExtensions = {
    png = true,
    jpg = true,
    jpeg = true,
    webp = true,
    gif = true,
}

local backgroundFits = { cover = true, contain = true, fill = true }
local backgroundPositions = { center = true, top = true, bottom = true, left = true, right = true }
local backgroundTints = { none = true, soft = true, medium = true, strong = true }
local backgroundMotions = { none = true, drift = true, pan = true, pulse = true }

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

local function backgroundPayload(key)
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
    local fit = backgroundFits[background.Fit] and background.Fit or 'cover'
    local position = backgroundPositions[background.Position] and background.Position or 'center'
    local tint = backgroundTints[background.Tint] and background.Tint or 'medium'
    local motion = backgroundMotions[background.Motion] and background.Motion or 'none'
    local opacity = tonumber(background.Opacity) or 0.65
    if opacity ~= opacity or opacity == math.huge or opacity == -math.huge then
        opacity = 0.65
    end
    opacity = math.min(1.0, math.max(0.15, opacity))

    return {
        file = file,
        fallback = fallback,
        animated = animated,
        fit = fit,
        position = position,
        tint = tint,
        opacity = opacity,
        motion = motion,
    }
end

local function stylesPayload()
    local styles = {}
    for key, style in pairs(Config.Styles or {}) do
        local toneKey = tostring(style.Tone or 'rose')
        local tone = Config.Tones and Config.Tones[toneKey] or nil
        if type(tone) ~= 'table' then
            toneKey = Config.Tones and Config.Tones.rose and 'rose' or next(Config.Tones or {})
            tone = toneKey and Config.Tones[toneKey] or {}
        end
        styles[#styles + 1] = {
            key = key,
            name = tostring(style.Name or style.Label or key),
            label = tostring(style.Label or style.Name or key),
            subtitle = tostring(style.Subtitle or ''),
            symbol = tostring(style.Symbol or 'icon'),
            icon = tostring(style.Icon or 'tag'),
            emoji = tostring(style.Emoji or ''),
            variant = tostring(style.Variant or 'candy'),
            tone = toneKey,
            font = tostring(style.Font or 'body'),
            effect = tostring(style.Effect or 'none'),
            background = backgroundPayload(style.Background),
            uppercase = style.Uppercase == true,
            priority = tonumber(style.Priority) or 0,
            colors = {
                accent = tostring(tone.Accent or ''),
                surface = tostring(tone.Surface or ''),
                border = tostring(tone.Border or ''),
                text = tostring(tone.Text or ''),
            },
        }
    end

    table.sort(styles, function(first, second)
        if first.priority == second.priority then
            return first.key < second.key
        end
        return first.priority > second.priority
    end)

    return styles
end

local function createTables()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `jrmy_tags_grants` (
            `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            `namespace` CHAR(16) COLLATE utf8mb4_bin NOT NULL,
            `owner_type` VARCHAR(16) COLLATE utf8mb4_bin NOT NULL,
            `owner_identifier` VARCHAR(96) COLLATE utf8mb4_bin NOT NULL,
            `owner_name` VARCHAR(80) NOT NULL,
            `style_key` VARCHAR(48) COLLATE utf8mb4_bin NOT NULL,
            `label` VARCHAR(48) NOT NULL,
            `subtitle` VARCHAR(64) DEFAULT NULL,
            `emoji` VARCHAR(32) DEFAULT NULL,
            `granted_by_type` VARCHAR(16) COLLATE utf8mb4_bin NOT NULL,
            `granted_by_identifier` VARCHAR(96) COLLATE utf8mb4_bin NOT NULL,
            `granted_by_name` VARCHAR(80) NOT NULL,
            `expires_at` BIGINT UNSIGNED DEFAULT NULL,
            `granted_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `owner_style` (`namespace`, `owner_type`, `owner_identifier`, `style_key`),
            KEY `owner_active` (`namespace`, `owner_type`, `owner_identifier`, `expires_at`),
            KEY `style_active` (`namespace`, `style_key`, `expires_at`),
            KEY `owner_name` (`namespace`, `owner_name`),
            KEY `expiry_sweep` (`namespace`, `expires_at`),
            KEY `admin_recent` (`namespace`, `updated_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `jrmy_tags_profiles` (
            `namespace` CHAR(16) COLLATE utf8mb4_bin NOT NULL,
            `owner_type` VARCHAR(16) COLLATE utf8mb4_bin NOT NULL,
            `owner_identifier` VARCHAR(96) COLLATE utf8mb4_bin NOT NULL,
            `selected_grant_id` BIGINT UNSIGNED DEFAULT NULL,
            `visible` TINYINT(1) NOT NULL DEFAULT 0,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`namespace`, `owner_type`, `owner_identifier`),
            KEY `selected_grant` (`selected_grant_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `jrmy_tags_audit` (
            `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            `namespace` CHAR(16) COLLATE utf8mb4_bin NOT NULL,
            `action` VARCHAR(24) COLLATE utf8mb4_bin NOT NULL,
            `actor_type` VARCHAR(16) COLLATE utf8mb4_bin NOT NULL,
            `actor_identifier` VARCHAR(96) COLLATE utf8mb4_bin NOT NULL,
            `actor_name` VARCHAR(80) NOT NULL,
            `target_type` VARCHAR(16) COLLATE utf8mb4_bin NOT NULL,
            `target_identifier` VARCHAR(96) COLLATE utf8mb4_bin NOT NULL,
            `target_name` VARCHAR(80) NOT NULL,
            `grant_id` BIGINT UNSIGNED DEFAULT NULL,
            `style_key` VARCHAR(48) COLLATE utf8mb4_bin DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `target_history` (`namespace`, `target_type`, `target_identifier`, `created_at`),
            KEY `actor_history` (`namespace`, `actor_type`, `actor_identifier`, `created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end

local function writeProfile(identity, selectedId, visible)
    MySQL.query.await([[
        INSERT INTO jrmy_tags_profiles
            (namespace, owner_type, owner_identifier, selected_grant_id, visible)
        VALUES (?, ?, ?, NULLIF(?, 0), ?)
        ON DUPLICATE KEY UPDATE
            selected_grant_id = VALUES(selected_grant_id),
            visible = VALUES(visible)
    ]], {
        storageNamespace(), identity.type, identity.identifier,
        tonumber(selectedId) or 0, visible and 1 or 0,
    })
end

local function queryGrants(identity)
    local rows = MySQL.query.await([[
        SELECT id, owner_name, style_key, label, subtitle, emoji, expires_at, granted_at
        FROM jrmy_tags_grants
        WHERE namespace = ? AND owner_type = ? AND owner_identifier = ?
          AND (expires_at IS NULL OR expires_at > ?)
    ]], { storageNamespace(), identity.type, identity.identifier, os.time() }) or {}
    local grants = {}

    for _, row in ipairs(rows) do
        if Config.Styles and Config.Styles[row.style_key] then
            row.id = tonumber(row.id)
            row.expires_at = tonumber(row.expires_at)
            grants[#grants + 1] = row
        end
    end

    table.sort(grants, function(first, second)
        local firstPriority = stylePriority(first.style_key)
        local secondPriority = stylePriority(second.style_key)
        if firstPriority == secondPriority then
            return first.id < second.id
        end
        return firstPriority > secondPriority
    end)

    return grants
end

local function findGrant(grants, grantId)
    grantId = tonumber(grantId)
    for _, grant in ipairs(grants) do
        if grant.id == grantId then
            return grant
        end
    end

    return nil
end

local function loadCollection(identity)
    local grants = queryGrants(identity)
    local rows = MySQL.query.await([[
        SELECT selected_grant_id, visible
        FROM jrmy_tags_profiles
        WHERE namespace = ? AND owner_type = ? AND owner_identifier = ?
        LIMIT 1
    ]], { storageNamespace(), identity.type, identity.identifier }) or {}
    local row = rows[1]
    local selectedId = row and tonumber(row.selected_grant_id) or nil
    local storedSelectedId = selectedId
    local storedVisible = row and databaseBoolean(row.visible) or false
    local visible = storedVisible
    local selected = findGrant(grants, selectedId)

    if not selected then
        selected = grants[1]
        selectedId = selected and selected.id or nil
        if not selected then
            visible = false
        elseif not row or not storedSelectedId then
            visible = Config.DefaultVisible == true
        end
        if not row or storedSelectedId ~= selectedId or storedVisible ~= visible then
            writeProfile(identity, selectedId, visible)
        end
    end

    return grants, {
        selectedId = selectedId,
        visible = visible,
    }
end

local function grantPayload(grant, selectedId)
    return {
        id = grant.id,
        styleKey = grant.style_key,
        label = tostring(grant.label or ''),
        subtitle = tostring(grant.subtitle or ''),
        emoji = tostring(grant.emoji or ''),
        expiresAt = tonumber(grant.expires_at) or false,
        selected = grant.id == tonumber(selectedId),
    }
end

local function stateEqual(first, second)
    if first == second then
        return true
    end
    if not first or not second then
        return false
    end

    return first.serverId == second.serverId
        and first.grantId == second.grantId
        and first.styleKey == second.styleKey
        and first.label == second.label
        and first.subtitle == second.subtitle
        and first.emoji == second.emoji
        and first.afk == second.afk
        and first.expiresAt == second.expiresAt
end

local function publishState(sourceId, state)
    local previous = activeStates[sourceId]
    if stateEqual(previous, state) then
        return
    end

    activeStates[sourceId] = state
    revision = revision + 1
    TriggerClientEvent('jrmy_tags:cl:delta', -1, revision, sourceId, state, os.time())
end

local function refreshSource(sourceId, identity, grants, profile)
    if not GetPlayerName(sourceId) then
        publishState(sourceId, nil)
        hydratedSources[sourceId] = nil
        return false
    end

    local current = identityOf(sourceId)
    if not sameIdentity(current, identity) then
        publishState(sourceId, nil)
        sourceIdentities[sourceId] = nil
        hydratedSources[sourceId] = nil
        afkStates[sourceId] = nil
        adminSessions[sourceId] = nil
        return false
    end

    sourceIdentities[sourceId] = cloneIdentity(identity)
    hydratedSources[sourceId] = cycleOf(sourceId)
    local selected = profile.visible and findGrant(grants, profile.selectedId) or nil
    if not selected then
        publishState(sourceId, nil)
        return true
    end

    publishState(sourceId, {
        serverId = sourceId,
        grantId = selected.id,
        styleKey = selected.style_key,
        label = tostring(selected.label or ''),
        subtitle = tostring(selected.subtitle or ''),
        emoji = tostring(selected.emoji or ''),
        afk = afkStates[sourceId] == true,
        expiresAt = tonumber(selected.expires_at) or false,
    })
    return true
end

local function sendSnapshot(sourceId)
    local states = {}
    for _, state in pairs(activeStates) do
        states[#states + 1] = state
    end
    table.sort(states, function(first, second)
        return first.serverId < second.serverId
    end)
    TriggerClientEvent('jrmy_tags:cl:snapshot', sourceId, revision, states, os.time())
end

local function writeAudit(action, actor, target, grantId, styleKey)
    local ok, errorValue = pcall(function()
        MySQL.insert.await([[
            INSERT INTO jrmy_tags_audit
                (namespace, action, actor_type, actor_identifier, actor_name,
                 target_type, target_identifier, target_name, grant_id, style_key)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, NULLIF(?, 0), NULLIF(?, ''))
        ]], {
            storageNamespace(), action,
            actor.type, actor.identifier, actor.name,
            target.type, target.identifier, target.name,
            tonumber(grantId) or 0, styleKey or '',
        })
    end)
    if not ok then
        print(('^1[jrmy_tags]^7 %s'):format(tostring(errorValue)))
    end
end

local function playerPayload(sourceId, identity, grants, profile)
    local collection = {}
    for _, grant in ipairs(grants) do
        collection[#collection + 1] = grantPayload(grant, profile.selectedId)
    end

    return {
        mode = 'player',
        locale = Config.Locale,
        strings = Bridge.UI(),
        styles = stylesPayload(),
        grants = collection,
        player = {
            name = identity.name,
            visible = profile.visible == true,
            afk = afkStates[sourceId] == true,
            selectedId = tonumber(profile.selectedId) or false,
        },
        isAdmin = isAdmin(sourceId),
        afkEnabled = Config.AFK and Config.AFK.Enabled == true,
    }
end

local function activeSourcesFor(identity)
    local sources = {}
    local key = identityKey(identity)
    for sourceId, current in pairs(sourceIdentities) do
        if identityKey(current) == key and GetPlayerName(sourceId) then
            sources[#sources + 1] = sourceId
        end
    end
    return sources
end

local function refreshIdentitySources(identity, grants, profile)
    for _, sourceId in ipairs(activeSourcesFor(identity)) do
        refreshSource(sourceId, identity, grants, profile)
    end
end

local function recoverIdentity(identity)
    local key = identityKey(identity)
    local ok, grants, profile = withIdentityLock(identity, function()
        return loadCollection(identity)
    end)
    if ok then
        pendingRecoveries[key] = nil
        refreshIdentitySources(identity, grants, profile)
    else
        pendingRecoveries[key] = cloneIdentity(identity)
    end
    return ok
end

local function clearSource(sourceId, dropped)
    sourceId = tonumber(sourceId)
    if not sourceId then
        return
    end

    publishState(sourceId, nil)
    sourceIdentities[sourceId] = nil
    hydratedSources[sourceId] = nil
    afkStates[sourceId] = nil
    adminSessions[sourceId] = nil
    if dropped then
        limits[sourceId] = nil
    end
    pendingReady[sourceId] = nil
    sourceCycles[sourceId] = cycleOf(sourceId) + 1
end

local function sessionFor(sourceId, supplied)
    local session = adminSessions[sourceId]
    if type(supplied) ~= 'string' or not session or session.token ~= supplied then
        return nil
    end
    if os.time() > session.expiresAt then
        adminSessions[sourceId] = nil
        return nil
    end
    if session.cycle ~= cycleOf(sourceId) then
        adminSessions[sourceId] = nil
        return nil
    end
    if not isAdmin(sourceId) then
        adminSessions[sourceId] = nil
        return nil
    end

    local identity = identityOf(sourceId)
    if not sameIdentity(identity, session.identity) then
        adminSessions[sourceId] = nil
        return nil
    end

    session.expiresAt = os.time() + math.ceil(session.duration / 1000)
    return session, identity
end

local function actorCurrent(sourceId, cycle, identity, session)
    if not cycleMatches(sourceId, cycle) then
        return false
    end
    if session then
        local current, currentIdentity = sessionFor(sourceId, session.token)
        return current == session and sameIdentity(currentIdentity, identity)
    end
    return sameIdentity(identityOf(sourceId), identity)
end

local function newAdminSession(sourceId, identity)
    local duration = math.max(30000, math.min(600000, tonumber(Config.AdminSessionDuration) or 120000))
    local session = {
        token = newToken('admin', sourceId),
        expiresAt = os.time() + math.ceil(duration / 1000),
        duration = duration,
        cycle = cycleOf(sourceId),
        identity = cloneIdentity(identity),
        targets = {},
    }
    adminSessions[sourceId] = session
    return session
end

local function adminRows()
    local limit = math.max(1, math.min(2000, math.floor(tonumber(Config.AdminListLimit) or 500)))
    return MySQL.query.await([[
        SELECT g.id, g.owner_type, g.owner_identifier, g.owner_name, g.style_key,
               g.label, g.subtitle, g.emoji, g.expires_at, g.granted_at,
               p.selected_grant_id, p.visible
        FROM jrmy_tags_grants g
        LEFT JOIN jrmy_tags_profiles p
          ON p.namespace = g.namespace
         AND p.owner_type = g.owner_type
         AND p.owner_identifier = g.owner_identifier
        WHERE g.namespace = ? AND (g.expires_at IS NULL OR g.expires_at > ?)
        ORDER BY g.updated_at DESC, g.id DESC
        LIMIT ?
    ]], { storageNamespace(), os.time(), limit }) or {}
end

local function buildAdminPayload(sourceId, identity, session)
    local rows = adminRows()
    local online = {}
    local players = {}
    session.targets = {}

    for _, value in ipairs(GetPlayers()) do
        local playerId = tonumber(value)
        local target = identityOf(playerId)
        if target then
            local key = identityKey(target)
            online[key] = playerId
            local targetToken = newToken('target', sourceId)
            session.targets[targetToken] = {
                source = playerId,
                identity = cloneIdentity(target),
            }
            players[#players + 1] = {
                serverId = playerId,
                name = target.name,
                targetToken = targetToken,
                tagCount = 0,
                visible = activeStates[playerId] ~= nil,
            }
        end
    end

    local playerBySource = {}
    for _, player in ipairs(players) do
        playerBySource[player.serverId] = player
    end

    local assignments = {}
    local people = {}
    for _, row in ipairs(rows) do
        local key = tostring(row.owner_type) .. '\0' .. tostring(row.owner_identifier)
        local onlineSource = online[key]
        local id = tonumber(row.id)
        local selected = tonumber(row.selected_grant_id) == id
        people[key] = true
        if onlineSource and playerBySource[onlineSource] then
            playerBySource[onlineSource].tagCount = playerBySource[onlineSource].tagCount + 1
        end
        assignments[#assignments + 1] = {
            id = id,
            ownerName = tostring(row.owner_name or 'Player'),
            styleKey = tostring(row.style_key or ''),
            label = tostring(row.label or ''),
            subtitle = tostring(row.subtitle or ''),
            emoji = tostring(row.emoji or ''),
            expiresAt = tonumber(row.expires_at) or false,
            grantedAt = tostring(row.granted_at or ''),
            selected = selected,
            visible = selected and databaseBoolean(row.visible) and onlineSource ~= nil,
            online = onlineSource ~= nil,
            serverId = onlineSource or false,
        }
    end

    table.sort(players, function(first, second)
        local firstName = first.name:lower()
        local secondName = second.name:lower()
        if firstName == secondName then
            return first.serverId < second.serverId
        end
        return firstName < secondName
    end)

    local peopleCount = 0
    for _ in pairs(people) do
        peopleCount = peopleCount + 1
    end
    local visibleCount = 0
    for _ in pairs(activeStates) do
        visibleCount = visibleCount + 1
    end

    return {
        mode = 'admin',
        locale = Config.Locale,
        strings = Bridge.UI(),
        styles = stylesPayload(),
        players = players,
        assignments = assignments,
        player = {
            name = identity.name,
            visible = activeStates[sourceId] ~= nil,
            afk = afkStates[sourceId] == true,
            selectedId = activeStates[sourceId] and activeStates[sourceId].grantId or false,
        },
        stats = {
            assignments = #assignments,
            people = peopleCount,
            visible = visibleCount,
            styles = #stylesPayload(),
        },
        session = session.token,
        sessionDuration = session.duration,
        isAdmin = true,
    }
end

local function normalizeFields(data)
    if type(data) ~= 'table' or type(data.styleKey) ~= 'string' then
        return nil
    end
    local style = Config.Styles and Config.Styles[data.styleKey]
    if not style then
        return nil
    end

    local label = cleanText(data.label, 48)
    local subtitle = cleanText(data.subtitle, 64)
    local emoji = cleanText(data.emoji, 16)
    if label == false or subtitle == false or emoji == false then
        return nil
    end
    label = label or cleanText(tostring(style.Label or style.Name or data.styleKey), 48)
    subtitle = subtitle or cleanText(tostring(style.Subtitle or ''), 64)
    emoji = emoji or cleanText(tostring(style.Emoji or ''), 16)
    if not label or label == false or subtitle == false or emoji == false then
        return nil
    end

    local days = tonumber(data.expiresDays)
    if not days or days ~= math.floor(days) or days < 0 or days > 3650 then
        return nil
    end

    return {
        styleKey = data.styleKey,
        label = label,
        subtitle = subtitle,
        emoji = emoji,
        expiresAt = days > 0 and os.time() + days * 86400 or nil,
    }
end

local function adminFailure(sourceId, operation, key)
    TriggerClientEvent('jrmy_tags:cl:adminResult', sourceId, operation, false)
    notify(sourceId, 'error', key or 'invalid_request')
end

local function sendAdminRefresh(sourceId, identity, session)
    local payload = buildAdminPayload(sourceId, identity, session)
    local current = sessionFor(sourceId, session.token)
    if current ~= session then
        return false
    end
    TriggerClientEvent('jrmy_tags:cl:adminData', sourceId, payload)
    return true
end

local function lookupGrant(grantId)
    local rows = MySQL.query.await([[
        SELECT id, owner_type, owner_identifier, owner_name, style_key, label, subtitle, emoji, expires_at
        FROM jrmy_tags_grants
        WHERE namespace = ? AND id = ?
        LIMIT 1
    ]], { storageNamespace(), grantId }) or {}
    local row = rows[1]
    if row then
        row.id = tonumber(row.id)
        row.expires_at = tonumber(row.expires_at)
    end
    return row
end

local function rowIdentity(row)
    return {
        type = tostring(row.owner_type),
        identifier = tostring(row.owner_identifier),
        name = cleanText(row.owner_name, 80) or 'Player',
    }
end

local function matchingOnlineSource(identity)
    local key = identityKey(identity)
    for value in pairs(sourceIdentities) do
        local sourceId = tonumber(value)
        if sourceId and GetPlayerName(sourceId) then
            local current = identityOf(sourceId)
            if current and identityKey(current) == key then
                return sourceId
            end
        end
    end
    for _, value in ipairs(GetPlayers()) do
        local sourceId = tonumber(value)
        local current = identityOf(sourceId)
        if current and identityKey(current) == key then
            return sourceId
        end
    end
    return nil
end

local function hydrateSource(sourceId)
    if not databaseReady or not GetPlayerName(sourceId) then
        return false
    end

    local cycle = cycleOf(sourceId)
    local identity = identityOf(sourceId)
    if not identity then
        if GetPlayerName(sourceId) then
            pendingReady[sourceId] = true
        end
        notify(sourceId, 'error', 'identity_unavailable')
        return false
    end

    local previous = sourceIdentities[sourceId]
    if previous and not sameIdentity(previous, identity) then
        publishState(sourceId, nil)
        sourceIdentities[sourceId] = nil
        hydratedSources[sourceId] = nil
        afkStates[sourceId] = nil
        adminSessions[sourceId] = nil
    end
    afkStates[sourceId] = afkStates[sourceId] == true

    local ok, grants, profile = withIdentityLock(identity, function()
        if not cycleMatches(sourceId, cycle) or not sameIdentity(identityOf(sourceId), identity) then
            return nil, nil
        end
        return loadCollection(identity)
    end)
    if not ok then
        if cycleMatches(sourceId, cycle) and sameIdentity(identityOf(sourceId), identity) then
            pendingReady[sourceId] = true
            notify(sourceId, 'error', 'database_error')
        end
        return false
    end
    if not cycleMatches(sourceId, cycle) or not sameIdentity(identityOf(sourceId), identity) then
        return false
    end

    pendingReady[sourceId] = nil
    refreshSource(sourceId, identity, grants, profile)
    sendSnapshot(sourceId)
    return true
end

local function retryPendingSources(maximum)
    local waiting = {}
    for sourceId in pairs(pendingReady) do
        pendingReady[sourceId] = nil
        waiting[#waiting + 1] = sourceId
        if maximum and #waiting >= maximum then
            break
        end
    end
    for _, sourceId in ipairs(waiting) do
        hydrateSource(sourceId)
    end
end

RegisterNetEvent('jrmy_tags:sv:ready', function()
    local sourceId = source
    if limited(sourceId, 'ready', 500) then
        return
    end
    if not databaseReady then
        pendingReady[sourceId] = true
        return
    end
    pendingReady[sourceId] = nil
    local identity = identityOf(sourceId)
    if identity and hydratedSources[sourceId] == cycleOf(sourceId) and sameIdentity(sourceIdentities[sourceId], identity) then
        sendSnapshot(sourceId)
        return
    end
    hydrateSource(sourceId)
end)

RegisterNetEvent('jrmy_tags:sv:requestSnapshot', function()
    local sourceId = source
    if limited(sourceId, 'snapshot', 1000) or not databaseReady then
        return
    end
    sendSnapshot(sourceId)
end)

RegisterNetEvent('jrmy_tags:sv:openPlayer', function()
    local sourceId = source
    local cycle = cycleOf(sourceId)
    local blocked, shouldRespond = limited(sourceId, 'openPlayer', 600)
    if blocked then
        if shouldRespond then
            notify(sourceId, 'error', 'cooldown')
        end
        return
    end
    if not databaseReady then
        notify(sourceId, 'error', 'database_error')
        return
    end

    local identity = identityOf(sourceId)
    if not identity then
        notify(sourceId, 'error', 'identity_unavailable')
        return
    end
    local ok, grants, profile = withIdentityLock(identity, function()
        if not cycleMatches(sourceId, cycle) or not sameIdentity(identityOf(sourceId), identity) then
            return nil, nil
        end
        return loadCollection(identity)
    end)
    if not ok then
        if cycleMatches(sourceId, cycle) and sameIdentity(identityOf(sourceId), identity) then
            if hydratedSources[sourceId] ~= cycle then
                pendingReady[sourceId] = true
            end
            notify(sourceId, 'error', 'database_error')
        end
        return
    end
    if not cycleMatches(sourceId, cycle) or not sameIdentity(identityOf(sourceId), identity) then
        return
    end

    if not refreshSource(sourceId, identity, grants, profile) then
        return
    end
    TriggerClientEvent('jrmy_tags:cl:open', sourceId, playerPayload(sourceId, identity, grants, profile))
end)

RegisterNetEvent('jrmy_tags:sv:openAdmin', function()
    local sourceId = source
    local cycle = cycleOf(sourceId)
    local blocked, shouldRespond = limited(sourceId, 'openAdmin', 700)
    if blocked then
        if shouldRespond then
            notify(sourceId, 'error', 'cooldown')
        end
        return
    end
    if not databaseReady then
        notify(sourceId, 'error', 'database_error')
        return
    end
    if not isAdmin(sourceId) then
        notify(sourceId, 'error', 'not_admin')
        return
    end

    local identity = identityOf(sourceId)
    if not identity then
        notify(sourceId, 'error', 'identity_unavailable')
        return
    end

    local session = newAdminSession(sourceId, identity)
    local ok, payload = pcall(buildAdminPayload, sourceId, identity, session)
    if not ok then
        if adminSessions[sourceId] == session then
            adminSessions[sourceId] = nil
        end
        print(('^1[jrmy_tags]^7 %s'):format(tostring(payload)))
        if actorCurrent(sourceId, cycle, identity) then
            notify(sourceId, 'error', 'database_error')
        end
        return
    end
    if not cycleMatches(sourceId, cycle) or adminSessions[sourceId] ~= session or not sameIdentity(identityOf(sourceId), identity) then
        if adminSessions[sourceId] == session then
            adminSessions[sourceId] = nil
        end
        return
    end
    TriggerClientEvent('jrmy_tags:cl:open', sourceId, payload)
end)

RegisterNetEvent('jrmy_tags:sv:select', function(value)
    local sourceId = source
    local cycle = cycleOf(sourceId)
    local blocked, shouldRespond = limited(sourceId, 'select', 500)
    if blocked then
        if shouldRespond then
            notify(sourceId, 'error', 'cooldown')
        end
        return
    end
    local grantId = positiveInteger(type(value) == 'table' and (value.id or value.grantId) or value)
    if not databaseReady or not grantId then
        notify(sourceId, 'error', databaseReady and 'invalid_request' or 'database_error')
        return
    end

    local identity = identityOf(sourceId)
    if not identity then
        notify(sourceId, 'error', 'identity_unavailable')
        return
    end

    local ok, success, grants, profile, selected = withIdentityLock(identity, function()
        if not cycleMatches(sourceId, cycle) or not sameIdentity(identityOf(sourceId), identity) then
            return false
        end
        local currentGrants, currentProfile = loadCollection(identity)
        local grant = findGrant(currentGrants, grantId)
        if not grant then
            return false
        end
        if currentProfile.selectedId ~= grant.id then
            currentProfile.selectedId = grant.id
            writeProfile(identity, grant.id, currentProfile.visible)
            writeAudit('select', identity, identity, grant.id, grant.style_key)
        end
        return true, currentGrants, currentProfile, grant
    end)
    if not cycleMatches(sourceId, cycle) or not sameIdentity(identityOf(sourceId), identity) then
        return
    end
    if not ok then
        notify(sourceId, 'error', 'database_error')
        return
    end
    if not success then
        notify(sourceId, 'error', 'assignment_missing')
        return
    end
    sourceIdentities[sourceId] = cloneIdentity(identity)
    refreshSource(sourceId, identity, grants, profile)
    TriggerClientEvent('jrmy_tags:cl:playerData', sourceId, playerPayload(sourceId, identity, grants, profile))
    notify(sourceId, 'success', 'tag_selected', selected.label)
end)

RegisterNetEvent('jrmy_tags:sv:toggle', function(value)
    local sourceId = source
    local cycle = cycleOf(sourceId)
    local blocked, shouldRespond = limited(sourceId, 'toggle', 500)
    if blocked then
        if shouldRespond then
            notify(sourceId, 'error', 'cooldown')
        end
        return
    end
    if not databaseReady then
        notify(sourceId, 'error', 'database_error')
        return
    end

    local desired = nil
    if type(value) == 'boolean' then
        desired = value
    elseif type(value) == 'table' and type(value.visible) == 'boolean' then
        desired = value.visible
    elseif value ~= nil then
        notify(sourceId, 'error', 'invalid_request')
        return
    end

    local identity = identityOf(sourceId)
    if not identity then
        notify(sourceId, 'error', 'identity_unavailable')
        return
    end

    local ok, success, grants, profile, selected = withIdentityLock(identity, function()
        if not cycleMatches(sourceId, cycle) or not sameIdentity(identityOf(sourceId), identity) then
            return false
        end
        local currentGrants, currentProfile = loadCollection(identity)
        local grant = findGrant(currentGrants, currentProfile.selectedId)
        if not grant then
            return false
        end
        local nextVisible = desired
        if nextVisible == nil then
            nextVisible = not currentProfile.visible
        end
        nextVisible = nextVisible == true
        if currentProfile.visible ~= nextVisible then
            currentProfile.visible = nextVisible
            writeProfile(identity, currentProfile.selectedId, currentProfile.visible)
            writeAudit(currentProfile.visible and 'show' or 'hide', identity, identity, grant.id, grant.style_key)
        end
        return true, currentGrants, currentProfile, grant
    end)
    if not cycleMatches(sourceId, cycle) or not sameIdentity(identityOf(sourceId), identity) then
        return
    end
    if not ok then
        notify(sourceId, 'error', 'database_error')
        return
    end
    if not success then
        notify(sourceId, 'error', 'no_tags')
        return
    end
    sourceIdentities[sourceId] = cloneIdentity(identity)
    refreshSource(sourceId, identity, grants, profile)
    TriggerClientEvent('jrmy_tags:cl:playerData', sourceId, playerPayload(sourceId, identity, grants, profile))
    notify(sourceId, 'success', profile.visible and 'tag_visible' or 'tag_hidden', selected.label)
end)

RegisterNetEvent('jrmy_tags:sv:setAfk', function(value)
    local sourceId = source
    local cycle = cycleOf(sourceId)
    local blocked, shouldRespond = limited(sourceId, 'afk', 500)
    if blocked then
        if shouldRespond then
            notify(sourceId, 'error', 'cooldown')
        end
        return
    end
    if not databaseReady then
        notify(sourceId, 'error', 'database_error')
        return
    end
    if not Config.AFK or Config.AFK.Enabled ~= true then
        return
    end

    local desired = nil
    if type(value) == 'boolean' then
        desired = value
    elseif type(value) == 'table' and type(value.afk) == 'boolean' then
        desired = value.afk
    elseif value ~= nil then
        notify(sourceId, 'error', 'invalid_request')
        return
    end

    local identity = identityOf(sourceId)
    if not identity then
        notify(sourceId, 'error', 'identity_unavailable')
        return
    end

    local ok, grants, profile = withIdentityLock(identity, function()
        if not cycleMatches(sourceId, cycle) or not sameIdentity(identityOf(sourceId), identity) then
            return nil, nil
        end
        return loadCollection(identity)
    end)
    if not ok then
        if cycleMatches(sourceId, cycle) and sameIdentity(identityOf(sourceId), identity) then
            notify(sourceId, 'error', 'database_error')
        end
        return
    end
    if not cycleMatches(sourceId, cycle) or not sameIdentity(identityOf(sourceId), identity) then
        return
    end

    afkStates[sourceId] = desired == nil and not afkStates[sourceId] or desired == true
    sourceIdentities[sourceId] = cloneIdentity(identity)
    refreshSource(sourceId, identity, grants, profile)
    TriggerClientEvent('jrmy_tags:cl:playerData', sourceId, playerPayload(sourceId, identity, grants, profile))
    notify(sourceId, 'success', afkStates[sourceId] and 'afk_on' or 'afk_off')
end)

RegisterNetEvent('jrmy_tags:sv:adminRefresh', function(value)
    local sourceId = source
    local actorCycle = cycleOf(sourceId)
    local token = type(value) == 'table' and value.session or value
    local blocked, shouldRespond = limited(sourceId, 'adminRefresh', 700)
    if blocked then
        if shouldRespond then
            adminFailure(sourceId, 'refresh', 'cooldown')
        end
        return
    end
    if not databaseReady then
        adminFailure(sourceId, 'refresh', 'database_error')
        return
    end

    local session, identity = sessionFor(sourceId, token)
    if not session then
        if not isAdmin(sourceId) then
            adminFailure(sourceId, 'refresh', 'not_admin')
            return
        end
        identity = identityOf(sourceId)
        if not identity then
            adminFailure(sourceId, 'refresh', 'identity_unavailable')
            return
        end
        session = newAdminSession(sourceId, identity)
    end

    local ok, delivered = pcall(sendAdminRefresh, sourceId, identity, session)
    if not ok then
        print(('^1[jrmy_tags]^7 %s'):format(tostring(delivered)))
        if actorCurrent(sourceId, actorCycle, identity, session) then
            adminFailure(sourceId, 'refresh', 'database_error')
        end
        return
    end
    if not delivered then
        if cycleMatches(sourceId, actorCycle) and sameIdentity(identityOf(sourceId), identity) then
            adminFailure(sourceId, 'refresh', 'session_expired')
        end
        return
    end
    if not actorCurrent(sourceId, actorCycle, identity, session) then
        return
    end
    TriggerClientEvent('jrmy_tags:cl:adminResult', sourceId, 'refresh', true)
end)

RegisterNetEvent('jrmy_tags:sv:adminSave', function(data)
    local sourceId = source
    local actorCycle = cycleOf(sourceId)
    local blocked, shouldRespond = limited(sourceId, 'adminSave', 900)
    if blocked then
        if shouldRespond then
            adminFailure(sourceId, 'save', 'cooldown')
        end
        return
    end
    if not databaseReady or type(data) ~= 'table' then
        adminFailure(sourceId, 'save', databaseReady and 'invalid_request' or 'database_error')
        return
    end

    local session, actor = sessionFor(sourceId, data.session)
    if not session then
        adminFailure(sourceId, 'save', isAdmin(sourceId) and 'session_expired' or 'not_admin')
        return
    end
    local fields = normalizeFields(data)
    if not fields then
        adminFailure(sourceId, 'save', 'invalid_request')
        return
    end

    local editId = positiveInteger(data.id)
    if data.id ~= nil and data.id ~= false and data.id ~= '' and not editId then
        adminFailure(sourceId, 'save', 'invalid_request')
        return
    end
    local target = nil
    local existing = nil
    if editId then
        local okLookup, result = pcall(lookupGrant, editId)
        if not actorCurrent(sourceId, actorCycle, actor, session) then
            return
        end
        if not okLookup then
            adminFailure(sourceId, 'save', 'database_error')
            return
        end
        existing = result
        if not existing then
            adminFailure(sourceId, 'save', 'assignment_missing')
            return
        end
        target = rowIdentity(existing)
    else
        local record = type(data.targetToken) == 'string' and session.targets[data.targetToken] or nil
        if not record or not GetPlayerName(record.source) then
            adminFailure(sourceId, 'save', 'session_expired')
            return
        end
        local current = identityOf(record.source)
        if not sameIdentity(current, record.identity) then
            adminFailure(sourceId, 'save', 'session_expired')
            return
        end
        target = cloneIdentity(current)
    end

    local ok, success, operation, grantId, grants, profile, previousLabel = withIdentityLock(target, function()
        if not actorCurrent(sourceId, actorCycle, actor, session) then
            return false, 'session'
        end
        if editId then
            local row = lookupGrant(editId)
            if not row or row.owner_type ~= target.type or row.owner_identifier ~= target.identifier then
                return false, 'missing'
            end
            if row.expires_at and row.expires_at <= os.time() then
                return false, 'missing'
            end
            MySQL.query.await([[
                DELETE FROM jrmy_tags_grants
                WHERE namespace = ? AND owner_type = ? AND owner_identifier = ?
                  AND style_key = ? AND id <> ?
                  AND expires_at IS NOT NULL AND expires_at <= ?
            ]], {
                storageNamespace(), target.type, target.identifier,
                fields.styleKey, editId, os.time(),
            })
            local duplicate = MySQL.scalar.await([[
                SELECT id FROM jrmy_tags_grants
                WHERE namespace = ? AND owner_type = ? AND owner_identifier = ?
                  AND style_key = ? AND id <> ?
                  AND (expires_at IS NULL OR expires_at > ?)
                LIMIT 1
            ]], {
                storageNamespace(), target.type, target.identifier,
                fields.styleKey, editId, os.time(),
            })
            if duplicate then
                return false, 'duplicate'
            end
            MySQL.update.await([[
                UPDATE jrmy_tags_grants
                SET owner_name = ?, style_key = ?, label = ?,
                    subtitle = NULLIF(?, ''), emoji = NULLIF(?, ''),
                    expires_at = NULLIF(?, 0)
                WHERE namespace = ? AND id = ?
            ]], {
                target.name, fields.styleKey, fields.label,
                fields.subtitle or '', fields.emoji or '', fields.expiresAt or 0,
                storageNamespace(), editId,
            })
            writeAudit('update', actor, target, editId, fields.styleKey)
            local currentGrants, currentProfile = loadCollection(target)
            return true, 'update', editId, currentGrants, currentProfile, row.label
        end

        MySQL.query.await([[
            DELETE FROM jrmy_tags_grants
            WHERE namespace = ? AND owner_type = ? AND owner_identifier = ?
              AND style_key = ? AND expires_at IS NOT NULL AND expires_at <= ?
        ]], { storageNamespace(), target.type, target.identifier, fields.styleKey, os.time() })
        local duplicate = MySQL.scalar.await([[
            SELECT id FROM jrmy_tags_grants
            WHERE namespace = ? AND owner_type = ? AND owner_identifier = ?
              AND style_key = ? AND (expires_at IS NULL OR expires_at > ?)
            LIMIT 1
        ]], { storageNamespace(), target.type, target.identifier, fields.styleKey, os.time() })
        if duplicate then
            return false, 'duplicate'
        end
        local count = tonumber(MySQL.scalar.await([[
            SELECT COUNT(*) FROM jrmy_tags_grants
            WHERE namespace = ? AND owner_type = ? AND owner_identifier = ?
              AND (expires_at IS NULL OR expires_at > ?)
        ]], { storageNamespace(), target.type, target.identifier, os.time() })) or 0
        local maximum = math.max(1, math.floor(tonumber(Config.MaxTagsPerPlayer) or 8))
        if count >= maximum then
            return false, 'maximum'
        end
        local newId = MySQL.insert.await([[
            INSERT INTO jrmy_tags_grants
                (namespace, owner_type, owner_identifier, owner_name, style_key,
                 label, subtitle, emoji, granted_by_type, granted_by_identifier,
                 granted_by_name, expires_at)
            VALUES (?, ?, ?, ?, ?, ?, NULLIF(?, ''), NULLIF(?, ''), ?, ?, ?, NULLIF(?, 0))
        ]], {
            storageNamespace(), target.type, target.identifier, target.name,
            fields.styleKey, fields.label, fields.subtitle or '', fields.emoji or '',
            actor.type, actor.identifier, actor.name, fields.expiresAt or 0,
        })
        newId = tonumber(newId)
        if not newId then
            error('grant insert failed')
        end
        writeAudit('grant', actor, target, newId, fields.styleKey)
        local currentGrants, currentProfile = loadCollection(target)
        return true, 'grant', newId, currentGrants, currentProfile, nil
    end)

    if not ok then
        recoverIdentity(target)
        if actorCurrent(sourceId, actorCycle, actor, session) then
            adminFailure(sourceId, 'save', 'database_error')
        end
        return
    end
    if not success then
        local key = operation == 'maximum' and 'max_tags'
            or operation == 'missing' and 'assignment_missing'
            or operation == 'duplicate' and 'duplicate_tag'
            or operation == 'session' and 'session_expired'
            or 'invalid_request'
        if actorCurrent(sourceId, actorCycle, actor, session) then
            adminFailure(sourceId, 'save', key)
        end
        return
    end

    local targetSource = matchingOnlineSource(target)
    if targetSource and GetPlayerName(targetSource) then
        sourceIdentities[targetSource] = cloneIdentity(target)
        refreshIdentitySources(target, grants, profile)
        if operation == 'grant' then
            notify(targetSource, 'success', 'grant_received', fields.label)
        elseif previousLabel ~= fields.label then
            notify(targetSource, 'success', 'grant_updated')
        end
    else
        refreshIdentitySources(target, grants, profile)
    end
    if not cycleMatches(sourceId, actorCycle) or adminSessions[sourceId] ~= session or not sameIdentity(identityOf(sourceId), actor) then
        return
    end
    TriggerClientEvent('jrmy_tags:cl:adminResult', sourceId, 'save', true)
    notify(sourceId, 'success', operation == 'grant' and 'grant_saved' or 'grant_updated', target.name)
    local refreshOk, refreshError = pcall(sendAdminRefresh, sourceId, actor, session)
    if not refreshOk then
        debugLog(refreshError)
    end
end)

RegisterNetEvent('jrmy_tags:sv:adminDelete', function(first, second)
    local sourceId = source
    local actorCycle = cycleOf(sourceId)
    local blocked, shouldRespond = limited(sourceId, 'adminDelete', 800)
    if blocked then
        if shouldRespond then
            adminFailure(sourceId, 'delete', 'cooldown')
        end
        return
    end
    local data = type(first) == 'table' and first or { session = first, id = second }
    local grantId = positiveInteger(data.id)
    if not databaseReady or not grantId then
        adminFailure(sourceId, 'delete', databaseReady and 'invalid_request' or 'database_error')
        return
    end

    local session, actor = sessionFor(sourceId, data.session)
    if not session then
        adminFailure(sourceId, 'delete', isAdmin(sourceId) and 'session_expired' or 'not_admin')
        return
    end
    local okLookup, existing = pcall(lookupGrant, grantId)
    if not actorCurrent(sourceId, actorCycle, actor, session) then
        return
    end
    if not okLookup then
        adminFailure(sourceId, 'delete', 'database_error')
        return
    end
    if not existing then
        adminFailure(sourceId, 'delete', 'assignment_missing')
        return
    end
    local target = rowIdentity(existing)

    local ok, removed, grants, profile = withIdentityLock(target, function()
        if not actorCurrent(sourceId, actorCycle, actor, session) then
            return false, 'session'
        end
        local row = lookupGrant(grantId)
        if not row or row.owner_type ~= target.type or row.owner_identifier ~= target.identifier then
            return false, 'missing'
        end
        local affected = MySQL.update.await([[
            DELETE FROM jrmy_tags_grants
            WHERE namespace = ? AND id = ? AND owner_type = ? AND owner_identifier = ?
        ]], { storageNamespace(), grantId, target.type, target.identifier })
        if tonumber(affected) ~= 1 then
            return false, 'missing'
        end
        writeAudit('revoke', actor, target, grantId, row.style_key)
        local currentGrants, currentProfile = loadCollection(target)
        return true, currentGrants, currentProfile
    end)
    if not ok then
        recoverIdentity(target)
        if actorCurrent(sourceId, actorCycle, actor, session) then
            adminFailure(sourceId, 'delete', 'database_error')
        end
        return
    end
    if not removed then
        local key = grants == 'session' and 'session_expired' or 'assignment_missing'
        if actorCurrent(sourceId, actorCycle, actor, session) then
            adminFailure(sourceId, 'delete', key)
        end
        return
    end

    local targetSource = matchingOnlineSource(target)
    if targetSource then
        sourceIdentities[targetSource] = cloneIdentity(target)
        refreshIdentitySources(target, grants, profile)
        notify(targetSource, 'warning', 'grant_removed', existing.label)
    else
        refreshIdentitySources(target, grants, profile)
    end
    if not cycleMatches(sourceId, actorCycle) or adminSessions[sourceId] ~= session or not sameIdentity(identityOf(sourceId), actor) then
        return
    end
    TriggerClientEvent('jrmy_tags:cl:adminResult', sourceId, 'delete', true)
    notify(sourceId, 'success', 'grant_revoked')
    local refreshOk, refreshError = pcall(sendAdminRefresh, sourceId, actor, session)
    if not refreshOk then
        debugLog(refreshError)
    end
end)

RegisterNetEvent('jrmy_tags:sv:unloaded', function()
    local sourceId = source
    if limited(sourceId, 'unloaded', 5000) then
        return
    end
    clearSource(sourceId, false)
end)

AddEventHandler('playerDropped', function()
    clearSource(source, true)
end)

local function frameworkLogout(playerId)
    local eventSource = tonumber(source)
    local target = eventSource and eventSource > 0 and eventSource or tonumber(playerId)
    if target then
        clearSource(target, false)
    end
end

AddEventHandler('QBCore:Server:OnPlayerUnload', frameworkLogout)
AddEventHandler('qbx_core:server:onLogout', frameworkLogout)
AddEventHandler('esx:playerLogout', frameworkLogout)

CreateThread(function()
    local attempt = 0
    while not databaseReady do
        attempt = attempt + 1
        local ok, errorValue = pcall(createTables)
        if ok then
            databaseReady = true
            debugLog('database ready')
            retryPendingSources()
            return
        end
        print(('^1[jrmy_tags]^7 %s'):format(tostring(errorValue)))
        Wait(math.min(15000, attempt * 2000))
    end
end)

CreateThread(function()
    while true do
        Wait(5000)
        if databaseReady then
            retryPendingSources(10)
            local recoveries = {}
            for _, identity in pairs(pendingRecoveries) do
                recoveries[#recoveries + 1] = identity
                if #recoveries >= 5 then
                    break
                end
            end
            for _, identity in ipairs(recoveries) do
                recoverIdentity(identity)
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(math.max(10000, tonumber(Config.ExpirationSweep) or 60000))
        if databaseReady then
            local ok, rows = pcall(function()
                return MySQL.query.await([[
                    SELECT id, owner_type, owner_identifier, owner_name, style_key, label
                    FROM jrmy_tags_grants
                    WHERE namespace = ? AND expires_at IS NOT NULL AND expires_at <= ?
                    ORDER BY expires_at ASC
                    LIMIT 250
                ]], { storageNamespace(), os.time() }) or {}
            end)
            if ok then
                for _, row in ipairs(rows) do
                    local target = rowIdentity(row)
                    local grantId = tonumber(row.id)
                    local lockOk, removed, grants, profile = withIdentityLock(target, function()
                        local affected = MySQL.update.await([[
                            DELETE FROM jrmy_tags_grants
                            WHERE namespace = ? AND id = ? AND expires_at IS NOT NULL AND expires_at <= ?
                        ]], { storageNamespace(), grantId, os.time() })
                        if tonumber(affected) ~= 1 then
                            return false
                        end
                        local system = { type = 'system', identifier = 'jrmy_tags', name = 'jrmy_tags' }
                        writeAudit('expire', system, target, grantId, row.style_key)
                        local currentGrants, currentProfile = loadCollection(target)
                        return true, currentGrants, currentProfile
                    end)
                    if lockOk and removed then
                        local targetSource = matchingOnlineSource(target)
                        if targetSource then
                            sourceIdentities[targetSource] = cloneIdentity(target)
                            refreshIdentitySources(target, grants, profile)
                            notify(targetSource, 'warning', 'grant_removed', row.label)
                        else
                            refreshIdentitySources(target, grants, profile)
                        end
                    elseif not lockOk then
                        recoverIdentity(target)
                    end
                end
            else
                print(('^1[jrmy_tags]^7 %s'):format(tostring(rows)))
            end
        end
    end
end)

exports('IsAdmin', function(sourceId)
    return isAdmin(tonumber(sourceId))
end)

exports('GetActiveTag', function(sourceId)
    sourceId = tonumber(sourceId)
    local state = sourceId and activeStates[sourceId]
    local expiresAt = state and tonumber(state.expiresAt)
    if not state or expiresAt and expiresAt > 0 and expiresAt <= os.time() then
        return nil
    end
    return {
        serverId = state.serverId,
        grantId = state.grantId,
        styleKey = state.styleKey,
        label = state.label,
        subtitle = state.subtitle,
        emoji = state.emoji,
        afk = state.afk,
        expiresAt = state.expiresAt,
    }
end)

exports('HasTag', function(sourceId, styleKey)
    sourceId = tonumber(sourceId)
    if not databaseReady or not sourceId or type(styleKey) ~= 'string' or not Config.Styles[styleKey] then
        return false
    end
    local identity = identityOf(sourceId)
    if not identity then
        return false
    end
    local ok, result = pcall(function()
        return MySQL.scalar.await([[
            SELECT id FROM jrmy_tags_grants
            WHERE namespace = ? AND owner_type = ? AND owner_identifier = ?
              AND style_key = ? AND (expires_at IS NULL OR expires_at > ?)
            LIMIT 1
        ]], { storageNamespace(), identity.type, identity.identifier, styleKey, os.time() })
    end)
    return ok and result ~= nil
end)
