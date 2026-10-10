local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local T = Glimpse:GetModule("TravelAddon")
local L = T.L

-- Rote Warnungen, wenn man sich während der Tiefenbahn-Fahrt bewegt. Eine zufällige, nie zweimal dieselbe hintereinander,
-- danach WARNING_PAUSE Sekunden Ruhe. "%s" = Start und Ziel; ist die Richtung unbekannt, fallen diese Texte weg.
T.TRAM_WARNINGS = {
    L["Please do not fall out of the Deeprun Tram during the ride. Unless you have extremely good hiking boots, gills and absolutely no plans for the weekend."],
    { route = true, text = L["Safety warning: High Tinker Mekkatorque reminds all passengers to stay in the car during the ride from %s to %s, as a fall from the track means an extremely long walk."] },
    L["Travel notice: Anyone who falls out of the tram windows will inevitably end up in the dark tunnel bed and has to walk the whole way."],
    L["Announcement from the tram management: Leaving the car during the underwater panorama is strictly forbidden and results in an immediate and lengthy walk."],
    L["Accident report: A careless adventurer missed the platform and is now walking alone on the tracks of the Deeprun Tram built by Mekkatorque."],
    L["Gnomish warning: Mind the platform edges, because whoever loses their footing here gets to walk the route between the dwarves and the humans without transport."],
    L["Monty Shouts: KEEP YOUR ARMS AND LEGS INSIDE IF YOU DO NOT WANT WOODEN SPLINTERS!"],
}
T.WARNING_PAUSE = 20

local last, nextAt = nil, 0

function T:ResetWarnings()
    last, nextAt = nil, 0
end

--- Text der nächsten Warnung oder nil (Option aus, Pause läuft). destination = Ziel-ID der Fahrt
function T:PickWarning(destination, now)
    if not self:Opt("tramWarnings") or now < nextAt then return nil end
    local from, to = self:TramStationName(3 - destination), self:TramStationName(destination)
    local choices = {}
    for index, warning in ipairs(self.TRAM_WARNINGS) do
        local usable = type(warning) == "string" or (from and to)
        if usable and index ~= last then choices[#choices + 1] = index end
    end
    if #choices == 0 then return nil end
    last = choices[self.api.random(#choices)]
    nextAt = now + self.WARNING_PAUSE
    local warning = self.TRAM_WARNINGS[last]
    if type(warning) == "string" then return warning end
    return format(warning.text, from, to)
end
