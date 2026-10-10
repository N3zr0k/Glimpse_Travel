local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local T = Glimpse:GetModule("TravelAddon")
local L = T.L

-- Countdown bis zur Ankunft in der Tiefenbahn und auf der Flugroute. Erkennen und Messen macht der Core-Modul Reisen:
--   GLIMPSE_TRAVEL_RIDE_START  kind, id, startTime, seconds   seconds = Fahrzeit (Tiefenbahn fest 58, Flug nil); kind "tram" (id = Ziel 1 Sturmwind, 2 Eisenschmiede, 0 unbekannt) oder
--                                                    "flight" (id = Route von * 10000 + nach)
--   GLIMPSE_TRAVEL_RIDE_END    kind, id          bei Ankunft, Halt, Aussteigen, Ladebildschirm oder Abbruch (ab Core 0.3.16)
-- Fahrzeit: Tiefenbahn aus der Nachricht, Flug als Durchschnitt aus "travel" (flighttime/flight).

local TICK = 0.2       -- Sekunden
local SOUND_AT = 5     -- Sekunden vor der Ankunft
local GIVE_UP = 60     -- Sekunden nach der erwarteten Ankunft ohne Ende-Nachricht: ausblenden
local RESUME = 10      -- Tiefenbahn: so lange darf nach einem zu frühen Ende ein neuer Start die Fahrt fortsetzen
local SOUND = SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959

T.TRAM_MAPS = { [1] = 1453, [2] = 1455 }  -- uiMapID Sturmwind, Eisenschmiede (für den Namen)
T.TRAM_SECONDS = 58 -- feste Fahrzeit der Tiefenbahn, falls der Core keine mitschickt

local ride -- { kind, id, start, seconds, name, sounded, silent, pausedAt }

--- "1 min 05 s", "42 s"
function T.FormatRemaining(seconds)
    seconds = math.max(0, math.floor(seconds + 0.5))
    if seconds < 60 then return format(L["%d s"], seconds) end
    return format(L["%d min %02d s"], math.floor(seconds / 60), seconds % 60)
end

--- Name der Station (1 Sturmwind, 2 Eisenschmiede), sonst nil
function T:TramStationName(id)
    local map = self.api.GetMapInfo and self.TRAM_MAPS[id] and self.api.GetMapInfo(self.TRAM_MAPS[id])
    return map and map.name or (id == 1 and L["Stormwind"]) or (id == 2 and L["Ironforge"]) or nil
end

--- Name und erwartete Dauer einer Fahrt
function T:RideInfo(kind, id)
    local reader = self:TravelReader()
    if kind == "tram" then
        return self:TramStationName(id), self.TRAM_SECONDS
    end
    local from, to = math.floor(id / 10000), id % 10000
    local seconds = reader and self:RouteTime(reader, from, to)
    return self.nodeNames[to] or L["your destination"], seconds
end

--- Text der grünen Zeile zum Zeitpunkt now; silent = Option "arrival" aus, nur die Hinweise an Punkten laufen
function T:CountdownText(now)
    if not ride or ride.silent then return nil end
    local name = ride.name -- nil: Ziel unbekannt
    if not ride.seconds then
        return name and format(L["Next stop: %s (flight time is being measured)"], name)
            or L["Next stop (flight time is being measured)"]
    end
    local left = ride.seconds - (now - ride.start)
    if left <= 0 then return name and format(L["Arriving in %s"], name) or L["Arriving at the next station"] end
    return name and format(L["Arrival in %s in %s"], name, T.FormatRemaining(left))
        or format(L["Next station in %s"], T.FormatRemaining(left))
end

