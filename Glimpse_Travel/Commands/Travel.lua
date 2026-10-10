local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local T = Glimpse:GetModule("TravelAddon")
local L = T.L

-- /gli travel   Einstellungen, Taste, was der Client zu Reittieren und Klassenfertigkeiten meldet, laufende Fahrt mit
--               Sekunden seit der Abfahrt (für die Hinweise in ArrivalPoints.lua), letzte Doppelklicks

local function OnOff(value) return value and "on" or "off" end

function T:StatusLines()
    local lines = {}
    lines[#lines + 1] = format("mount %s, class ability %s, speed ability %s, speed potion %s, swim potion %s, key: %s",
        OnOff(self:Opt("mount")), OnOff(self:Opt("classSpeed")), OnOff(self:Opt("speedBoost")), OnOff(self:Opt("speedPotion")),
        OnOff(self:Opt("swimPotion")), self:ActionKeyText() or "not registered")

    local journal = self.api.C_MountJournal
    local mounts = self:MountCandidates()
    local favorites = 0
    for _, mount in ipairs(mounts) do
        if mount.favorite then favorites = favorites + 1 end
    end
    lines[#lines + 1] = format("mount journal: %s, usable mounts: %d (favorites %d)",
        (journal and journal.GetMountIDs) and "yes" or "NO", #mounts, favorites)

    local class = self:PlayerClass() or "?"
    for _, list in ipairs({ self.CLASS_SPEED, self.CLASS_WATER, self.SPEED_BOOSTS }) do
        for _, entry in ipairs(list[class] or {}) do
            lines[#lines + 1] = format("%s %d %s: known %s, usable %s", class, entry.spell,
                tostring(self:SpellName(entry.spell)), OnOff(self:KnowsSpell(entry.spell)), OnOff(self:SpellUsable(entry.spell)))
        end
    end
    lines[#lines + 1] = "active travel form: " .. tostring(self:ActiveTravelForm() or "none")

    local ride = self:CurrentRide()
    lines[#lines + 1] = ride and format("ride: %s %s, %.0f s since departure, expected %s", ride.kind, tostring(ride.id),
        self.api.GetTime() - ride.start, tostring(ride.seconds or "not measured")) or "ride: none"
    for index, text in ipairs(self.actionLog) do lines[#lines + 1] = format("log %d: %s", index, text) end
    return lines
end

Glimpse:RegisterCommand("travel", L["Shows the travel settings, what the client reports about mounts and travel abilities, the current ride and the last double clicks: /gli travel"], function()
    for _, line in ipairs(T:StatusLines()) do Glimpse:Print(line) end
end)
