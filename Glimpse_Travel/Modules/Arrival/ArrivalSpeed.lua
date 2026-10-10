local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local T = Glimpse:GetModule("TravelAddon")
local L = T.L

-- Tempo der Tiefenbahn als eigene Zeile. Der Core zählt die Yards der laufenden Fahrt (Travel:GetTramRide), hier wird
-- daraus alle SAMPLE Sekunden das Tempo, in km/h oder mph je nach Entfernungseinheit des Core (Meter oder Yards).
-- Nichts wird gespeichert.

local SAMPLE = 1
local KMH = 0.9144 * 3.6     -- 1 yd/s in km/h
local MPH = 3600 / 1760      -- 1 yd/s in mph

-- Spruch nach Tempo in km/h (auch bei mph-Anzeige), %s = Tempo mit Einheit. Der erste passende gilt (Spitze der Bahn 136 bis 141 km/h). Die letzte Stufe hat mehrere
-- Sprüche: Bei jedem neuen Erreichen der Grenze kommt ein anderer, zufällig gewählt.
T.TRAM_SPEED_TEXTS = {
    { below = 30, text = L["Gnome speedometer %s, cozy as a dwarf after his ale"] },
    { below = 100, text = L["Gnome speedometer %s, the gnomes are stoking the boiler"] },
    { below = 138, text = L["Gnome speedometer %s, Mekkatorque would nod contentedly"] },
    { texts = {
        L["Gnome speedometer %s, top speed, please hold on tight!"],
        L["Gnome speedometer %s, Mekkatorque has lit the turbo!"],
        L["Gnome speedometer %s, faster than a gryphon with a tailwind"],
        L["Gnome speedometer %s, the boiler rivets are starting to sing"],
        L["Gnome speedometer %s, record run, Ironforge is amazed"],
        L["Gnome speedometer %s, light gnomes please hold on to someone heavy"],
    } },
}

-- Greifenflug: ein Spruch pro Flug, zufällig gewählt, nie derselbe wie beim letzten Flug
T.FLIGHT_SPEED_TEXTS = {
    L["Dwarf speedometer %s, the gryphon has had its ale"],
    L["Dwarf speedometer %s, hold on to your beard, it gets windy!"],
    L["Dwarf speedometer %s, faster than any dwarf ever stumbled"],
    L["Dwarf speedometer %s, the gryphon master promises a soft landing, maybe"],
    L["Dwarf speedometer %s, mind the tankard, the foam is flying"],
    L["Dwarf speedometer %s, by the anvil of Ironforge, what a tailwind!"],
}

local sample -- { at, yards }
local flightPick, lastFlightPick -- Spruch des laufenden Flugs; zuletzt gewählter
local top, lastTop -- Index des Spruchs der letzten Stufe, solange sie gilt; zuletzt gezeigter

function T:ResetSpeed()
    sample, top, flightPick = nil, nil, nil
end

--- "meters" oder "yards" aus den Glimpse-Optionen (Allgemein, Entfernung)
function T:SpeedUnit()
    return Glimpse.GetDistanceUnit and Glimpse:GetDistanceUnit() or "meters"
end

--- Tempo aus yd/s als "139 km/h" bzw. "86 mph" (Einheit des Core)
function T:FormatSpeed(yardsPerSecond)
    if self:SpeedUnit() == "yards" then return format(L["%d mph"], math.floor(yardsPerSecond * MPH + 0.5)) end
    return format(L["%d km/h"], math.floor(yardsPerSecond * KMH + 0.5))
end

--- Text der Tempozeile aus yd/s
function T:SpeedText(yardsPerSecond)
    local kmh = math.floor(yardsPerSecond * KMH + 0.5)
    local shown = self:FormatSpeed(yardsPerSecond)
    for _, entry in ipairs(self.TRAM_SPEED_TEXTS) do
        if not entry.below or kmh < entry.below then
            if not entry.texts then
                top = nil
                return format(entry.text, shown)
            end
            if not top then
                local count = #entry.texts
                top = self.api.random(count > 1 and lastTop and count - 1 or count)
                if count > 1 and lastTop and top >= lastTop then top = top + 1 end -- nie zweimal derselbe
                lastTop = top
            end
            return format(entry.texts[top], shown)
        end
    end
end

--- Im Takt der Fahrt: neues Tempo oder nil (noch keine Messung, Option aus, Core ohne GetTramRide)
function T:CheckSpeed(now)
    if not self:Opt("tramSpeed") then return nil end
    local coreRide = self.api.GetTramRide and self.api.GetTramRide()
    if not (coreRide and coreRide.yards) then return nil end
    if not sample then
        sample = { at = now, yards = coreRide.yards }
        return nil
    end
    if now - sample.at < SAMPLE then return nil end
    local speed = (coreRide.yards - sample.yards) / (now - sample.at)
    sample.at, sample.yards = now, coreRide.yards
    return self:SpeedText(math.max(speed, 0))
end

--- Flug: alle SAMPLE Sekunden das gemessene Tempo des Spielers mit dem Spruch des Flugs, sonst nil
function T:CheckFlightSpeed(now)
    if not self:Opt("flightSpeed") then return nil end
    if sample and now - sample.at < SAMPLE then return nil end
    sample = { at = now }
    local speed = self:PlayerSpeed()
    if not (speed and speed > 0) then return nil end
    if not flightPick then
        local count = #self.FLIGHT_SPEED_TEXTS
        flightPick = self.api.random(lastFlightPick and count - 1 or count)
        if lastFlightPick and flightPick >= lastFlightPick then flightPick = flightPick + 1 end
        lastFlightPick = flightPick
    end
    return format(self.FLIGHT_SPEED_TEXTS[flightPick], self:FormatSpeed(speed))
end