function T:RideTick(now)
    if not ride then return end
    if (ride.seconds and now - ride.start > ride.seconds + GIVE_UP) or (ride.pausedAt and now - ride.pausedAt > RESUME) then
        self:RideEnd()
        return
    end
    if self:Opt("arrivalSound") and not ride.silent and ride.seconds and not ride.sounded and ride.seconds - (now - ride.start) <= SOUND_AT then
        ride.sounded = true
        if self.api.PlaySound then self.api.PlaySound(SOUND) end
    end
    if ride.kind == "tram" then
        local text = self:CheckPoints(ride.name, now - ride.start, ride.seconds)
        if text then self:ShowNote(text, now) end
        local speedText = self:CheckSpeed(now)
        if speedText then self:ShowSpeed(speedText) end
    elseif ride.kind == "flight" then
        local speedText = self:CheckFlightSpeed(now)
        if speedText then self:ShowSpeed(speedText) end
    end
    self:ExpireNote(now)
    self:ShowCountdown(self:CountdownText(now))
end

function T:RideStart(kind, id, startTime, seconds)
    -- Während der Fahrt startet nichts neu: Bewegt man sich im Wagen, meldet der Core Ende und Start erneut.
    if ride and ride.kind == kind then
        ride.pausedAt = nil
        return
    end
    local tramExtras = kind == "tram" and (self:Opt("tramNotes") or self:Opt("tramWarnings") or self:Opt("tramSpeed"))
    local flightExtras = kind == "flight" and self:Opt("flightSpeed")
    if not self:Opt("arrival") and not tramExtras and not flightExtras then return end
    local name, known = self:RideInfo(kind, id)
    seconds = seconds or known
    local now = self.api.GetTime()
    ride = { kind = kind, id = id, start = startTime or now, seconds = seconds, name = name }
    self:ResetPoints()
    self:ResetWarnings()
    self:ResetSpeed()
    ride.silent = not self:Opt("arrival")
    self:StartTicker()
    self:RideTick(now)
end

--- arrived = true, wenn der Core das Ende meldet (nicht bei Aufgeben oder Abschalten)
function T:RideEnd(arrived)
    -- Tiefenbahn vor der Ankunft: erst abwarten, ob die Fahrt weitergeht (RESUME)
    if arrived and ride and ride.kind == "tram" and not ride.pausedAt then
        local now = self.api.GetTime()
        if now - ride.start < ride.seconds * self.ARRIVED then
            ride.pausedAt = now
            return
        end
    end
    local done = ride
    ride = nil
    self:StopTicker()
    self:HideArrival()
    -- Begrüßung am Ziel, nur wenn die Fahrt wirklich ankam (nicht bei Abbruch oder Aussteigen unterwegs)
    if arrived and done and done.kind == "tram" then
        local now = self.api.GetTime()
        local text = self:CheckPoints(done.name, now - done.start, done.seconds, true)
        if text then
            self:ShowNote(text, now)
            if self.api.After then self.api.After(self.NOTE_SECONDS + 0.1, function() T:ExpireNote(T.api.GetTime()) end) end
        end
    end
end

local ticker
function T:StartTicker()
    if ticker or not self.api.NewTicker then return end
    ticker = self.api.NewTicker(TICK, function() T:RideTick(T.api.GetTime()) end)
end

function T:StopTicker()
    if ticker then ticker:Cancel() end
    ticker = nil
end

--- Bewegung während der Tiefenbahn-Fahrt: rote Warnung
function T:RideMoved(now)
    if not (ride and ride.kind == "tram") then return end
    local text = self:PickWarning(ride.id, now)
    if text then self:ShowWarning(text, now) end
end

--- Für Tests und /gli travel
function T:CurrentRide() return ride end

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

function T:ArrivalEnable()
    self:RegisterMessage("GLIMPSE_TRAVEL_RIDE_START", function(_, kind, id, startTime, seconds)
        T:RideStart(kind, id, startTime, seconds)
    end)
    self:RegisterMessage("GLIMPSE_TRAVEL_RIDE_END", function() T:RideEnd(true) end)
    self:RegisterEvent("TAXIMAP_OPENED", function() T:RememberNodeNames() end)
    self:RegisterEvent("PLAYER_STARTED_MOVING", function() T:RideMoved(T.api.GetTime()) end)
end
