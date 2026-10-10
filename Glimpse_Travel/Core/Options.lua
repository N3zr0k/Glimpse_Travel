local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local T = Glimpse:GetModule("TravelAddon")
local L = T.L

-- Tab "Allgemein": was der Doppelklick tun darf und seine Taste, dazu Flugzeit und Ankunft. Die Tastenauswahl kommt vom Core
-- (AddDoubleClickKeyOptions) und ist ausgeblendet, solange nichts eingeschaltet ist.

local function Toggle(name, order, label, desc)
    return {
        type = "toggle", order = order, width = "full", name = label, desc = desc,
        get = function() return T:Opt(name) == true end,
        set = function(_, value) T:SetOpt(name, value and true or false) end,
    }
end

local function BuildGeneral(self)
    local args = {
        actionHeader = { type = "header", order = 1, name = L["Travel with a double click"] },
        intro = {
            type = "description", order = 2, width = "full", fontSize = "medium",
            name = L["A double click on the game world with the key below mounts up or dismounts. If no mount is allowed or you cannot ride yet, your class ability for faster travel is used (Travel Form, Ghost Wolf, Aspect of the Cheetah). In water: Aquatic Form or a swim speed potion. If none of these is possible: a speed ability (Sprint, Dash) or a speed potion. Only out of combat."],
        },
        mount = Toggle("mount", 3, L["Mount up automatically"],
            L["The double click summons a mount: a favorite if you have one, otherwise any usable mount. A second double click dismounts."]),
        classSpeed = Toggle("classSpeed", 4, L["Use a class ability to travel faster"],
            L["Used when no mount is allowed here or you cannot ride yet, and in water for Aquatic Form. A second double click leaves the form."]),
        speedBoost = Toggle("speedBoost", 4.5, L["Use a speed ability (Sprint, Dash)"],
            L["Used when neither a mount nor a travel form is possible, also in water. Skipped while its cooldown runs. Dash only works in Cat Form."]),
        speedPotion = Toggle("speedPotion", 4.6, L["Drink a speed potion"],
            L["Swiftness Potion from your bags, when neither a mount, a travel form nor a speed ability is possible. Uses up one potion."]),
        swimPotion = Toggle("swimPotion", 5, L["Drink a swim speed potion in water"],
            L["Only when no Aquatic Form is available. Uses up one potion."]),
        flightHeader = { type = "header", order = 40, name = L["Flight map"] },
        flightTime = Toggle("flightTime", 41, L["Show the flight time in the tooltip"],
            L["Hover a flight point on the flight map to see how long the flight from here takes, measured by Glimpse on your characters. Routes you never flew in one go are estimated from their measured legs."]),
        arrivalHeader = { type = "header", order = 50, name = L["Arrival"] },
        arrival = Toggle("arrival", 51, L["Show a countdown to the arrival"],
            L["On the Deeprun Tram and on flight routes a green line at the top of the screen counts down to the arrival, from the travel and flight times Glimpse knows."]),
        arrivalSound = Toggle("arrivalSound", 52, L["Play a sound shortly before the arrival"],
            L["5 seconds before the arrival."]),
        tramNotes = Toggle("tramNotes", 53, L["Show notes during the Deeprun Tram ride"],
            L["During the ride, short notes appear in white: right after departure, at a quarter, half and three quarters of the way, and on arrival."]),
        tramWarnings = Toggle("tramWarnings", 54, L["Show a warning when you move during the Deeprun Tram ride"],
            L["A random safety notice from the tram management appears in red, at most every 20 seconds."]),
        tramSpeed = Toggle("tramSpeed", 55, L["Show the speed of the Deeprun Tram"],
            L["An extra line below the countdown shows how fast the tram is going, in km/h or mph, depending on the distance unit in the Glimpse options."]),
        keyText = {
            type = "description", order = 30, width = "full",
            name = function()
                local text = self:ActionKeyText()
                return text and format(L["Current key: %s"], text) or ""
            end,
            hidden = function() return not self:ActionWanted() end,
        },
    }
    if Glimpse.AddDoubleClickKeyOptions then
        -- über eine Weiterleitung, damit ein Profilwechsel greift
        local settings = setmetatable({}, {
            __index = function(_, key) return self:Opt(key) end,
            __newindex = function(_, key, value) self:SetOpt(key, value) end,
        })
        Glimpse:AddDoubleClickKeyOptions(args, settings, 20, { modifier = "modifier", button = "button",
            hidden = function() return not self:ActionWanted() end })
    end
    return args
end

--- Tabs der Optionsseite
function T:BuildOptions()
    return {
        general = { type = "group", order = 1, name = _G.GENERAL or L["General"], args = BuildGeneral(self) },
    }
end
