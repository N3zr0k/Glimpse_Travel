local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local T = Glimpse:GetModule("TravelAddon")
local L = T.L

-- Tiefenbahn als Fahrt für das Arrival-Modul: Name und Dauer, Hinweise, Warnungen, Tempo.
-- Der Core meldet Start und Ende (GLIMPSE_TRAVEL_RIDE_START/_END, kind "tram", id = Ziel 1 Sturmwind, 2 Eisenschmiede, 0 unbekannt).

T.TRAM_MAPS = { [1] = 1453, [2] = 1455 }  -- uiMapID Sturmwind, Eisenschmiede (für den Namen)
T.TRAM_SECONDS = 58 -- feste Fahrzeit der Tiefenbahn, falls der Core keine mitschickt
T.ARRIVED = 0.9     -- ab diesem Anteil der Fahrzeit zählt ein Ende als Ankunft
local RESUME = 10   -- so lange darf nach einem zu frühen Ende ein neuer Start die Fahrt fortsetzen

--- Name der Station (1 Sturmwind, 2 Eisenschmiede), sonst nil
function T:TramStationName(id)
    local map = self.api.GetMapInfo and self.TRAM_MAPS[id] and self.api.GetMapInfo(self.TRAM_MAPS[id])
    return map and map.name or (id == 1 and L["Stormwind"]) or (id == 2 and L["Ironforge"]) or nil
end

local function Wanted(self)
    return self:Opt("tramNotes") or self:Opt("tramWarnings") or self:Opt("tramSpeed")
end

local function Start(self)
    self:ResetPoints()
    self:ResetWarnings()
    self:TramSpeedReset()
end

local function Tick(self, ride, now)
    local text = self:CheckPoints(ride.name, now - ride.start, ride.seconds)
    if text then self:ShowNote(text, now) end
    local speedText = self:CheckTramSpeed(now)
    if speedText then self:ShowSpeed(speedText) end
end

local function Moved(self, ride, now)
    local text = self:PickWarning(ride.id, now)
    if text then self:ShowWarning(text, now) end
end

-- Ende der Fahrt: Begrüßung am Ziel, nur wenn sie wirklich ankam (nicht bei Abbruch oder Aussteigen unterwegs)
local function Finish(self, ride, now)
    local text = self:CheckPoints(ride.name, now - ride.start, ride.seconds, true)
    if text then
        self:ShowNote(text, now)
        if self.api.After then self.api.After(self.NOTE_SECONDS + 0.1, function() T:ExpireNote(T.api.GetTime()) end) end
    end
end

T:RegisterRide("tram", {
    wanted = Wanted,
    info = function(self, id) return self:TramStationName(id), self.TRAM_SECONDS end,
    start = Start,
    tick = Tick,
    moved = Moved,
    finish = Finish,
    resume = RESUME,          -- Sekunden Wartezeit nach zu frühem Ende
    arrived = function(self) return self.ARRIVED end, -- Anteil der Fahrzeit, ab dem ein Ende eine Ankunft ist
})
