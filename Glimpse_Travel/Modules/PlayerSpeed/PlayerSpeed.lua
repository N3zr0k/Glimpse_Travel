local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local T = Glimpse:GetModule("TravelAddon")

-- Aktuelles Tempo des Spielers in yd/s (Stand 0, auch auf Flugrouten). nil, wenn der Client den Wert
-- als geheim liefert (Kampf) oder nicht lesbar ist.
function T:PlayerSpeed()
    local api = self.api
    if not api.GetUnitSpeed then return nil end
    local ok, speed = pcall(function()
        local current = api.GetUnitSpeed("player")
        if api.issecretvalue and api.issecretvalue(current) then return nil end
        return current and current + 0
    end)
    if ok and type(speed) == "number" then return speed end
    return nil
end
