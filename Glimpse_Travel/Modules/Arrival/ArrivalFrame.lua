local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local T = Glimpse:GetModule("TravelAddon")

-- Oben in der Bildschirmmitte, von oben nach unten: weißer Hinweis, roter Warnhinweis, grüner Countdown, Tempo.
-- Hinweise mit "Titel: Text" zeigen den Titel fett in einer eigenen Zeile. Sie verschwinden nach ihrer Zeit von selbst.

T.NOTE_SECONDS = 6
T.WARNING_SECONDS = 10

local WIDTH = 700
local frame, countdown, speed
local lines = {} -- note, warning: { head, body, untilTime, text }

local function Bold(fontString)
    if not (fontString.GetFont and fontString.SetFont) then return end
    local path, size = fontString:GetFont()
    if path then fontString:SetFont(path, size, "THICKOUTLINE") end
end

local function NewLine(anchor, r, g, b)
    local head = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    head:SetPoint("TOP", anchor, anchor == frame and "TOP" or "BOTTOM", 0, anchor == frame and 0 or -8)
    head:SetTextColor(r, g, b)
    Bold(head)
    local body = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    body:SetPoint("TOP", head, "BOTTOM", 0, -2)
    body:SetTextColor(r, g, b)
    if body.SetWidth then body:SetWidth(WIDTH) end
    if body.SetWordWrap then body:SetWordWrap(true) end
    return { head = head, body = body, untilTime = 0 }
end

local function Ensure()
    if frame or not T.api.CreateFrame then return frame end
    frame = T.api.CreateFrame("Frame", "GlimpseTravelArrival", UIParent)
    frame:SetSize(WIDTH + 100, 80)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -140)
    frame:SetFrameStrata("HIGH")
    lines.note = NewLine(frame, 1, 1, 1)
    lines.warning = NewLine(lines.note.body, 1, 0.2, 0.2)
    countdown = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    countdown:SetPoint("TOP", lines.warning.body, "BOTTOM", 0, -8)
    countdown:SetTextColor(0.1, 1, 0.1)
    speed = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    speed:SetPoint("TOP", countdown, "BOTTOM", 0, -6)
    return frame
end

local function Busy()
    return lines.note.untilTime > 0 or lines.warning.untilTime > 0 or countdown:GetText() ~= "" or speed:GetText() ~= ""
end

local function SetLine(line, text, untilTime)
    -- "Titel: Text" → Titel fett darüber
    local head, body = (text or ""):match("^([^:]+):%s+(.+)$")
    line.head:SetText(head or "")
    line.body:SetText(head and body or text or "")
    line.text, line.untilTime = text, untilTime
end

--- Grüne Zeile setzen; nil blendet sie aus
function T:ShowCountdown(text)
    if not Ensure() then return end
    countdown:SetText(text or "")
    frame:SetShown(Busy())
end

--- Tempozeile setzen; nil blendet sie aus
function T:ShowSpeed(text)
    if not Ensure() then return end
    speed:SetText(text or "")
    frame:SetShown(Busy())
end

--- Weißen Hinweis für ein paar Sekunden zeigen
function T:ShowNote(text, now)
    if not Ensure() then return end
    SetLine(lines.note, text, now + T.NOTE_SECONDS)
    frame:Show()
end

--- Roten Warnhinweis für ein paar Sekunden zeigen
function T:ShowWarning(text, now)
    if not Ensure() then return end
    SetLine(lines.warning, text, now + T.WARNING_SECONDS)
    frame:Show()
end

--- Abgelaufene Hinweise entfernen (im Takt der Fahrt)
function T:ExpireNote(now)
    if not frame then return end
    for _, line in pairs(lines) do
        if line.untilTime > 0 and now >= line.untilTime then SetLine(line, nil, 0) end
    end
    if not Busy() then frame:Hide() end
end

--- Angezeigter Text ("Titel: Text") des Hinweises ("note") oder der Warnung ("warning"), sonst ""
function T:ArrivalText(which)
    local line = lines[which]
    return line and line.text or ""
end

function T:HideArrival()
    if not frame then return end
    countdown:SetText("")
    speed:SetText("")
    for _, line in pairs(lines) do SetLine(line, nil, 0) end
    frame:Hide()
end
