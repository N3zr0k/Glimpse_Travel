local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local T = Glimpse:GetModule("TravelAddon")
local L = T.L

-- Flugroute als Fahrt für das Arrival-Modul. Der Core meldet Start und Ende (kind "flight", id = Route von * 10000 + nach);
-- die erwartete Zeit ist der Durchschnitt aus der Datenbank (Modules/FlightTime).

-- Namen der Flugpunkte merken, solange die Flugkarte offen ist (nur für die Anzeige, nichts wird gespeichert)
T.nodeNames = {}
function T:RememberNodeNames()
    local api = self.api
    if not (api.C_TaxiMap and api.C_TaxiMap.GetAllTaxiNodes and api.GetTaxiMapID) then return end
    local mapID = api.GetTaxiMapID()
    if not mapID then return end
    for _, node in ipairs(api.C_TaxiMap.GetAllTaxiNodes(mapID) or {}) do
        if node.nodeID and node.name then self.nodeNames[node.nodeID] = node.name end
    end
end

--- Name des Ziels und erwartete Dauer einer Route
local function Info(self, id)
    local reader = self:TravelReader()
    local from, to = math.floor(id / 10000), id % 10000
    local seconds = reader and self:RouteTime(reader, from, to)
    return self.nodeNames[to] or L["your destination"], seconds
end

local function Tick(self, _, now)
    local text = self:CheckFlightSpeed(now)
    if text then self:ShowSpeed(text) end
end

T:RegisterRide("flight", {
    wanted = function(self) return self:Opt("flightSpeed") end,
    info = Info,
    start = function(self) self:FlightSpeedReset() end,
    tick = Tick,
})

function T:FlightRideEnable()
    self:RegisterEvent("TAXIMAP_OPENED", function() T:RememberNodeNames() end)
end
