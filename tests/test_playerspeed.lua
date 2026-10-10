-- luacheck: ignore 111 113 122 143 432
-- Tempoanzeige am Spielerportrait (Modules/PlayerSpeed/*.lua)
local TravelSetup = require("travel_setup")

local function setup()
    local e = TravelSetup()
    local api = e.T.api
    e.speeds = { 7 } -- aktuell
    e.secret = false
    e.text, e.tickers = nil, 0
    api.GetUnitSpeed = function() return table.unpack(e.speeds) end
    e.combat = false
    api.InCombat = function() return e.combat end
    api.issecretvalue = function() return e.secret end
    api.GetPlayerFrame = function()
        return { CreateFontString = function()
            local fs = { text = "", shown = true }
            function fs:SetPoint() end
            function fs:SetJustifyH() end
            function fs:SetTextColor() end
            function fs:SetText(t) self.text = t end
            function fs:Show() self.shown = true end
            function fs:Hide() self.shown = false end
            e.text = fs
            return fs
        end }
    end
    api.NewTicker = function() e.tickers = e.tickers + 1; return { Cancel = function() e.tickers = e.tickers - 1 end } end
    return e
end

test("PlayerSpeed: aktuelles Tempo in yd/s, geheime Werte liefern nichts", function()
    local e = setup()
    eq(e.T:PlayerSpeed(), 7, "aktuell")
    e.secret = true; eq(e.T:PlayerSpeed(), nil, "geheim")
    e.secret = false
    e.T.api.GetUnitSpeed = function() error("geheim") end
    eq(e.T:PlayerSpeed(), nil, "Fehler abgefangen")
end)

test("PlayerSpeed: km/h oder mph, leer im Stand und im Kampf, Option schaltet ab", function()
    local e = setup()
    e.T:PlayerSpeedUpdate()
    eq(e.text.text, "23 km/h", "7 yd/s")
    e.speeds = { 14 }
    e.T:PlayerSpeedRefresh()
    eq(e.text.text, "46 km/h", "14 yd/s")
    e.speeds = { 0 }
    e.T:PlayerSpeedRefresh()
    eq(e.text.text, "", "Stand")
    e.speeds = { 14 }
    e.combat = true
    e.T:PlayerSpeedRefresh()
    eq(e.text.text, "", "Kampf")
    e.combat = false
    e.secret = true
    e.T:PlayerSpeedRefresh()
    eq(e.text.text, "", "geheim")
    e.secret = false
    e.Glimpse.GetDistanceUnit = function() return "yards" end
    e.T:PlayerSpeedRefresh()
    eq(e.text.text, "29 mph", "Yards: mph")
    e.T:SetOpt("playerSpeed", false)
    eq(e.text.text, "", "ausgeblendet"); eq(e.tickers, 0, "Takt gestoppt")
    e.T:SetOpt("playerSpeed", true)
    eq(e.text.text, "29 mph", "wieder da"); eq(e.tickers, 1, "ein Takt")
end)
