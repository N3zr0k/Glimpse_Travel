-- luacheck: ignore 111 113 122 143 432
-- Ankunft (Modules/Arrival/*.lua): Countdown für Tiefenbahn und Flugroute, Ton, Hinweise an Punkten, Optionen.
local TravelSetup = require("travel_setup")

local function fontString()
    local fs = { text = "" }
    function fs:SetText(text) self.text = text end
    function fs:GetText() return self.text end
    function fs:SetPoint() end
    function fs:SetTextColor() end
    return fs
end

local function setup(counts)
    local e = TravelSetup()
    local api = e.T.api
    e.now, e.sounds = 1000, 0
    e.fonts = {}
    api.CreateFrame = function()
        local frame = { shown = false }
        function frame:SetSize() end
        function frame:SetPoint() end
        function frame:SetFrameStrata() end
        function frame:Show() self.shown = true end
        function frame:Hide() self.shown = false end
        function frame:SetShown(value) self.shown = value end
        function frame:CreateFontString()
            local fs = fontString()
            e.fonts[#e.fonts + 1] = fs
            return fs
        end
        e.frame = frame
        return frame
    end
    api.GetTime = function() return e.now end
    api.NewTicker = function() return { Cancel = function() end } end
    api.PlaySound = function() e.sounds = e.sounds + 1 end
    api.GetMapInfo = function(id) return ({ [1453] = { name = "Sturmwind" }, [1455] = { name = "Eisenschmiede" } })[id] end
    counts = counts or {}
    local reader = { GetCount = function(_, kind, id) return counts[kind .. ":" .. id] end }
    api.GetDatabase = function() return { Get = function() return reader end } end
    return e
end

-- fonts 1/2 = weißer Hinweis (Titel/Text), 3/4 = rote Warnung, 5 = grüner Countdown, 6 = Tempo
local function green(e) return e.fonts[5] and e.fonts[5].text end
local function white(e) return e.T:ArrivalText("note") end
local function red(e) return e.T:ArrivalText("warning") end

test("Arrival: Tiefenbahn zählt von der Fahrzeit des Core herunter und verschwindet bei Ankunft", function()
    local e = setup()
    e.Glimpse:GetModule("TravelAddon").messages.GLIMPSE_TRAVEL_RIDE_START(nil, "tram", 1, 1000, 65)
    eq(green(e), "Arrival in Sturmwind in 1 min 05 s", "Start, Fahrzeit vom Core")
    e.now = 1030
    e.T:RideTick(e.now)
    eq(green(e), "Arrival in Sturmwind in 35 s", "nach 30 s")
    e.now = 1070
    e.T:RideTick(e.now)
    eq(green(e), "Arriving in Sturmwind", "überfällig")
    e.T.messages.GLIMPSE_TRAVEL_RIDE_END(nil, "tram", 1)
    eq(green(e), "", "Countdown weg"); eq(e.T:CurrentRide(), nil, "Fahrt vorbei")
    eq(white(e), format(e.T.TRAM_POINTS[5].text, "Sturmwind"), "Begrüßung")
    e.now = 1077; e.T:ExpireNote(e.now)
    eq(e.frame.shown, false, "danach ausgeblendet")
end)

test("Arrival: erste Fahrt ohne Messung, Eisenschmiede aus dem Client-Namen", function()
    local e = setup()
    e.T:RideStart("tram", 2, 1000)
    eq(green(e), "Arrival in Eisenschmiede in 58 s", "ohne Messung")
    e.T.api.GetMapInfo = nil
    e.T:RideEnd()
    e.T:RideStart("tram", 2, 1000)
    eq(green(e), "Arrival in Ironforge in 58 s", "eigener Name als Ersatz")
end)

test("Arrival: Flugroute mit Namen aus der Flugkarte und Flugzeit aus dem Core", function()
    local e = setup({ ["flight:100020"] = 1, ["flighttime:100020"] = 150 })
    e.T.nodeNames[20] = "Eisenschmiede"
    e.T:RideStart("flight", 100020, 1000)
    eq(green(e), "Arrival in Eisenschmiede in 2 min 30 s", "Flug")
    e.T:RideEnd()
    e.T:RideStart("flight", 100030, 1000)
    eq(green(e), "Next stop: your destination (flight time is being measured)", "unbekannter Punkt, nicht gemessen")
end)

test("Arrival: Ton nur mit Option, einmal 5 s vor der Ankunft", function()
    local e = setup()
    e.T:RideStart("tram", 1, 1000, 60)
    e.now = 1056; e.T:RideTick(e.now)
    eq(e.sounds, 0, "Option aus")
    e.T:SetOpt("arrivalSound", true)
    e.now = 1000
    e.T:RideStart("tram", 1, 1000, 60)
    e.now = 1054; e.T:RideTick(e.now)
    eq(e.sounds, 0, "zu früh")
    e.now = 1055.5; e.T:RideTick(e.now)
    e.now = 1057; e.T:RideTick(e.now)
    eq(e.sounds, 1, "genau einmal")
end)

test("Arrival: weiße Hinweise 1 s nach Abfahrt, bei 25/42/75 % und bei Ankunft, einmal je Fahrt", function()
    local e = setup()
    local P = e.T.TRAM_POINTS
    e.T:RideStart("tram", 1, 1000, 60)
    eq(white(e), "", "noch nicht fällig")
    e.now = 1001; e.T:RideTick(e.now)
    eq(white(e), format(P[1].text, "Sturmwind"), "nach 1 s")
    e.now = 1015; e.T:RideTick(e.now)
    eq(white(e), format(P[2].text, "Sturmwind"), "25 %")
    e.now = 1026; e.T:RideTick(e.now)
    eq(white(e), P[3].text, "42 %")
    e.now = 1045; e.T:RideTick(e.now)
    eq(white(e), format(P[4].text, "Sturmwind"), "75 %")
    e.now = 1052; e.T:RideTick(e.now)
    eq(white(e), "", "nach 6 s weg, kein zweites Mal")
    e.now = 1060; e.T:RideEnd(true)
    eq(white(e), format(P[5].text, "Sturmwind"), "Ankunft")

    e.now = 2000
    e.T:RideStart("tram", 1, 2000, 60)
    e.now = 2010; e.T:RideEnd(true)
    eq(e.T:CurrentRide() ~= nil, true, "zu früh: Fahrt wartet")
    e.now = 2021; e.T:RideTick(e.now)
    eq(e.T:CurrentRide(), nil, "kein neuer Start: Fahrt vorbei"); eq(white(e), "", "unterwegs ausgestiegen: keine Begrüßung")

    e.T:SetOpt("tramNotes", false)
    e.now = 1000
    e.T:RideStart("tram", 1, 1000, 60)
    e.now = 1001; e.T:RideTick(e.now)
    eq(white(e), "", "Option aus")
end)

test("Arrival: ohne Fahrzeit vom Core gelten 58 s", function()
    local e = setup()
    e.T.TRAM_POINTS = { { percent = 50, text = "Halb nach %s" } }
    e.T:RideStart("tram", 1, 1000)
    eq(green(e), "Arrival in Sturmwind in 58 s", "Countdown mit 58 s")
    e.now = 1029; e.T:RideTick(e.now)
    eq(white(e), "Halb nach Sturmwind", "Hinweis bei 29 s")
end)

test("Arrival: Titel vor dem Doppelpunkt eigene Zeile", function()
    local e = setup()
    e.T:ShowNote("Gleich da: Sturmwind", 1000)
    eq(e.fonts[1].text, "Gleich da", "Titel"); eq(e.fonts[2].text, "Sturmwind", "Text")
    e.T:ShowNote("Ohne Titel. Wirklich!", 1000)
    eq(e.fonts[1].text, "", "kein Titel"); eq(e.fonts[2].text, "Ohne Titel. Wirklich!", "ganzer Text")
end)

test("Arrival: Bewegen im Wagen (Ende und neuer Start vom Core) setzt die Fahrt fort", function()
    local e = setup()
    e.T:RideStart("tram", 1, 1000, 60)
    e.now = 1001; e.T:RideTick(e.now)
    local first = white(e)
    e.now = 1020; e.T.messages.GLIMPSE_TRAVEL_RIDE_END(nil, "tram", 1)
    e.now = 1023; e.T.messages.GLIMPSE_TRAVEL_RIDE_START(nil, "tram", 1, 1023)
    local ride = e.T:CurrentRide()
    eq(ride.start, 1000, "alte Abfahrt bleibt"); eq(ride.pausedAt, nil, "läuft weiter")
    e.now = 1024; e.T:RideTick(e.now)
    eq(green(e), "Arrival in Sturmwind in 36 s", "Countdown läuft weiter")
    e.now = 1030; e.T:RideTick(e.now)
    eq(white(e) ~= first, true, "keine Abfahrt-Meldung ein zweites Mal")
end)

test("Arrival: Tempo der Bahn aus den Yards des Core, in km/h und mph", function()
    local e = setup()
    local coreRide = { yards = 0 }
    e.T.api.GetTramRide = function() return coreRide end
    e.T.api.random = function() return 1 end
    e.T:RideStart("tram", 1, 1000, 60)
    eq(e.fonts[6].text, "", "noch kein Tempo")
    e.now = 1001; coreRide.yards = 5; e.T:RideTick(e.now)
    eq(e.fonts[6].text, format(e.T.TRAM_SPEED_TEXTS[1].text, "16 km/h"), "5 yd/s")
    e.now = 1002; coreRide.yards = 52.7; e.T:RideTick(e.now)
    local tops = e.T.TRAM_SPEED_TEXTS[4].texts
    eq(e.fonts[6].text, format(tops[1], "157 km/h"), "47,7 yd/s, erster Spitzen-Spruch")
    e.now = 1003; coreRide.yards = 100.4; e.T:RideTick(e.now)
    eq(e.fonts[6].text, format(tops[1], "157 km/h"), "bleibt, solange schnell")
    e.now = 1004; coreRide.yards = 140.4; e.T:RideTick(e.now)
    eq(e.fonts[6].text, format(e.T.TRAM_SPEED_TEXTS[3].text, "132 km/h"), "unter 138")
    e.now = 1005; coreRide.yards = 182.4; e.T:RideTick(e.now)
    eq(e.fonts[6].text, format(tops[2], "138 km/h"), "138 wieder erreicht: anderer Spruch")
    e.Glimpse.GetDistanceUnit = function() return "yards" end
    e.now = 1006; coreRide.yards = 224.4; e.T:RideTick(e.now)
    eq(e.fonts[6].text, format(tops[2], "86 mph"), "Einheit Yards: mph")
    e.Glimpse.GetDistanceUnit = nil
    e.T:RideEnd()
    eq(e.fonts[6].text, "", "nach der Fahrt weg")
end)

test("Arrival: Bewegung in der Tiefenbahn zeigt eine rote Warnung, mit Pause und nie zweimal dieselbe", function()
    local e = setup()
    e.T.api.random = function() return 1 end
    e.T.TRAM_WARNINGS = { "Erste", { route = true, text = "Von %s nach %s" } }
    e.T:RideMoved(1000)
    eq(red(e), "", "ohne Fahrt nichts")
    e.T:RideStart("tram", 1, 1000, 60)
    e.T:RideMoved(1005)
    eq(red(e), "Erste", "Warnung")
    e.T:RideMoved(1010)
    eq(red(e), "Erste", "Pause läuft")
    e.now = 1026; e.T:RideTick(e.now)
    eq(red(e), "", "nach 10 s weg")
    e.T:RideMoved(1026)
    eq(red(e), "Von Eisenschmiede nach Sturmwind", "andere Warnung, Start und Ziel eingesetzt")

    e.T:RideEnd()
    e.T:SetOpt("tramWarnings", false)
    e.T:RideStart("tram", 1, 1100, 60)
    e.T:RideMoved(1105)
    eq(red(e), "", "Option aus")
    e.T:RideEnd()
    e.T:SetOpt("tramWarnings", true)
    e.T:RideStart("tram", 0, 1200, 60)
    e.T:RideMoved(1205)
    eq(red(e), "Erste", "Richtung unbekannt: nur Texte ohne Start und Ziel")
end)

test("Arrival: ohne Countdown-Option laufen nur die Hinweise, ohne beides nichts", function()
    local e = setup()
    e.T.TRAM_POINTS = { { at = 0, text = "Hinweis" } }
    e.T:SetOpt("arrival", false)
    e.T:RideStart("tram", 1, 1000, 60)
    eq(green(e), "", "kein Countdown"); eq(white(e), "Hinweis", "Hinweis trotzdem")
    e.T:RideEnd()
    e.T:SetOpt("tramNotes", false)
    e.T:SetOpt("tramWarnings", false)
    e.T:SetOpt("tramSpeed", false)
    e.T:SetOpt("flightSpeed", false)
    e.T:RideStart("tram", 1, 1000, 60)
    eq(e.T:CurrentRide(), nil, "nichts gestartet")
    e.T:RideStart("flight", 100020, 1000)
    eq(e.T:CurrentRide(), nil, "Flug ohne Countdown auch nicht")
end)

test("Arrival: Fahrt ohne Ende-Nachricht wird nach einer Minute Überzeit beendet, /gli travel zeigt die Fahrt", function()
    local e = setup()
    e.T:RideStart("tram", 1, 1000, 60)
    e.now = 1121; e.T:RideTick(e.now)
    eq(e.T:CurrentRide(), nil, "aufgegeben")
    e.now = 1000
    e.T:RideStart("tram", 1, 1000, 60)
    e.now = 1012
    e.Glimpse.commands.travel.func()
    eq(table.concat(e.Glimpse.printed, "\n"):find("ride: tram 1, 12 s since departure, expected 60", 1, true) ~= nil, true, "Fahrt")
    eq(string.format("%s", e.T.FormatRemaining(-3)), "0 s", "nie negativ")
end)

test("Arrival: Tiefenbahn mit unbekanntem Ziel, ohne Fahrzeit vom Core 58 s", function()
    local e = setup()
    e.T:RideStart("tram", 0, 1000)
    eq(green(e), "Next station in 58 s", "58 s")
end)

test("Arrival: Greifenflug zeigt das Tempo mit Zwergenspruch unter der Flugzeit", function()
    local e = setup({ ["flight:100020"] = 1, ["flighttime:100020"] = 150 })
    e.speed = 14
    e.T.api.GetUnitSpeed = function() return e.speed end
    e.T.api.random = function() return 2 end
    e.T:RideStart("flight", 100020, 1000)
    eq(e.fonts[6].text, "Dwarf speedometer 46 km/h, hold on to your beard, it gets windy!", "Tempo und Spruch")
    e.now = 1000.5; e.T:RideTick(e.now)
    e.speed = 20
    e.now = 1002; e.T:RideTick(e.now)
    eq(e.fonts[6].text, "Dwarf speedometer 66 km/h, hold on to your beard, it gets windy!", "gleicher Spruch im Flug")
    e.speed = 0
    e.now = 1004; e.T:RideTick(e.now)
    eq(e.fonts[6].text:find("66 km/h", 1, true) ~= nil, true, "ohne Tempo bleibt die Zeile")
    e.T:RideEnd()
    e.T:SetOpt("arrival", false)
    e.speed = 14
    e.T:RideStart("flight", 100020, 1000)
    eq(green(e), "", "ohne Countdown"); eq(e.fonts[6].text ~= "", true, "Tempo trotzdem")
    e.T:RideEnd()
    e.T:SetOpt("flightSpeed", false)
    e.T:RideStart("flight", 100020, 1000)
    eq(e.T:CurrentRide(), nil, "Option aus")
end)
