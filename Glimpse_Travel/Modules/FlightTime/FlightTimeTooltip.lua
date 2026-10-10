local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local T = Glimpse:GetModule("TravelAddon")
local L = T.L

-- Flugzeit im Tooltip eines Flugpunkts auf der Flugkarte. Zwei Kartenarten: die alte Flugkarte (TaxiFrame, Knöpfe mit
-- slotIndex als ID) und die neue (Blizzard_FlightMap, Pins mit taxiNodeData). Welche der Client hat, ist offen; beide
-- werden angehängt, wenn es sie gibt.

local api = T.api
local CURRENT = Enum and Enum.FlightPathState and Enum.FlightPathState.Current or 0

--- slotIndex -> nodeID und der aktuelle Knoten der offenen Flugkarte
local function Nodes()
    if not (api.C_TaxiMap and api.C_TaxiMap.GetAllTaxiNodes and api.GetTaxiMapID) then return nil end
    local mapID = api.GetTaxiMapID()
    if not mapID then return nil end
    local bySlot, current = {}, nil
    for _, node in ipairs(api.C_TaxiMap.GetAllTaxiNodes(mapID) or {}) do
        if node.slotIndex and node.nodeID then
            bySlot[node.slotIndex] = node.nodeID
            if node.state == CURRENT then current = node.nodeID end
        end
    end
    return bySlot, current
end

--- nodeIDs vom aktuellen Flugpunkt bis zum Flugpunkt in slot, mit Zwischenhalten soweit der Client sie nennt
function T:FlightPath(slot)
    local bySlot, current = Nodes()
    if not (bySlot and current and bySlot[slot]) or bySlot[slot] == current then return nil end
    local hops = api.TaxiNumRoutes and api.TaxiNumRoutes(slot) or 0
    if hops < 2 or not api.TaxiGetNodeSlot then return { current, bySlot[slot] } end
    local path = { current }
    for hop = 1, hops do
        local node = bySlot[api.TaxiGetNodeSlot(slot, hop, false)]
        if not node then return { current, bySlot[slot] } end
        path[#path + 1] = node
    end
    return path
end

--- Zeilen für den Tooltip: { text, r, g, b }
function T:FlightTimeLines(slot)
    if not self:Opt("flightTime") then return nil end
    local path = self:FlightPath(slot)
    if not path then return nil end
    local seconds, how, count = self:FlightTime(path)
    if not seconds then
        return { { format(L["Flight time: %s"], L["not measured yet"]), 0.6, 0.6, 0.6 } }
    end
    if how == "measured" then
        return {
            { format(L["Flight time: %s"], T.FormatDuration(seconds)), 1, 1, 1 },
            { count == 1 and L["Measured on one flight"] or format(L["Average of %d flights"], count), 0.6, 0.6, 0.6 },
        }
    end
    return {
        { format(L["Flight time: about %s"], T.FormatDuration(seconds)), 1, 1, 1 },
        { format(L["From %d measured legs"], count), 0.6, 0.6, 0.6 },
    }
end

local function AddLines(slot)
    local tooltip = api.GameTooltip
    if not (tooltip and slot) then return end
    local ok, lines = pcall(T.FlightTimeLines, T, slot)
    if not ok or not lines then return end
    for _, line in ipairs(lines) do tooltip:AddLine(line[1], line[2], line[3], line[4]) end
    tooltip:Show()
end

-- Neue Flugkarte: lädt erst mit Blizzard_FlightMap
local function HookFlightMap()
    local pin = _G.FlightMap_FlightPointPinMixin
    if T.flightMapHooked or not (pin and api.hooksecurefunc) then return end
    T.flightMapHooked = true
    api.hooksecurefunc(pin, "OnMouseEnter", function(self)
        AddLines(self.taxiNodeData and self.taxiNodeData.slotIndex)
    end)
end

function T:FlightTimeEnable()
    if not api.hooksecurefunc then return end
    if _G.TaxiNodeOnButtonEnter and not self.taxiHooked then
        self.taxiHooked = true
        api.hooksecurefunc("TaxiNodeOnButtonEnter", function(button) AddLines(button and button:GetID()) end)
    end
    HookFlightMap()
    if not self.flightMapHooked then
        self:RegisterEvent("ADDON_LOADED", function(_, name)
            if name == "Blizzard_FlightMap" then HookFlightMap() end
        end)
    end
end
