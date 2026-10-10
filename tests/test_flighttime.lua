-- luacheck: ignore 111 113 122 143 432
-- Flugzeit an der Flugkarte (Modules/FlightTime/*.lua): Strecke aus der Flugkarte, gemessene und geschätzte Zeit, Tooltip.
local TravelSetup = require("travel_setup")

-- Flugkarte mit drei Knoten: Slot 1 = hier (nodeID 10), Slot 2 = 20, Slot 3 = 30 über 20
local function setup(times, routes)
    local e = TravelSetup()
    local counts = {}
    for route, entry in pairs(times or {}) do
        counts["flight:" .. route] = entry[1]
        counts["flighttime:" .. route] = entry[2]
    end
    e.scopes = {}
    local reader = {
        GetCount = function(_, kind, id, scope)
            e.scopes[#e.scopes + 1] = scope
            return counts[kind .. ":" .. id]
        end,
    }
    local api = e.T.api
    api.GetDatabase = function() return { Get = function(_, name) return name == "travel" and reader or nil end } end
    api.GetTaxiMapID = function() return 1415 end
    api.C_TaxiMap = { GetAllTaxiNodes = function()
        return { { slotIndex = 1, nodeID = 10, state = 0 }, { slotIndex = 2, nodeID = 20, state = 1 },
            { slotIndex = 3, nodeID = 30, state = 1 } }
    end }
    routes = routes or { [2] = { 2 }, [3] = { 2, 3 } }
    api.TaxiNumRoutes = function(slot) return #(routes[slot] or {}) end
    api.TaxiGetNodeSlot = function(slot, hop) return routes[slot][hop] end
    return e
end

local function texts(lines)
    local out = {}
    for _, line in ipairs(lines or {}) do out[#out + 1] = line[1] end
    return table.concat(out, " | ")
end

test("FlightTime: Dauer als m:ss oder h:mm:ss", function()
    local T = TravelSetup().T
    eq(T.FormatDuration(65), "1:05", "Minuten"); eq(T.FormatDuration(59.6), "1:00", "gerundet")
    eq(T.FormatDuration(3723), "1:02:03", "Stunden")
end)

test("FlightTime: gemessene Strecke zeigt den Durchschnitt über den Account", function()
    local e = setup({ [100020] = { 2, 130 } })
    eq(texts(e.T:FlightTimeLines(2)), "Flight time: 1:05 | Average of 2 flights", "Zeilen")
    local seconds, how, count = e.T:FlightTime({ 10, 20 })
    eq(seconds, 65, "Schnitt"); eq(how, "measured", "gemessen"); eq(count, 2, "Flüge")
    eq(e.scopes[1], "account", "Scope")
    e = setup({ [100020] = { 1, 60 } })
    eq(texts(e.T:FlightTimeLines(2)), "Flight time: 1:00 | Measured on one flight", "ein Flug")
end)

test("FlightTime: ohne direkte Messung aus Teilstrecken geschätzt, sonst nicht gemessen", function()
    local e = setup({ [100020] = { 1, 60 }, [200030] = { 2, 100 } })
    eq(table.concat(e.T:FlightPath(3), ","), "10,20,30", "Weg mit Zwischenhalt")
    local seconds, how, count = e.T:FlightTime(e.T:FlightPath(3))
    eq(seconds, 110, "60 + 50"); eq(how, "estimated", "geschätzt"); eq(count, 2, "Teilstrecken")
    eq(texts(e.T:FlightTimeLines(3)), "Flight time: about 1:50 | From 2 measured legs", "Zeilen")

    e = setup({ [100020] = { 1, 60 } })
    eq(e.T:FlightTime(e.T:FlightPath(3)), nil, "Teilstrecke fehlt")
    eq(texts(e.T:FlightTimeLines(3)), "Flight time: not measured yet", "noch nicht gemessen")
end)

test("FlightTime: nichts am eigenen Flugpunkt, ohne Database oder mit Option aus", function()
    local e = setup({ [100020] = { 1, 60 } })
    eq(e.T:FlightTimeLines(1), nil, "eigener Flugpunkt")
    e.T:SetOpt("flightTime", false)
    eq(e.T:FlightTimeLines(2), nil, "Option aus")
    e.T:SetOpt("flightTime", true)
    e.T.api.GetDatabase = function() return nil end
    eq(texts(e.T:FlightTimeLines(2)), "Flight time: not measured yet", "ohne Database: nicht gemessen")
    e.T.api.GetTaxiMapID = function() return nil end
    eq(e.T:FlightTimeLines(2), nil, "keine Flugkarte offen")
end)

test("FlightTime: ohne Routen-API direkt vom aktuellen Punkt zum Ziel", function()
    local e = setup({ [100030] = { 1, 200 } })
    e.T.api.TaxiNumRoutes = nil
    eq(table.concat(e.T:FlightPath(3), ","), "10,30", "nur Start und Ziel")
    eq(e.T:FlightTime(e.T:FlightPath(3)), 200, "gemessen")
end)

test("FlightTime: Tooltip bekommt die Zeilen und wird neu gezeigt", function()
    local e = setup({ [100020] = { 1, 60 } })
    local added, shown = {}, 0
    local tooltip = { AddLine = function(_, text) added[#added + 1] = text end, Show = function() shown = shown + 1 end }
    local hooks = {}
    e.T.api.GameTooltip = tooltip
    e.T.api.hooksecurefunc = function(name, func) hooks[name] = func end
    _G.TaxiNodeOnButtonEnter = function() end
    e.T.RegisterEvent = function() end
    e.T:FlightTimeEnable()
    hooks.TaxiNodeOnButtonEnter({ GetID = function() return 2 end })
    eq(#added, 2, "zwei Zeilen"); eq(shown, 1, "Show")
    _G.TaxiNodeOnButtonEnter = nil
end)
