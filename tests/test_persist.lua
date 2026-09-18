-- Settings mirror: survives a "client restart" where SavedVariables come back empty.
-- Each session() below reloads the addon from disk with fresh frames, the way a
-- new client launch does. Only the fake CVar store lives across sessions, which
-- is exactly what the Forever beta client gives an addon. Run from ForeverCDM:
--   lua tests/test_persist.lua
unpack = table.unpack
strlower = string.lower
strtrim = function(s) return s:match('^%s*(.-)%s*$') end
issecretvalue = function() return false end

local frames, methods = {}, {}
local function noop() end
local function object(kind, name, parent)
    local f = { kind = kind, parent = parent, scripts = {}, events = {}, shown = true }
    setmetatable(f, { __index = methods })
    frames[#frames + 1] = f
    if name then _G[name] = f end
    return f
end
for _, name in ipairs({ 'SetTexCoord', 'ClearAllPoints', 'SetMovable', 'SetClampedToScreen', 'SetDrawEdge',
    'SetHideCountdownNumbers', 'SetDesaturated', 'SetCooldownFromDurationObject', 'SetAllPoints', 'SetCooldown',
    'Clear', 'SetColorTexture', 'RegisterForDrag', 'SetPoint', 'SetTexture', 'EnableMouse', 'SetAlpha',
    'SetText' }) do methods[name] = noop end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:GetWidth() return self.width or 100 end
function methods:SetScript(k, fn) self.scripts[k] = fn end
function methods:RegisterEvent(e) self.events[e] = true end
function methods:RegisterUnitEvent(e) self.events[e] = true end
function methods:CreateTexture() return object('Texture', nil, self) end
function methods:CreateFontString() return object('FontString', nil, self) end
function methods:IsShown() return self.shown end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:SetShown(v) self.shown = v and true or false end

CreateFrame = object
C_Timer = { NewTicker = noop, After = function(_, fn) fn() end }   -- debounce fires at once
C_Spell = {
    GetSpellName = function(id) return 'Spell ' .. id end,
    GetSpellTexture = function(id) return id end,
    GetSpellCooldown = function() return { startTime = 0, duration = 0, isEnabled = true } end,
    GetSpellCharges = function() return nil end,
}
C_UnitAuras = { GetPlayerAuraBySpellID = function() return nil end }

-- The one thing that outlives a session: the client's CVar store.
local cvars, registered = {}, {}
C_CVar = {
    RegisterCVar = function(name, default) registered[name] = true if cvars[name] == nil then cvars[name] = default end end,
    GetCVar = function(name) assert(registered[name], 'GetCVar before RegisterCVar: ' .. name) return cvars[name] end,
    SetCVar = function(name, value)
        assert(registered[name], 'SetCVar before RegisterCVar: ' .. name)
        assert(#value <= 200, 'chunk longer than 200 characters')
        assert(not value:find('"', 1, true) and not value:find('\n', 1, true), 'value would corrupt config-cache.wtf')
        cvars[name] = value
    end,
}

local player = 'Thunderz'
UnitName = function() return player end
GetRealmName = function() return 'Beta Realm' end

local printed
print = function(...) printed[#printed + 1] = table.concat({ ... }, ' ') end

local function session(savedVariables)
    frames, registered, printed = {}, {}, {}     -- registrations do not survive a restart; values do
    UIParent = object('Frame')
    SlashCmdList = {}
    ForeverCDM, ForeverCDMDB = nil, savedVariables
    assert(loadfile('ForeverCDM.lua'))('ForeverCDM')
    for _, f in ipairs(frames) do if f.events.PLAYER_LOGIN then f.scripts.OnEvent(f, 'PLAYER_LOGIN') end end
    return ForeverCDMDB
end
local function logout()
    for _, f in ipairs(frames) do if f.events.PLAYER_LOGOUT then f.scripts.OnEvent(f, 'PLAYER_LOGOUT') end end
end
local function slash(msg) SlashCmdList.FOREVERCDM(msg) end
local function said(fragment)
    for _, line in ipairs(printed) do if line:find(fragment, 1, true) then return true end end
    return false
end

-- 1. First ever launch: nothing saved, nothing mirrored, defaults.
local db = session(nil)
assert(#db.cds == 0 and db.rowSize.buffs == 36 and db.locked == true, 'fresh install should start on defaults')
assert(not said('restored'), 'nothing to restore on a first launch')

-- The player sets things up.
slash('add 101')
slash('add 102')
slash('addutility 103')
slash('addbuff 201')
slash('size buffs 50')
slash('spacing cds 8')
slash('unlock')
slash('hideready on')
db.pos.buffs = { 'TOPLEFT', 123.4, -56.7 }
db.minimap.angle, db.minimap.hide = -42.4, true
db.buffDurations[201] = 1800
slash('names on')            -- any later change flushes the manual edits above too
logout()

-- 2. Restart. The beta client hands back NO SavedVariables. Everything returns.
db = session(nil)
assert(said('restored from the settings mirror'), 'player was not told their settings came from the mirror')
assert(db.cds[1] == 101 and db.cds[2] == 102 and #db.cds == 2, 'cooldown list or its order was lost')
assert(db.utilities[1] == 103 and db.buffs[1] == 201, 'utility/buff lists were lost')
assert(db.rowSize.buffs == 50 and db.rowSize.cds == 36, 'per-bar size was lost')
assert(db.rowSpacing.cds == 8 and db.rowSpacing.buffs == 4, 'per-bar spacing was lost')
assert(db.locked == false and db.hideReady == true and db.showNames == true, 'toggles were lost')
assert(db.pos.buffs[1] == 'TOPLEFT' and db.pos.buffs[2] == 123.4 and db.pos.buffs[3] == -56.7, 'bar position was lost')
assert(db.pos.cds[1] == 'CENTER' and db.pos.cds[3] == -170, 'untouched bar position changed')
assert(db.minimap.angle == -42 and db.minimap.hide == true, 'minimap button state was lost')
assert(db.buffDurations[201] == 1800, 'learned buff duration was lost')

-- 3. A real SavedVariables table always wins over the mirror (the day Blizzard fixes it).
db = session({ cds = { 999 }, buffs = {}, utilities = {} })
assert(db.cds[1] == 999 and #db.cds == 1, 'mirror overwrote settings the client actually loaded')
assert(not said('restored'), 'mirror claimed a restore it should not have done')
slash('lock')                -- and the mirror now follows the real settings
db = session(nil)
assert(db.cds[1] == 999, 'mirror did not pick up the loaded settings')

-- 4. A shorter save must not leave the tail of a longer one behind.
for id = 1000, 1299 do db.cds[#db.cds + 1] = id end          -- about 1500 characters of IDs
slash('lock')
local long = session(nil)
assert(#long.cds == 301 and long.cds[301] == 1299, 'long list did not survive chunking')
slash('reset')
slash('add 7')
db = session(nil)
assert(#db.cds == 1 and db.cds[1] == 7, 'stale chunks from the longer save leaked into the restore')

-- 5. Too big for the mirror: the last good copy is kept rather than a cut-off one.
for id = 100000, 100400 do db.cds[#db.cds + 1] = id end      -- about 2800 characters
slash('lock')
db = session(nil)
assert(#db.cds == 1 and db.cds[1] == 7, 'oversized settings should leave the previous mirror intact')

-- 6. Another character gets its own mirror.
player = 'Someone Else'
db = session(nil)
assert(#db.cds == 0 and not said('restored'), "one character restored another character's settings")
player = 'Thunderz'
db = session(nil)
assert(db.cds[1] == 7, 'the first character lost its mirror after an alt logged in')

-- 7. Garbage in the CVars is ignored, not applied.
for name in pairs(cvars) do cvars[name] = '' end
local prefix
for name in pairs(cvars) do if name:match('N0$') then prefix = name end end
cvars[prefix] = 'this is not a settings string'
db = session(nil)
assert(#db.cds == 0 and not said('restored'), 'unrecognised mirror contents were applied')

-- 8. A client without RegisterCVar: everything still loads, the mirror just stays off.
C_CVar = nil
db = session(nil)
slash('add 5')
slash('mirror')
assert(db.cds[1] == 5 and said('this client has no C_CVar.RegisterCVar'), 'addon should run without the mirror')

io.write('settings mirror: restart, SavedVariables precedence, chunking, per-character and fallback checks passed\n')
