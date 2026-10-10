-- luacheck: ignore 111 113 122 143 432
-- Minimale Nachbildung der WoW-Umgebung, damit sich die reine Logik offline testen lässt.
-- Aufruf aus dem Hauptordner des Repos:  lua tests/run.lua
local stub = {}

local ROOT = ((arg and arg[0] or ""):match("^(.*)/[^/]*$") or ".") .. "/.."

function stub.reset()
    _G.unpack = _G.unpack or table.unpack
    _G.format = string.format
    _G.GENERAL = nil
    _G.strlower = string.lower
    _G.strtrim = function(text) return (text:gsub("^%s+", ""):gsub("%s+$", "")) end
    _G.wipe = function(t) for key in pairs(t) do t[key] = nil end return t end
end

-- Das Addon-Objekt (Glimpse) mit Modulen, Befehlen, Optionen und Doppelklick-Verteiler
function stub.newGlimpse()
    local Glimpse = { L = setmetatable({}, { __index = function(_, key) return key end }), modules = {}, commands = {}, printed = {} }
    function Glimpse:GetModule(name) return self.modules[name] end
    function Glimpse:NewModule(name)
        local module = { name = name, events = {}, messages = {} }
        function module:RegisterEvent(event, func) self.events[event] = func end
        function module:RegisterMessage(message, func) self.messages[message] = func end
        self.modules[name] = module
        return module
    end
    function Glimpse:RegisterCommand(name, desc, func) self.commands[name] = { desc = desc, func = func } end
    function Glimpse:Print(text) self.printed[#self.printed + 1] = text end
    function Glimpse:RegisterAddonOptions(_, options) self.options = options end
    -- AceDB: ein Namespace mit Profil
    Glimpse.db = { namespaces = {} }
    function Glimpse.db:RegisterNamespace(name)
        local ns = { profile = {} }
        self.namespaces[name] = ns
        return ns
    end
    -- Doppelklick-Verteiler: nur Anmeldung festhalten
    Glimpse.doubleClicks = {}
    function Glimpse:RegisterDoubleClick(name, handler) self.doubleClicks[name] = handler end
    function Glimpse:UnregisterDoubleClick(name) self.doubleClicks[name] = nil end
    function Glimpse:GetDoubleClickText(name)
        local handler = self.doubleClicks[name]
        return handler.modifier() .. " + " .. handler.button()
    end
    function Glimpse:AddDoubleClickKeyOptions(args, settings, _, opts)
        local function Option(field)
            return {
                get = function() return settings[field] end,
                set = function(_, value) settings[field] = value end,
                hidden = opts.hidden,
            }
        end
        args.doubleClickModifier = Option(opts.modifier)
        args.doubleClickButton = Option(opts.button)
    end

    _G.LibStub = function(name)
        if name == "AceLocale-3.0" then return { GetLocale = function() return Glimpse.L end } end
        return { GetAddon = function() return Glimpse end }
    end
    return Glimpse
end

-- Lädt eine Addon-Datei, ADDON_NAME wird wie vom Client als erstes Argument übergeben
function stub.load(path, addonName)
    local chunk, err = loadfile(ROOT .. "/Glimpse_Travel/" .. path) -- Pfade relativ zum Addon-Ordner
    assert(chunk, err)
    return chunk(addonName or "Glimpse_Travel")
end

return stub
