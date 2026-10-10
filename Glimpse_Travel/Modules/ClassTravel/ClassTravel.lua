local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local T = Glimpse:GetModule("TravelAddon")

-- Klassenfertigkeiten, mit denen man an Land schneller reist, in der Reihenfolge der Wahl. Die Beschreibung der Felder
-- gilt auch für Water und SpeedBoost.
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

for _, entries in pairs(T.CLASS_SPEED) do
    for _, entry in ipairs(entries) do
        if entry.form then T:RegisterForm(entry.spell) end
    end
end

--- Aktion "Klassenfertigkeit" oder nil; reason ist der bisherige Grund fürs Log
function T:ClassAction(ctx, reason)
    if not self:Opt("classSpeed") then return nil, reason end
    local spellID, name = self:ClassSpell(self.CLASS_SPEED, ctx)
    if spellID then return { type = "spell", spell = name }, "travel ability " .. spellID end
    return nil, reason .. ", " .. name
end
