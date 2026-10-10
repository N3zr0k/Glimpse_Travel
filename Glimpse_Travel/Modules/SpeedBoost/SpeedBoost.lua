local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local T = Glimpse:GetModule("TravelAddon")

-- Letzter Versuch, wenn weder Reittier noch Reisegestalt gehen (an Land und im Wasser): erst eine Tempo-Fähigkeit der
-- Klasse (T.SPEED_BOOSTS, Option speedBoost), dann ein Tempotrank aus den Taschen (Option speedPotion, verbraucht ihn).
-- Läuft die Abklingzeit oder wirkt der Buff schon, wird übersprungen.
-- Fähigkeiten, die das Tempo kurz erhöhen (eigene Option); erst, wenn weder Reittier noch Reisegestalt gehen
T.SPEED_BOOSTS = {
    ROGUE = { { spell = 2983, ranks = { 2983, 8696, 11305 }, cooldown = true } },  -- Sprinten
    DRUID = { { spell = 1850, ranks = { 1850, 9821 }, cooldown = true } },         -- Spurt (nur in Katzengestalt)
}

T.SPEED_POTIONS = {
    { item = 2459, aura = 2379 },  -- Beweglichkeitstrank
}

--- Läuft die Abklingzeit eines Gegenstands (Tränke teilen sie sich)?
function T:ItemOnCooldown(itemID)
    if not self.api.GetItemCooldown then return false end
    local ok, start, duration = pcall(self.api.GetItemCooldown, itemID)
    return ok and (start or 0) > 0 and (duration or 0) > 1.5
end

local function Potion(self)
    if not self.api.GetItemCount then return nil, "no item API" end
    local reason = "no speed potion in the bags"
    for _, potion in ipairs(self.SPEED_POTIONS) do
        if self:HasAura(potion.aura) then return nil, "speed potion already active" end
        local ok, count = pcall(self.api.GetItemCount, potion.item)
        if ok and (count or 0) > 0 then
            if not self:ItemOnCooldown(potion.item) then
                return { type = "item", item = "item:" .. potion.item }, "speed potion " .. potion.item
            end
            reason = "speed potion on cooldown"
        end
    end
    return nil, reason
end

--- Aktion oder nil; reason ist der bisherige Grund fürs Log
function T:BoostAction(ctx, reason)
    if self:Opt("speedBoost") then
        local spellID, name = self:ClassSpell(self.SPEED_BOOSTS, ctx)
        if spellID then return { type = "spell", spell = name }, "speed ability " .. spellID end
        reason = reason .. ", " .. name
    end
    if self:Opt("speedPotion") then
        local action, why = Potion(self)
        if action then return action, why end
        reason = reason .. ", " .. why
    end
    return nil, reason
end
