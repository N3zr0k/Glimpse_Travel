local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local T = Glimpse:GetModule("TravelAddon")
local L = T.L

-- Hinweise während der Tiefenbahn-Fahrt. In der Tiefenbahn gibt der Client keine Koordinaten, deshalb zählt die Zeit
-- seit der Abfahrt (meldet der Core):
--   at       Sekunden nach der Abfahrt
--   percent  Anteil der gemessenen Fahrzeit; ohne Messung entfällt der Hinweis
--   arrival  bei der Ankunft (Ende der Fahrt nach mindestens ARRIVED der Fahrzeit)
-- text mit %s = Name des Ziels, "Titel: Text" zeigt den Titel fett. Ist das Ziel unbekannt, gibt es keine Hinweise. Jeder erscheint einmal je Fahrt.
T.TRAM_POINTS = {
    { at = 1, text = L["Departure to %s"] },
    { percent = 25, text = L["A quarter of the way to %s"] },
    { percent = 42, text = L["Above you a mysterious body of water. Sea? Lake? Aquarium? Only High Tinker Mekkatorque knows!"] },
    { percent = 75, text = L["Almost there: %s"] },
    { arrival = true, text = L["Welcome to %s"] },
}
T.ARRIVED = 0.9

local shown = {} -- [Index] = true, je Fahrt

function T:ResetPoints()
    wipe(shown)
end

local function Due(point, elapsed, expected, arrived)
    if point.arrival then return arrived and expected ~= nil and elapsed >= expected * T.ARRIVED end
    if arrived then return false end
    if point.at then return elapsed >= point.at end
    return expected ~= nil and elapsed >= expected * point.percent / 100
end

--- Text des fälligen Hinweises oder nil. elapsed = Sekunden seit der Abfahrt, expected = erwartete Fahrzeit,
-- arrived = true beim Ende der Fahrt. Sind mehrere fällig (Ruckler), zählt der letzte.
function T:CheckPoints(name, elapsed, expected, arrived)
    if not (self:Opt("tramNotes") and name) then return nil end
    local text
    for index, point in ipairs(self.TRAM_POINTS) do
        if not shown[index] and Due(point, elapsed, expected, arrived) then
            shown[index] = true
            text = format(point.text, name)
        end
    end
    return text
end
