local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local T = Glimpse:GetModule("TravelAddon")

-- Blaue Tempoanzeige am rechten Rand des Spielerportraits, auf Höhe des Namens. Läuft nur mit eingeschalteter Option;
-- im Kampf und im Stand ist sie ausgeblendet.

local INTERVAL = 0.5   -- Sekunden
local OFFSET_X, OFFSET_Y = -10, -6
local COLOR = { 0.3, 0.6, 1 }

local text, ticker

local function Ensure()
    if text then return text end
    local parent = T.api.GetPlayerFrame and T.api.GetPlayerFrame()
    if not (parent and parent.CreateFontString) then return nil end
    text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("TOPRIGHT", parent, "TOPRIGHT", OFFSET_X, OFFSET_Y)
    text:SetJustifyH("RIGHT")
    text:SetTextColor(COLOR[1], COLOR[2], COLOR[3])
    return text
end

--- Anzeige aktualisieren; im Kampf, im Stand oder ohne lesbares Tempo bleibt sie leer
function T:PlayerSpeedRefresh()
    if not Ensure() then return end
    local api = self.api
    local speed = not (api.InCombat and api.InCombat()) and self:PlayerSpeed()
    text:SetText(speed and speed > 0 and self:FormatSpeed(speed) or "")
end

--- Nach Optionsänderung: Anzeige und Takt an- oder abschalten
function T:PlayerSpeedUpdate()
    if self:Opt("playerSpeed") and self.api.NewTicker then
        if not ticker then ticker = self.api.NewTicker(INTERVAL, function() T:PlayerSpeedRefresh() end) end
        self:PlayerSpeedRefresh()
        return
    end
    if ticker then ticker:Cancel() end
    ticker = nil
    if text then text:SetText("") end
end

function T:PlayerSpeedEnable()
    self:PlayerSpeedUpdate()
end
