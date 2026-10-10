local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local T = Glimpse:GetModule("TravelAddon")
local L = T.L

-- Tempo auf Greifenflügen als eigene Zeile unter der Flugzeit: das gemessene Tempo des Spielers mit einem Zwergenspruch,
-- einer pro Flug, zufällig gewählt und nie derselbe wie beim letzten Flug.

local SAMPLE = 1

T.FLIGHT_SPEED_TEXTS = {
    L["Dwarf speedometer %s, the gryphon has had its ale"],
    L["Dwarf speedometer %s, hold on to your beard, it gets windy!"],
    L["Dwarf speedometer %s, faster than any dwarf ever stumbled"],
    L["Dwarf speedometer %s, the gryphon master promises a soft landing, maybe"],
    L["Dwarf speedometer %s, mind the tankard, the foam is flying"],
    L["Dwarf speedometer %s, by the anvil of Ironforge, what a tailwind!"],
}

local lastAt          -- Zeitpunkt der letzten Messung
local pick, lastPick  -- Spruch des laufenden Flugs; zuletzt gewählter

function T:FlightSpeedReset()
    lastAt, pick = nil, nil
end

--- Alle SAMPLE Sekunden das gemessene Tempo des Spielers mit dem Spruch des Flugs, sonst nil
function T:CheckFlightSpeed(now)
    if not self:Opt("flightSpeed") then return nil end
    if lastAt and now - lastAt < SAMPLE then return nil end
    lastAt = now
    local speed = self:PlayerSpeed()
    if not (speed and speed > 0) then return nil end
    if not pick then
        local count = #self.FLIGHT_SPEED_TEXTS
        pick = self.api.random(lastPick and count - 1 or count)
        if lastPick and pick >= lastPick then pick = pick + 1 end
        lastPick = pick
    end
    return format(self.FLIGHT_SPEED_TEXTS[pick], self:FormatSpeed(speed))
end
