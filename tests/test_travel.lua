-- luacheck: ignore 111 113 122 143 432
local TravelSetup = require("travel_setup")

-- Reise-Aktion (Core/*.lua, Modules/TravelAction/*.lua): was ein Doppelklick in welcher Lage tut, An- und Abmelden
local function land(extra)
    local ctx = { mounted = false, swimming = false, outdoors = true, indoors = false, canMount = true }
    for key, value in pairs(extra or {}) do ctx[key] = value end
    return ctx
end

test("Travel: aufgesessen heißt absteigen, in einer Reisegestalt Gestalt aufheben", function()
    local e = TravelSetup()
    local action, reason = e.T:ChooseAction(land({ mounted = true, canMount = false }))
    eq(action.macrotext, "/dismount", "absteigen"); eq(reason, "dismount", "Grund")
    e.form, e.formSpell = 3, 783
    action = e.T:ChooseAction(land())
    eq(action.macrotext, "/cancelform", "Reisegestalt aufheben")
    e.formSpell = 768 -- Katzengestalt ist keine Reisegestalt
    e.mounts = { { name = "Pferd", spell = 100 } }
    action = e.T:ChooseAction(land())
    eq(action.spell, "Pferd", "aus anderer Gestalt aufs Reittier")
end)

test("Travel: Reittier, Favoriten zuerst, nur gesammelte, nutzbare und nicht ausgeblendete", function()
    local e = TravelSetup()
    e.mounts = {
        { name = "Wolf", spell = 101 },
        { name = "Favorit", spell = 102, favorite = true },
        { name = "Fremd", spell = 103, favorite = true, hidden = true },
        { name = "Fehlt", spell = 104, favorite = true, collected = false },
    }
    local action, reason = e.T:ChooseAction(land())
    eq(action.type, "spell", "Typ"); eq(action.spell, "Favorit", "Favorit gewinnt"); eq(reason, "mount 102", "Grund")
    e.mounts[2].favorite = false
    eq(e.T:ChooseAction(land()).spell, "Favorit", "ohne Favoriten aus allen (Zufall = letztes)")
end)

test("Travel: ohne Reittier oder wo keins erlaubt ist, kommt die Klassenfertigkeit", function()
    local e = TravelSetup()
    e.known[783] = true
    -- Reiten nicht gelernt: das Journal meldet das Reittier als nicht nutzbar
    e.mounts = { { name = "Pferd", spell = 100, usable = false } }
    local action, reason = e.T:ChooseAction(land())
    eq(action.spell, "Reisegestalt", "Reisegestalt ohne Reiten"); eq(reason, "travel ability 783", "Grund")
    -- drinnen: kein Reittier, Reisegestalt nur im Freien
    action, reason = e.T:ChooseAction(land({ canMount = false, outdoors = false, indoors = true }))
    eq(action, nil, "drinnen nichts"); eq(reason, "no mount allowed here, 783 only outdoors, travel ability not learned", "Grund")

    e.class, e.known = "SHAMAN", { [2645] = true }
    action = e.T:ChooseAction(land({ canMount = false, outdoors = false, indoors = true }))
    eq(action.spell, "Geisterwolf", "Geisterwolf auch drinnen")
    e.unusable[2645] = true
    eq(e.T:ChooseAction(land({ canMount = false })), nil, "nicht nutzbar (z. B. Mana)")

    e.class, e.known = "HUNTER", { [5118] = true }
    eq(e.T:ChooseAction(land({ canMount = false })).spell, "Aspekt des Geparden", "Gepard")
    e.auras[5118] = true
    eq(e.T:ChooseAction(land({ canMount = false })), nil, "Gepard schon aktiv")

    e.class = "WARRIOR"
    action, reason = e.T:ChooseAction(land({ canMount = false }))
    eq(action, nil, "Krieger hat nichts"); eq(reason, "no mount allowed here, no travel ability for this class, no travel ability for this class", "Grund")
end)

test("Travel: Reittier geht vor der Klassenfertigkeit, Optionen schalten beides", function()
    local e = TravelSetup()
    e.known[783] = true
    e.mounts = { { name = "Pferd", spell = 100 } }
    eq(e.T:ChooseAction(land()).spell, "Pferd", "Reittier zuerst")
    e.T:SetOpt("mount", false)
    eq(e.T:ChooseAction(land()).spell, "Reisegestalt", "ohne Aufsitzen die Reisegestalt")
    e.T:SetOpt("classSpeed", false)
    e.T:SetOpt("speedBoost", false)
    local action, reason = e.T:ChooseAction(land())
    eq(action, nil, "alles aus"); eq(reason, "mount switched off", "Grund")
end)

test("Travel: im Wasser Wassergestalt, sonst Schwimmtrank nur mit Option, nie die Landfertigkeit", function()
    local e = TravelSetup()
    local swim = land({ swimming = true, canMount = false })
    e.known = { [783] = true, [1066] = true }
    local action = e.T:ChooseAction(swim)
    eq(action.spell, "Wassergestalt", "Wassergestalt")

    e.class, e.known = "SHAMAN", { [2645] = true }
    eq(e.T:ChooseAction(swim), nil, "kein Geisterwolf im Wasser")
    e.items[6372] = 2
    eq(e.T:ChooseAction(swim), nil, "Trank nur mit Option")
    e.T:SetOpt("swimPotion", true)
    action = e.T:ChooseAction(swim)
    eq(action.type, "item", "Typ"); eq(action.item, "item:6372", "Schwimmtrank")
    e.auras[7840] = true
    local reason
    action, reason = e.T:ChooseAction(swim)
    eq(action, nil, "Trank wirkt schon"); eq(reason, "swim potion already active, no travel ability for this class", "Grund")
end)

test("Travel: Handler meldet sich ab, wenn alles aus ist, und Tastenfelder verschwinden", function()
    local e = TravelSetup()
    local G = e.Glimpse
    local handler = G.doubleClicks.travel
    eq(handler ~= nil, true, "angemeldet")
    eq(handler.modifier(), "ALT", "Standard Alt"); eq(handler.button(), "RightButton", "rechte Maustaste")

    local general = G.options.general.args
    eq(general.doubleClickModifier.hidden(), false, "Taste sichtbar")
    general.doubleClickModifier.set(nil, "CTRL")
    eq(handler.modifier(), "CTRL", "Taste aus den Optionen")

    e.T:SetOpt("mount", false)
    eq(G.doubleClicks.travel ~= nil, true, "Klassenfertigkeit allein hält ihn")
    e.T:SetOpt("classSpeed", false)
    eq(G.doubleClicks.travel ~= nil, true, "Tempo-Fähigkeit allein hält ihn")
    e.T:SetOpt("speedBoost", false)
    eq(G.doubleClicks.travel, nil, "abgemeldet")
    eq(general.doubleClickModifier.hidden(), true, "Taste ausgeblendet")
    eq(general.doubleClickButton.hidden(), true, "Maustaste ausgeblendet")
    eq(general.keyText.hidden(), true, "Tastentext ausgeblendet")
    e.T:SetOpt("swimPotion", true)
    eq(G.doubleClicks.travel ~= nil, true, "Schwimmtrank meldet wieder an")
end)

test("Travel: Prepare schreibt ins Log, /gli travel zeigt Lage und Log", function()
    local e = TravelSetup()
    e.mounts = { { name = "Pferd", spell = 100 } }
    local action = e.Glimpse.doubleClicks.travel.Prepare(land())
    eq(action.spell, "Pferd", "Aktion")
    eq(e.T.actionLog[1], "mount 100", "Log")
    e.Glimpse.commands.travel.func()
    local printed = table.concat(e.Glimpse.printed, "\n")
    eq(printed:find("usable mounts: 1", 1, true) ~= nil, true, "Reittiere gezählt")
    eq(printed:find("log 1: mount 100", 1, true) ~= nil, true, "Log gezeigt")
    eq(printed:find("key: ALT + RightButton", 1, true) ~= nil, true, "Taste gezeigt")
end)

test("Travel: ohne Reittier-Journal bleibt es bei der Klassenfertigkeit", function()
    local e = TravelSetup()
    e.T.api.C_MountJournal = nil
    e.known[783] = true
    local action, reason = e.T:ChooseAction(land())
    eq(action.spell, "Reisegestalt", "Reisegestalt"); eq(reason, "travel ability 783", "Grund")
    e.T:SetOpt("classSpeed", false)
    _, reason = e.T:ChooseAction(land())
    eq(reason, "no mount journal in this client, travel ability not learned", "Grund ohne Journal")
end)

test("Travel: Tempo-Fähigkeit und Tempotrank, wenn sonst nichts geht, eigene Optionen", function()
    local e = TravelSetup()
    e.class, e.known = "ROGUE", { [8696] = true } -- nur Rang 2 gelernt
    local action, reason = e.T:ChooseAction(land({ canMount = false }))
    eq(action.spell, "Sprinten", "Sprinten"); eq(reason, "speed ability 2983", "Grund")
    eq(e.T:ChooseAction(land({ swimming = true, canMount = false })).spell, "Sprinten", "auch im Wasser")
    e.cooldowns[8696] = true
    action, reason = e.T:ChooseAction(land({ canMount = false }))
    eq(action, nil, "Abklingzeit läuft")
    eq(reason, "no mount allowed here, no travel ability for this class, 2983 on cooldown", "Grund")

    e.items[2459] = 1
    eq(e.T:ChooseAction(land({ canMount = false })), nil, "Trank nur mit Option")
    e.T:SetOpt("speedPotion", true)
    action = e.T:ChooseAction(land({ canMount = false }))
    eq(action.item, "item:2459", "Beweglichkeitstrank")
    e.itemCooldowns[2459] = true
    _, reason = e.T:ChooseAction(land({ canMount = false }))
    eq(reason:find("speed potion on cooldown", 1, true) ~= nil, true, "Trank-Abklingzeit")
    e.itemCooldowns[2459], e.auras[2379] = nil, true
    _, reason = e.T:ChooseAction(land({ canMount = false }))
    eq(reason:find("speed potion already active", 1, true) ~= nil, true, "Trank wirkt schon")

    e.T:SetOpt("speedBoost", false)
    e.T:SetOpt("speedPotion", false)
    eq(e.T:ChooseAction(land({ canMount = false })), nil, "beide Optionen aus")
end)

test("Travel: Reisegestalt geht vor Spurt, Spurt nur wenn nutzbar (Katzengestalt)", function()
    local e = TravelSetup()
    e.known = { [783] = true, [1850] = true }
    eq(e.T:ChooseAction(land({ canMount = false })).spell, "Reisegestalt", "draußen Reisegestalt")
    e.unusable[1850] = true
    eq(e.T:ChooseAction(land({ canMount = false, outdoors = false })), nil, "drinnen ohne Katzengestalt nichts")
    e.unusable[1850] = nil
    eq(e.T:ChooseAction(land({ canMount = false, outdoors = false })).spell, "Spurt", "drinnen in Katzengestalt Spurt")
end)
