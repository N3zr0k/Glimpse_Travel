local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local T = Glimpse:GetModule("TravelAddon")
local L = T.L

-- Countdown bis zur Ankunft für Fahrten, die der Core meldet. Erkennen und Messen macht das Core-Modul Reisen:
--   GLIMPSE_TRAVEL_RIDE_START  kind, id, startTime, seconds   seconds = Fahrzeit (Tiefenbahn fest 58, Flug nil)
--   GLIMPSE_TRAVEL_RIDE_END    kind, id          bei Ankunft, Halt, Aussteigen, Ladebildschirm oder Abbruch (ab Core 0.3.16)
-- Was zu einer Art von Fahrt gehört, steht in deren Modul (DeeprunTram, FlightRide) und meldet sich hier an:
--   T:RegisterRide(kind, { info, wanted, start, tick, moved, finish, resume, arrived })
--   info(self, id) -> Name des Ziels, erwartete Sekunden    wanted(self) -> läuft die Fahrt auch ohne Countdown?
--   start(self, ride), tick(self, ride, now), moved(self, ride, now), finish(self, ride, now) bei echter Ankunft
--   resume = Sekunden, die ein zu frühes Ende abgewartet wird; arrived(self) = Anteil der Fahrzeit, ab dem ein Ende zählt

local TICK = 0.2       -- Sekunden
local SOUND_AT = 5     -- Sekunden vor der Ankunft
local GIVE_UP = 60     -- Sekunden nach der erwarteten Ankunft ohne Ende-Nachricht: ausblenden
local SOUND = SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959

local kinds = {}
local ride -- { kind, id, start, seconds, name, sounded, silent, pausedAt }

function T:RegisterRide(kind, handler)
    kinds[kind] = handler
end

--- "1 min 05 s", "42 s"
function T.FormatRemaining(seconds)
    seconds = math.max(0, math.floor(seconds + 0.5))
    if seconds < 60 then return format(L["%d s"], seconds) end
    return format(L["%d min %02d s"], math.floor(seconds / 60), seconds % 60)
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
    local handler = kinds[ride.kind]
    if (ride.seconds and now - ride.start > ride.seconds + GIVE_UP)
        or (ride.pausedAt and now - ride.pausedAt > handler.resume) then
        self:RideEnd()
        return
    end
    if self:Opt("arrivalSound") and not ride.silent and ride.seconds and not ride.sounded and ride.seconds - (now - ride.start) <= SOUND_AT then
        ride.sounded = true
        if self.api.PlaySound then self.api.PlaySound(SOUND) end
    end
    if handler.tick then handler.tick(self, ride, now) end
    self:ExpireNote(now)
    self:ShowCountdown(self:CountdownText(now))
end

function T:RideStart(kind, id, startTime, seconds)
    local handler = kinds[kind]
    if not handler then return end
    -- Während der Fahrt startet nichts neu: Bewegt man sich im Wagen, meldet der Core Ende und Start erneut.
    if ride and ride.kind == kind then
        ride.pausedAt = nil
        return
    end
    if not self:Opt("arrival") and not (handler.wanted and handler.wanted(self)) then return end
    local name, known = handler.info(self, id)
    seconds = seconds or known
    local now = self.api.GetTime()
    ride = { kind = kind, id = id, start = startTime or now, seconds = seconds, name = name }
    if handler.start then handler.start(self, ride) end
    ride.silent = not self:Opt("arrival")
    self:StartTicker()
    self:RideTick(now)
end

--- arrived = true, wenn der Core das Ende meldet (nicht bei Aufgeben oder Abschalten)
function T:RideEnd(arrived)
    local handler = ride and kinds[ride.kind]
    -- Zu frühes Ende: erst abwarten, ob die Fahrt weitergeht (resume)
    if arrived and handler and handler.resume and not ride.pausedAt then
        local now = self.api.GetTime()
        if now - ride.start < ride.seconds * handler.arrived(self) then
            ride.pausedAt = now
            return
        end
    end
    local done = ride
    ride = nil
    self:StopTicker()
    self:HideArrival()
    if arrived and handler and handler.finish then handler.finish(self, done, self.api.GetTime()) end
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

--- Bewegung während einer Fahrt (Tiefenbahn: rote Warnung)
function T:RideMoved(now)
    local handler = ride and kinds[ride.kind]
    if handler and handler.moved then handler.moved(self, ride, now) end
end

--- Für Tests und /gli travel
function T:CurrentRide() return ride end

function T:ArrivalEnable()
    self:RegisterMessage("GLIMPSE_TRAVEL_RIDE_START", function(_, kind, id, startTime, seconds)
        T:RideStart(kind, id, startTime, seconds)
    end)
    self:RegisterMessage("GLIMPSE_TRAVEL_RIDE_END", function() T:RideEnd(true) end)
    self:RegisterEvent("PLAYER_STARTED_MOVING", function() T:RideMoved(T.api.GetTime()) end)
end
