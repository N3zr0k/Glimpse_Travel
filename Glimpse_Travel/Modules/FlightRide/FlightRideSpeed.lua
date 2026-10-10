local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local T = Glimpse:GetModule("TravelAddon")
local L = T.L

-- Tempo auf Flügen als eigene Zeile unter der Flugzeit: das gemessene Tempo des Spielers mit einem Spruch, bei der Allianz
-- von den Zwergen, bei der Horde vom Windreiter. Einer pro Flug, zufällig gewählt und nie derselbe wie beim letzten Flug.

local SAMPLE = 1

T.FLIGHT_SPEED_TEXTS = {
    Alliance = {
        L["Dwarf speedometer %s, the gryphon has had its ale"],
        L["Dwarf speedometer %s, hold on to your beard, it gets windy!"],
        L["Dwarf speedometer %s, faster than any dwarf ever stumbled"],
        L["Dwarf speedometer %s, the gryphon master promises a soft landing, maybe"],
        L["Dwarf speedometer %s, mind the tankard, the foam is flying"],
        L["Dwarf speedometer %s, by the anvil of Ironforge, what a tailwind!"],
    },
    Horde = {
        L["Windrider speedometer %s, Orgrimmar sends loud regards!"],
        L["Windrider speedometer %s, Lok'tar ogar, hold on tight!"],
        L["Windrider speedometer %s, the wind rider spotted a juicy boar below"],
        L["Windrider speedometer %s, faster than a goblin chasing gold"],
        L["Windrider speedometer %s, the tauren in the saddle keeps chewing calmly"],
        L["Windrider speedometer %s, Thrall would be proud!"],
    },
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
    local texts = self.FLIGHT_SPEED_TEXTS[self:PlayerFaction()]
    if not pick then
        local count = #texts
        pick = self.api.random(lastPick and count - 1 or count)
        if lastPick and pick >= lastPick then pick = pick + 1 end
        lastPick = pick
    end
    return format(texts[pick], self:FormatSpeed(speed))
end
