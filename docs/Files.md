# Glimpse: Travel – Dateien

Alle Dateien im Addon-Ordner `Glimpse_Travel/`, in Ladereihenfolge.

Travel schreibt nichts in Glimpse: Database. Strecke, Zonen, Flugpunkte und Flugzeiten erfasst das Core-Modul Reisen
(Namespace `travel`); Travel liest nur. Die Einstellungen liegen im Namespace `Glimpse_Travel` von
`Glimpse.db` (SavedVariables `GlimpseSettings`, Profil).

| Datei | Beschreibung | Database | Weitere Abhängigkeiten |
| --- | --- | --- | --- |
| `Glimpse_Travel.toc` | Metadaten, Mindestversion Core (`X-Glimpse-MinVersion` 0.3.21), lädt nur `Glimpse_Travel.xml` | – | Benötigt Glimpse; optional Glimpse_Database |
| `Media/Icon.tga` | Addon-Icon (64 x 64, unkomprimiertes 32-Bit-TGA), in der TOC als `IconTexture` für die Addon-Liste und die Glimpse-Optionen | – | – |
| `Glimpse_Travel.xml` | Lädt Locales, Core, Modules, Commands in dieser Reihenfolge | – | – |
| `Locales/Locales.xml` | Lädt die Sprachdateien, `enUS` zuerst | – | – |
| `Locales/enUS.lua` | Englische Texte (Standard) | – | AceLocale-3.0 |
| `Locales/deDE.lua` | Deutsche Texte | – | AceLocale-3.0 |
| `Core/Core.xml` | Lädt die Core-Dateien, `Travel.lua` zuerst | – | – |
| `Core/Travel.lua` | Legt das Modul `TravelAddon` an, Einstellungen (`Opt`/`SetOpt`), `api`-Tabelle, Hilfen für Zauber, Buffs und Klasse | Einstellungen: Namespace `Glimpse_Travel` in `Glimpse.db` | Glimpse (`NewModule`, `db`, `RegisterAddonOptions`), AceEvent-3.0, `C_MountJournal`, `IsPlayerSpell`, `IsUsableSpell`, `C_UnitAuras`, `GetItemCount` |
| `Core/Options.lua` | Optionsseite, Tab Allgemein: Aufsitzen, Klassenfertigkeit, Tempo-Fähigkeit, Tempotrank, Schwimmtrank, Taste (ausgeblendet, wenn alles aus ist), Flugzeit im Tooltip, Ankunft | Einstellungen: liest und schreibt `Glimpse_Travel` | `Glimpse:AddDoubleClickKeyOptions` mit `hidden` (ab Core 0.3.9) |
| `Modules/Modules.xml` | Lädt die Erweiterungen, je eine ein Ordner | – | – |
| `Modules/TravelAction/TravelAction.xml` | Lädt die Reise-Aktion, Helfer zuerst | – | – |
| `Modules/TravelAction/TravelActionMount.lua` | Nutzbare Reittiere aus dem Journal, Favoriten zuerst | – | `C_MountJournal` |
| `Modules/TravelAction/TravelActionClass.lua` | Klassenfertigkeiten je Klasse (Reisegestalt, Geisterwolf, Gepard, Wassergestalt, Sprinten, Spurt), aktive Reisegestalt | – | `GetShapeshiftForm`, `GetShapeshiftFormInfo` |
| `Modules/TravelAction/TravelActionWater.lua` | Im Wasser: Wassergestalt oder Schwimmtrank aus den Taschen | – | `GetItemCount` |
| `Modules/TravelAction/TravelActionBoost.lua` | Letzter Versuch: Tempo-Fähigkeit (Sprinten, Spurt) oder Tempotrank, Abklingzeit beachtet | – | `GetSpellCooldown`, `GetItemCooldown`, `GetItemCount` |
| `Modules/TravelAction/TravelAction.lua` | Entscheidet, was der Doppelklick tut; meldet den Handler `travel` an oder ab; Log | – | `Glimpse:RegisterDoubleClick`, `UnregisterDoubleClick`, `GetDoubleClickText` (Core 0.3.8) |
| `Modules/FlightTime/FlightTime.xml` | Lädt die Flugzeit, `FlightTime.lua` zuerst | – | – |
| `Modules/FlightTime/FlightTime.lua` | Flugzeit einer Strecke: Durchschnitt aus den Messungen, sonst Summe gemessener Teilstrecken; Format m:ss | liest: `travel` (`flight`, `flighttime`, Scope `account`) | `GlimpseDB:Get` |
| `Modules/FlightTime/FlightTimeTooltip.lua` | Zeilen im Tooltip eines Flugpunkts auf der Flugkarte (alte TaxiFrame-Knöpfe und neue FlightMap-Pins) | liest über `FlightTime.lua` | `C_TaxiMap`, `GetTaxiMapID`, `TaxiNumRoutes`, `TaxiGetNodeSlot`, `hooksecurefunc` auf `TaxiNodeOnButtonEnter` bzw. `FlightMap_FlightPointPinMixin`, `GameTooltip` |
| `Modules/Arrival/Arrival.xml` | Lädt die Ankunft: Anzeige, Punkte, Warnungen, Tempo, Steuerung | – | – |
| `Modules/Arrival/ArrivalFrame.lua` | Weißer Hinweis, rote Warnung, grüner Countdown und Tempo oben in der Bildschirmmitte, Titel vor dem Doppelpunkt fett | – | `CreateFrame` |
| `Modules/Arrival/ArrivalPoints.lua` | Hinweise der Tiefenbahn: 1 s nach Abfahrt, bei 25/42/75 % der Fahrzeit und bei Ankunft, je Fahrt einmal | – | – |
| `Modules/Arrival/ArrivalWarnings.lua` | Rote Zufallswarnung bei Bewegung während der Tiefenbahn-Fahrt, mit Pause | – | – |
| `Modules/Arrival/ArrivalSpeed.lua` | Tempo der Tiefenbahn in km/h oder mph (Entfernungseinheit des Core) als eigene Zeile, mit Spruch | – | `Travel:GetTramRide()` (Yards der laufenden Fahrt), `Glimpse:GetDistanceUnit()` |
| `Modules/Arrival/Arrival.lua` | Countdown für Tiefenbahn und Flugroute, Ton vor der Ankunft, Namen der Flugpunkte solange die Flugkarte offen ist | liest: `travel` (`flight`, `flighttime`, Scope `account`) | Nachrichten `GLIMPSE_TRAVEL_RIDE_START` (mit Fahrzeit)/`_END` vom Core, `C_Timer.NewTicker`/`After`, `PlaySound`, `C_Map.GetMapInfo`, Ereignis `PLAYER_STARTED_MOVING` |
| `Commands/Commands.xml` | Lädt die Befehle | – | – |
| `Commands/Travel.lua` | `/gli travel`: Einstellungen, Taste, Reittiere, Klassenfertigkeiten, laufende Fahrt mit Sekunden seit der Abfahrt, Log | – | `Glimpse:RegisterCommand` |
| `LICENSE` | MIT-Lizenz | – | – |
| `docs/icon.png` | Icon (512 x 512) für README und CurseForge | – | – |
