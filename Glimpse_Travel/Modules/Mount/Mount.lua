local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local T = Glimpse:GetModule("TravelAddon")

-- Reittier aus dem Reittier-Journal: gesammelt, nutzbar, nicht für diesen Charakter ausgeblendet. Favoriten gehen vor,
-- daraus wird zufällig eins gewählt. Das Tempo eines Reittiers meldet der Client nicht, "bestes" heißt daher: Favorit.
-- isUsable ist false, solange Reiten nicht gelernt ist oder der Ort kein Reittier erlaubt.

--- Liste { id, name, spellID, favorite } der nutzbaren Reittiere
function T:MountCandidates()
    local journal = self.api.C_MountJournal
    local list = {}
    if not (journal and journal.GetMountIDs and journal.GetMountInfoByID) then return list end
    local ok, ids = pcall(journal.GetMountIDs)
    if not ok or type(ids) ~= "table" then return list end
    for _, id in ipairs(ids) do
        local got, name, spellID, _, _, usable, _, favorite, _, _, hidden, collected = pcall(journal.GetMountInfoByID, id)
        if got and name and spellID and usable and collected and not hidden then
            list[#list + 1] = { id = id, name = name, spellID = spellID, favorite = favorite and true or false }
        end
    end
    return list
end

--- name, spellID des gewählten Reittiers oder nil und Grund
function T:BestMount()
    local journal = self.api.C_MountJournal
    if not (journal and journal.GetMountIDs) then return nil, "no mount journal in this client" end
    local all = self:MountCandidates()
    if #all == 0 then return nil, "no usable mount" end
    local favorites = {}
    for _, mount in ipairs(all) do
        if mount.favorite then favorites[#favorites + 1] = mount end
    end
    local pool = #favorites > 0 and favorites or all
    local pick = pool[self.api.random(#pool)]
    return pick.name, pick.spellID
end

--- Aktion "Reittier rufen" oder nil; reason ist der bisherige Grund fürs Log
function T:MountAction(ctx, reason)
    if not self:Opt("mount") then return nil, reason end
    if not ctx.canMount then return nil, "no mount allowed here" end
    local name, spellID = self:BestMount()
    if name then return { type = "spell", spell = name }, "mount " .. spellID end
    return nil, spellID -- ohne Reittier steht hier der Grund
end
