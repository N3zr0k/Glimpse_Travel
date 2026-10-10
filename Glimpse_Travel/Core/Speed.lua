local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local T = Glimpse:GetModule("TravelAddon")
local L = T.L

-- Tempo-Umrechnung für alle Anzeigen (Tiefenbahn, Greifenflug, Portrait). Nichts wird gespeichert.

T.KMH = 0.9144 * 3.6     -- 1 yd/s in km/h
T.MPH = 3600 / 1760      -- 1 yd/s in mph

--- "meters" oder "yards" aus den Glimpse-Optionen (Allgemein, Entfernung)
function T:SpeedUnit()
    return Glimpse.GetDistanceUnit and Glimpse:GetDistanceUnit() or "meters"
end

--- Tempo aus yd/s als "139 km/h" bzw. "86 mph" (Einheit des Core)
function T:FormatSpeed(yardsPerSecond)
    if self:SpeedUnit() == "yards" then return format(L["%d mph"], math.floor(yardsPerSecond * T.MPH + 0.5)) end
    return format(L["%d km/h"], math.floor(yardsPerSecond * T.KMH + 0.5))
end
