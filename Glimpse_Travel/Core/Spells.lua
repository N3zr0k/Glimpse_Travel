local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local T = Glimpse:GetModule("TravelAddon")

-- Zauber, Buffs und Klasse, gemeinsam für alle Reisearten (Modules/Mount, ClassTravel, Water, SpeedBoost).
-- Die Reisegestalten melden die Module an (T:RegisterForm), damit der Doppelklick sie wieder aufheben kann.

T.travelForms = {} -- [Zauber-ID] = true

function T:RegisterForm(spellID)
    self.travelForms[spellID] = true
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

--- "Alliance" oder "Horde" (Standard Allianz, wenn der Client nichts liefert)
function T:PlayerFaction()
    local group = self.api.UnitFactionGroup and self.api.UnitFactionGroup("player")
    return group == "Horde" and "Horde" or "Alliance"
end

--- "DRUID", "SHAMAN" ...
function T:PlayerClass()
    if not self.api.UnitClass then return nil end
    local _, class = self.api.UnitClass("player")
    return class
end

local function Known(self, entry)
    for _, id in ipairs(entry.ranks or { entry.spell }) do
        if self:KnowsSpell(id) then return id end
    end
    return nil
end

--- Zauber-ID der aktiven Reisegestalt oder nil
function T:ActiveTravelForm()
    local api = self.api
    if not (api.GetShapeshiftForm and api.GetShapeshiftFormInfo) then return nil end
    local index = api.GetShapeshiftForm()
    if not index or index == 0 then return nil end
    local _, _, _, spellID = api.GetShapeshiftFormInfo(index)
    return self.travelForms[spellID] and spellID or nil
end

--- Erste passende Fertigkeit aus list[Klasse]: spellID, name oder nil und Grund
function T:ClassSpell(list, ctx)
    local entries = list[self:PlayerClass() or ""]
    if not entries then return nil, "no travel ability for this class" end
    local reason = "travel ability not learned"
    for _, entry in ipairs(entries) do
        local known = Known(self, entry)
        if known then
            if entry.outdoors and not ctx.outdoors then
                reason = entry.spell .. " only outdoors"
            elseif entry.aura and self:HasAura(entry.spell) then
                reason = entry.spell .. " already active"
            elseif entry.cooldown and self:OnCooldown(known) then
                reason = entry.spell .. " on cooldown"
            elseif not self:SpellUsable(known) then
                reason = entry.spell .. " not usable now"
            else
                local name = self:SpellName(known)
                if name then return entry.spell, name end
                reason = entry.spell .. " has no name"
            end
        end
    end
    return nil, reason
end
