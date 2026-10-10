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
end

--- Zaubername aus der ID, nil wenn der Client ihn nicht kennt
function T:SpellName(spellID)
    local api = self.api
    if api.GetSpellName then
        local ok, name = pcall(api.GetSpellName, spellID)
        if ok and name then return name end
    end
    if api.GetSpellInfo then
        local ok, name = pcall(api.GetSpellInfo, spellID)
        if ok and name then return name end
    end
    return nil
end

function T:KnowsSpell(spellID)
    local api = self.api
    for _, ask in ipairs({ api.IsPlayerSpell, api.IsSpellKnown }) do
        local ok, known = pcall(ask, spellID)
        if ok and known then return true end
    end
    return false
end

--- Nutzbar laut Client (Mana, Gestalt ...); ohne Abfrage wird es versucht
function T:SpellUsable(spellID)
    local api = self.api
    if not api.IsUsableSpell then return true end
    local ok, usable = pcall(api.IsUsableSpell, spellID)
    return not ok or usable == true or usable == 1
end

--- Läuft die Abklingzeit? Die globale Abklingzeit (bis 1,5 s) zählt nicht.
function T:OnCooldown(spellID)
    if not self.api.GetSpellCooldown then return false end
    local ok, start, duration = pcall(self.api.GetSpellCooldown, spellID)
    if not ok then return false end
    if type(start) == "table" then start, duration = start.startTime, start.duration end
    return (start or 0) > 0 and (duration or 0) > 1.5
end

--- Buff mit dieser Zauber-ID aktiv?
function T:HasAura(spellID)
    local api = self.api
    if api.GetPlayerAuraBySpellID then
        local ok, aura = pcall(api.GetPlayerAuraBySpellID, spellID)
        return ok and aura ~= nil
    end
    if not api.UnitBuff then return false end
    for index = 1, 40 do
        local ok, name, _, _, _, _, _, _, _, id = pcall(api.UnitBuff, "player", index)
        if not ok or not name then return false end
        if id == spellID then return true end
    end
    return false
end

--- "DRUID", "SHAMAN" ...
function T:PlayerClass()
    if not self.api.UnitClass then return nil end
    local _, class = self.api.UnitClass("player")
    return class
end
