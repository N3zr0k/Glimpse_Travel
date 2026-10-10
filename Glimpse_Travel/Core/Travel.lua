local ADDON_NAME = ...
local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

-- Komfort rund ums Reisen. Strecke, Zonen und Flugzeiten erfasst das Core-Modul "Travel"; dieses Addon liest nur.
-- Der Modulname ist deshalb "TravelAddon". Einstellungen liegen im Namespace ADDON_NAME von Glimpse.db (Profil).
local T = Glimpse:NewModule("TravelAddon", nil, "AceEvent-3.0")
Glimpse.TravelAddon = T
T.L = L

T.defaults = {
    mount = true,          -- Reittier per Doppelklick
    classSpeed = true,     -- Klassenfertigkeit, wenn kein Reittier geht
    speedBoost = true,     -- Tempo-Fähigkeit mit Abklingzeit (Sprinten, Spurt), wenn sonst nichts geht
    speedPotion = false,   -- Tempotrank, wenn sonst nichts geht (verbraucht einen Trank)
    swimPotion = false,    -- Schwimmtrank im Wasser (verbraucht einen Trank)
    flightTime = true,     -- Flugzeit im Tooltip der Flugkarte
    arrival = true,        -- grüner Countdown bis zur Ankunft (Tiefenbahn, Flugroute)
    arrivalSound = false,  -- Ton kurz vor der Ankunft
    tramNotes = true,      -- weiße Hinweise während der Tiefenbahn-Fahrt
    tramWarnings = true,   -- rote Warnung, wenn man sich in der Tiefenbahn bewegt
    tramSpeed = true,      -- Tempo der Tiefenbahn als eigene Zeile
    flightSpeed = true,    -- Flugtempo als eigene Zeile bei Flugrouten
    playerSpeed = true,    -- eigenes Tempo in Blau am Spielerportrait
    modifier = "ALT",
    button = "RightButton",
}

-- Blizzard-API gebündelt, damit Tests sie ersetzen können
T.api = {
    C_MountJournal = C_MountJournal,
    IsPlayerSpell = IsPlayerSpell,
    IsSpellKnown = IsSpellKnown,
    IsUsableSpell = IsUsableSpell or (C_Spell and C_Spell.IsSpellUsable),
    GetSpellName = C_Spell and C_Spell.GetSpellName or nil,
    GetSpellInfo = GetSpellInfo,
    GetSpellCooldown = (C_Spell and C_Spell.GetSpellCooldown) or GetSpellCooldown,
    GetShapeshiftForm = GetShapeshiftForm,
    GetShapeshiftFormInfo = GetShapeshiftFormInfo,
    GetPlayerAuraBySpellID = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID or nil,
    UnitBuff = UnitBuff,
    UnitClass = UnitClass,
    UnitFactionGroup = UnitFactionGroup,
    GetItemCount = (C_Item and C_Item.GetItemCount) or GetItemCount,
    GetItemCooldown = (C_Container and C_Container.GetItemCooldown) or GetItemCooldown,
    GetItemName = (C_Item and C_Item.GetItemNameByID) or GetItemInfo,
    random = math.random,
    -- Flugkarte
    C_TaxiMap = C_TaxiMap,
    GetTaxiMapID = GetTaxiMapID,
    TaxiNumRoutes = TaxiNumRoutes,
    TaxiGetNodeSlot = TaxiGetNodeSlot,
    GameTooltip = GameTooltip,
    hooksecurefunc = hooksecurefunc,
    GetDatabase = function() return GlimpseDB end,
    -- Ankunft
    CreateFrame = CreateFrame,
    GetTime = GetTime,
    NewTicker = C_Timer and C_Timer.NewTicker,
    After = C_Timer and C_Timer.After,
    PlaySound = PlaySound,
    GetMapInfo = C_Map and C_Map.GetMapInfo,
    -- Tempoanzeige
    GetUnitSpeed = GetUnitSpeed,
    InCombat = function() return UnitAffectingCombat("player") end,
    issecretvalue = issecretvalue,
    GetPlayerFrame = function() return PlayerFrame end,
    GetTramRide = function()
        local travel = Glimpse:GetModule("Travel", true)
        return travel and travel.GetTramRide and travel:GetTramRide()
    end,
}

function T:OnInitialize()
    self.settings = Glimpse.db:RegisterNamespace(ADDON_NAME, { profile = self.defaults })
    Glimpse:RegisterAddonOptions(ADDON_NAME, self:BuildOptions(), true)
end

function T:OnEnable()
    if self.ActionUpdate then self:ActionUpdate() end
    if self.FlightTimeEnable then self:FlightTimeEnable() end
    if self.ArrivalEnable then self:ArrivalEnable() end
    if self.FlightRideEnable then self:FlightRideEnable() end
    if self.PlayerSpeedEnable then self:PlayerSpeedEnable() end
end

function T:OnDisable()
    if self.ActionStop then self:ActionStop() end
    if self.RideEnd then self:RideEnd() end
end

--- Fällt auf T.defaults zurück
function T:Opt(name)
    local profile = self.settings and self.settings.profile
    local value = profile and profile[name]
    if value == nil then value = self.defaults[name] end
    return value
end

function T:SetOpt(name, value)
    self.settings.profile[name] = value
    if self.ActionUpdate then self:ActionUpdate() end
    if self.PlayerSpeedUpdate then self:PlayerSpeedUpdate() end
end
