local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local T = Glimpse:GetModule("TravelAddon")
local L = T.L

-- Reise-Aktion über den Doppelklick-Verteiler des Cores (Standard Alt + Doppelklick rechts). Ein Doppelklick:
--   aufgesessen               absteigen
--   in einer Reisegestalt     Gestalt aufheben
--   im Wasser                 Wassergestalt oder Schwimmtrank (Modules/Water)
--   an Land                   Reittier, wenn eins erlaubt und gelernt ist; sonst die Klassenfertigkeit
--   sonst                     Tempo-Fähigkeit oder Tempotrank, auch im Wasser (Modules/SpeedBoost)
-- Erkennung, Secure-Button und Kampfsperre liegen im Core. Sind alle Schalter (Reittier, Klassenfertigkeit, Tempo-Fähigkeit,
-- Tempotrank, Schwimmtrank) aus, meldet sich der Handler ab und verschwindet damit auch aus dem Block "Doppelklick" im Core.

local KEY = "travel"
local LOG_SIZE = 10

T.actionLog = {}

function T:ActionLog(text)
    local log = self.actionLog
    log[#log + 1] = text
    if #log > LOG_SIZE then table.remove(log, 1) end
end

--- Ist überhaupt etwas eingeschaltet, das der Doppelklick tun kann?
function T:ActionWanted()
    return self:Opt("mount") or self:Opt("classSpeed") or self:Opt("speedBoost") or self:Opt("speedPotion")
        or self:Opt("swimPotion") or false
end

--- Aktion für die Lage ctx (aus dem Core) oder nil, dazu ein Grund fürs Log
function T:ChooseAction(ctx)
    if ctx.mounted then return { type = "macro", macrotext = "/dismount" }, "dismount" end
    local form = self:ActiveTravelForm()
    if form then return { type = "macro", macrotext = "/cancelform" }, "leave form " .. form end
    if ctx.swimming then
        local action, reason = self:WaterAction(ctx)
        if action then return action, reason end
        return self:BoostAction(ctx, reason)
    end

    local reason = "mount switched off"
    local action
    action, reason = self:MountAction(ctx, reason)
    if action then return action, reason end
    action, reason = self:ClassAction(ctx, reason)
    if action then return action, reason end
    return self:BoostAction(ctx, reason)
end

local handler = {
    title = L["Travel: mount and travel form"],
    modifier = function() return T:Opt("modifier") end,
    button = function() return T:Opt("button") end,
    priority = 5,
    Prepare = function(ctx)
        local action, reason = T:ChooseAction(ctx)
        T:ActionLog(reason or "?")
        return action
    end,
}

--- An- oder abmelden, je nach Einstellungen
function T:ActionUpdate()
    if not Glimpse.RegisterDoubleClick then return end
    local wanted = self:ActionWanted()
    if wanted and not self.actionRegistered then
        Glimpse:RegisterDoubleClick(KEY, handler)
        self.actionRegistered = true
    elseif not wanted and self.actionRegistered then
        Glimpse:UnregisterDoubleClick(KEY)
        self.actionRegistered = nil
    end
end

function T:ActionStop()
    if self.actionRegistered and Glimpse.UnregisterDoubleClick then Glimpse:UnregisterDoubleClick(KEY) end
    self.actionRegistered = nil
end

--- "Alt + Doppelklick rechts" oder nil, wenn nicht angemeldet
function T:ActionKeyText()
    if not self.actionRegistered or not Glimpse.GetDoubleClickText then return nil end
    return Glimpse:GetDoubleClickText(KEY)
end
