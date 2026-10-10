local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local T = Glimpse:GetModule("TravelAddon")

-- Im Wasser: Wassergestalt der Klasse (Option Klassenfertigkeit), sonst ein Schwimmtrank aus den Taschen (eigene Option,
-- weil er verbraucht wird). Ein Trank mit aktivem Buff wird nicht noch einmal getrunken.
T.CLASS_WATER = {
    DRUID = { { spell = 1066, form = true } },                   -- Wassergestalt
}
for _, entries in pairs(T.CLASS_WATER) do
    for _, entry in ipairs(entries) do
        if entry.form then T:RegisterForm(entry.spell) end
    end
end

T.SWIM_POTIONS = {
    { item = 6372, aura = 7840 },  -- Trank der Schwimmgeschwindigkeit
}

--- Aktion für das Wasser oder nil und Grund
function T:WaterAction(ctx)
    local reason = "nothing for the water"
    if self:Opt("classSpeed") then
        local spellID, name = self:ClassSpell(self.CLASS_WATER, ctx)
        if spellID then return { type = "spell", spell = name }, "water form " .. spellID end
        reason = name -- ohne Zauber steht hier der Grund
    end
    if self:Opt("swimPotion") and self.api.GetItemCount then
        for _, potion in ipairs(self.SWIM_POTIONS) do
            if self:HasAura(potion.aura) then return nil, "swim potion already active" end
            local ok, count = pcall(self.api.GetItemCount, potion.item)
            if ok and (count or 0) > 0 then
                return { type = "item", item = "item:" .. potion.item }, "swim potion " .. potion.item
            end
        end
        reason = "no swim potion in the bags"
    end
    return nil, reason
end
