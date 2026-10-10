local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local T = Glimpse:GetModule("TravelAddon")

-- Klassenfertigkeiten, mit denen man schneller reist, in der Reihenfolge der Wahl.
--   form      Gestalt: ein weiterer Doppelklick hebt sie wieder auf
--   aura      Buff: ist er aktiv, wird nicht neu gewirkt
--   outdoors  nur im Freien
--   ranks     alle Ränge; gelernt ist er, wenn einer davon bekannt ist (gewirkt wird über den Namen, also der höchste)
--   cooldown  hat eine Abklingzeit: läuft sie, wird übersprungen
T.CLASS_SPEED = {
    DRUID = { { spell = 783, form = true, outdoors = true } },   -- Reisegestalt
    SHAMAN = { { spell = 2645, form = true } },                  -- Geisterwolf
    HUNTER = { { spell = 5118, aura = true } },                  -- Aspekt des Geparden
}
T.CLASS_WATER = {
    DRUID = { { spell = 1066, form = true } },                   -- Wassergestalt
}
-- Fähigkeiten, die das Tempo kurz erhöhen (eigene Option); erst, wenn weder Reittier noch Reisegestalt gehen
T.SPEED_BOOSTS = {
    ROGUE = { { spell = 2983, ranks = { 2983, 8696, 11305 }, cooldown = true } },  -- Sprinten
    DRUID = { { spell = 1850, ranks = { 1850, 9821 }, cooldown = true } },         -- Spurt (nur in Katzengestalt)
}

-- Zauber-IDs aller Reisegestalten
T.TRAVEL_FORMS = {}
for _, lists in ipairs({ T.CLASS_SPEED, T.CLASS_WATER }) do
    for _, entries in pairs(lists) do
        for _, entry in ipairs(entries) do
            if entry.form then T.TRAVEL_FORMS[entry.spell] = true end
        end
    end
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
    return self.TRAVEL_FORMS[spellID] and spellID or nil
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
