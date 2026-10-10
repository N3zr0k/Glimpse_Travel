-- luacheck: ignore 111 113 122 143 432
-- Gemeinsamer Aufbau für die Travel-Tests: lädt alle Dateien und steuert die Blizzard-API über env.
local stub = require("wowstub")

local FILES = { "Core/Travel.lua", "Core/Spells.lua", "Core/Speed.lua", "Core/Action.lua", "Core/Arrival/ArrivalFrame.lua",
    "Core/Arrival/Arrival.lua", "Core/Options.lua",
    "Modules/Mount/Mount.lua", "Modules/ClassTravel/ClassTravel.lua", "Modules/Water/Water.lua", "Modules/SpeedBoost/SpeedBoost.lua",
    "Modules/FlightTime/FlightTime.lua", "Modules/FlightTime/FlightTimeTooltip.lua",
    "Modules/DeeprunTram/DeeprunTramPoints.lua", "Modules/DeeprunTram/DeeprunTramWarnings.lua", "Modules/DeeprunTram/DeeprunTramSpeed.lua",
    "Modules/DeeprunTram/DeeprunTram.lua", "Modules/FlightRide/FlightRideSpeed.lua", "Modules/FlightRide/FlightRide.lua",
    "Modules/PlayerSpeed/PlayerSpeed.lua", "Modules/PlayerSpeed/PlayerSpeedFrame.lua",
    "Commands/Travel.lua" }

local SPELL_NAMES = { [783] = "Reisegestalt", [1066] = "Wassergestalt", [2645] = "Geisterwolf", [5118] = "Aspekt des Geparden", [2983] = "Sprinten", [8696] = "Sprinten", [1850] = "Spurt" }

local function TravelSetup()
    local Glimpse = stub.newGlimpse()
    -- Zustand des Spiels, vom Test gesteuert
    local env = { Glimpse = Glimpse, class = "DRUID", known = {}, unusable = {}, auras = {}, form = 0, formSpell = nil,
        mounts = {}, items = {}, cooldowns = {}, itemCooldowns = {} }
    for _, file in ipairs(FILES) do stub.load(file) end
    local T = Glimpse:GetModule("TravelAddon")
    env.T = T
    local api = T.api
    api.C_MountJournal = {
        GetMountIDs = function()
            local ids = {}
            for id in ipairs(env.mounts) do ids[#ids + 1] = id end
            return ids
        end,
        GetMountInfoByID = function(id)
            local m = env.mounts[id]
            return m.name, m.spell, "icon", false, m.usable ~= false, 0, m.favorite or false, false, nil, m.hidden or false, m.collected ~= false
        end,
    }
    api.IsPlayerSpell = function(id) return env.known[id] == true end
    api.IsSpellKnown = nil
    api.IsUsableSpell = function(id) return not env.unusable[id] end
    api.GetSpellName = function(id) return SPELL_NAMES[id] end
    api.GetSpellInfo = nil
    api.GetShapeshiftForm = function() return env.form end
    api.GetShapeshiftFormInfo = function() return "icon", true, true, env.formSpell end
    api.GetPlayerAuraBySpellID = function(id) return env.auras[id] and {} or nil end
    api.UnitClass = function() return "Klasse", env.class end
    api.GetItemCount = function(id) return env.items[id] or 0 end
    api.random = function(n) return n end -- immer das letzte
    api.GetSpellCooldown = function(id) if env.cooldowns[id] then return 100, 300 end return 0, 0 end
    api.GetItemCooldown = function(id) if env.itemCooldowns[id] then return 100, 120 end return 0, 0 end
    T:OnInitialize()
    T:OnEnable()
    return env
end

return TravelSetup
