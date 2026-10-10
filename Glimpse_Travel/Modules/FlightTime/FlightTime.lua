local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local T = Glimpse:GetModule("TravelAddon")

-- Flugzeiten aus dem Core-Modul Reisen (Namespace "travel"): flight = Zahl der Flüge, flighttime = Sekunden, je Strecke
-- von * 10000 + nach (nodeIDs). Flugzeiten sind für alle Charaktere gleich, gelesen wird daher über den Account.
-- Ist die ganze Strecke noch nie geflogen, wird aus den Teilstrecken geschätzt, sofern jede gemessen ist.

local SCOPE = "account"

function T.RouteID(from, to)
    return from * 10000 + to
end

--- Leser für "travel" oder nil ohne Glimpse: Database
function T:TravelReader()
    local DB = self.api.GetDatabase()
    if not (DB and DB.Get) then return nil end
    local ok, reader = pcall(DB.Get, DB, "travel")
    return ok and reader or nil
end

--- Durchschnitt in Sekunden und Zahl der Flüge einer Strecke, nil wenn nie geflogen
function T:RouteTime(reader, from, to)
    local route = T.RouteID(from, to)
    local flights = reader:GetCount("flight", route, SCOPE) or 0
    if flights <= 0 then return nil end
    local seconds = reader:GetCount("flighttime", route, SCOPE) or 0
    return seconds / flights, flights
end

--- path = nodeIDs vom Start bis zum Ziel (mit Zwischenhalten).
-- Rückgabe: Sekunden, "measured" mit Zahl der Flüge oder "estimated" mit Zahl der Teilstrecken; nil ohne Daten
function T:FlightTime(path)
    if not path or #path < 2 then return nil end
    local reader = self:TravelReader()
    if not reader then return nil end
    local seconds, flights = self:RouteTime(reader, path[1], path[#path])
    if seconds then return seconds, "measured", flights end
    if #path < 3 then return nil end
    local total = 0
    for index = 1, #path - 1 do
        local part = self:RouteTime(reader, path[index], path[index + 1])
        if not part then return nil end
        total = total + part
    end
    return total, "estimated", #path - 1
end

--- "1:05", "12:30", "1:02:03"
function T.FormatDuration(seconds)
    seconds = math.floor(seconds + 0.5)
    local hours, minutes = math.floor(seconds / 3600), math.floor(seconds % 3600 / 60)
    if hours > 0 then return format("%d:%02d:%02d", hours, minutes, seconds % 60) end
    return format("%d:%02d", minutes, seconds % 60)
end
