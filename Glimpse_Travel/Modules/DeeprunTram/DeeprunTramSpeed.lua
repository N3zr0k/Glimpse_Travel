local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local T = Glimpse:GetModule("TravelAddon")
local L = T.L

-- Tempo der Tiefenbahn als eigene Zeile. Der Core zählt die Yards der laufenden Fahrt (Travel:GetTramRide), hier wird
-- daraus alle SAMPLE Sekunden das Tempo, in km/h oder mph je nach Entfernungseinheit des Core (Meter oder Yards).
-- Nichts wird gespeichert.

local SAMPLE = 1

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

local sample -- { at, yards }
local top, lastTop -- Index des Spruchs der letzten Stufe, solange sie gilt; zuletzt gezeigter

function T:TramSpeedReset()
    sample, top = nil, nil
end

--- Text der Tempozeile aus yd/s
function T:TramSpeedText(yardsPerSecond)
    local kmh = math.floor(yardsPerSecond * T.KMH + 0.5)
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
function T:CheckTramSpeed(now)
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
    return self:TramSpeedText(math.max(speed, 0))
end
