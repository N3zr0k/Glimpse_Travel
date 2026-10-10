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
| `Core/Core.xml` | Lädt die Core-Dateien, `Travel.lua` zuerst, dann Zauber, Tempo, Doppelklick, Ankunft, Optionen | – | – |
| `Core/Travel.lua` | Legt das Modul `TravelAddon` an, Einstellungen (`Opt`/`SetOpt`), `api`-Tabelle, Hilfen für Zauber, Buffs und Klasse | Einstellungen: Namespace `Glimpse_Travel` in `Glimpse.db` | Glimpse (`NewModule`, `db`, `RegisterAddonOptions`), AceEvent-3.0, `C_MountJournal`, `IsPlayerSpell`, `IsUsableSpell`, `C_UnitAuras`, `GetItemCount` |
| `Core/Spells.lua` | Gemeinsam für alle Reisearten: Zaubername, bekannt, nutzbar, Abklingzeit, Buff, Klasse, passende Klassenfertigkeit (`ClassSpell`), Reisegestalten (`RegisterForm`, `ActiveTravelForm`) | – | `GetShapeshiftForm`, `GetShapeshiftFormInfo` |
| `Core/Speed.lua` | Einheit und Umrechnung des Tempos (km/h oder mph nach Entfernungseinheit des Core), für Tiefenbahn, Flüge und Portrait | – | `Glimpse:GetDistanceUnit()` |
| `Core/Action.lua` | Doppelklick: entscheidet, was er tut (absteigen, Gestalt aufheben, Wasser, Reittier, Klassenfertigkeit, Tempo); meldet den Handler `travel` an oder ab; Log | – | `Glimpse:RegisterDoubleClick`, `UnregisterDoubleClick`, `GetDoubleClickText` (Core 0.3.8) |
| `Core/Arrival/Arrival.xml` | Lädt die Ankunft: Anzeige, dann Steuerung | – | – |
| `Core/Arrival/ArrivalFrame.lua` | Weißer Hinweis, rote Warnung, grüner Countdown und Tempo oben in der Bildschirmmitte, Titel vor dem Doppelpunkt fett | – | `CreateFrame` |
| `Core/Arrival/Arrival.lua` | Gemeinsam für alle Fahrten: Countdown, Ton vor der Ankunft, Anmeldung der Fahrtarten (`T:RegisterRide`), wartet ein zu frühes Ende ab | – | Nachrichten `GLIMPSE_TRAVEL_RIDE_START` (mit Fahrzeit) und `GLIMPSE_TRAVEL_RIDE_END`, Ereignis `PLAYER_STARTED_MOVING` |
| `Core/Options.lua` | Optionsseite, Tab Allgemein: Aufsitzen, Klassenfertigkeit, Tempo-Fähigkeit, Tempotrank, Schwimmtrank, Taste (ausgeblendet, wenn alles aus ist), Flugzeit im Tooltip, Ankunft | Einstellungen: liest und schreibt `Glimpse_Travel` | `Glimpse:AddDoubleClickKeyOptions` mit `hidden` (ab Core 0.3.9) |
| `Modules/Modules.xml` | Lädt die Reisearten, je eine ein Ordner | – | – |
| `Modules/Mount/Mount.xml` | Lädt die Reittier-Auswahl | – | – |
| `Modules/Mount/Mount.lua` | Nutzbare Reittiere aus dem Journal, Favoriten zuerst; Aktion „Reittier rufen“ | – | `C_MountJournal` |
| `Modules/ClassTravel/ClassTravel.xml` | Lädt die Klassenfertigkeiten für Land | – | – |
| `Modules/ClassTravel/ClassTravel.lua` | Reisegestalt, Geisterwolf, Aspekt des Geparden; Aktion „Klassenfertigkeit“ | – | `GetShapeshiftForm`, `GetShapeshiftFormInfo` |
| `Modules/Water/Water.xml` | Lädt die Wasser-Aktion | – | – |
| `Modules/Water/Water.lua` | Im Wasser: Wassergestalt oder Schwimmtrank aus den Taschen | – | `GetItemCount` |
| `Modules/SpeedBoost/SpeedBoost.xml` | Lädt die Tempo-Fähigkeiten | – | – |
| `Modules/SpeedBoost/SpeedBoost.lua` | Letzter Versuch: Tempo-Fähigkeit (Sprinten, Spurt) oder Tempotrank, Abklingzeit beachtet | – | `GetSpellCooldown`, `GetItemCooldown`, `GetItemCount` |
| `Modules/FlightTime/FlightTime.xml` | Lädt die Flugzeit, `FlightTime.lua` zuerst | – | – |
| `Modules/FlightTime/FlightTime.lua` | Flugzeit einer Strecke: Durchschnitt aus den Messungen, sonst Summe gemessener Teilstrecken; Format m:ss | liest: `travel` (`flight`, `flighttime`, Scope `account`) | `GlimpseDB:Get` |
| `Modules/FlightTime/FlightTimeTooltip.lua` | Zeilen im Tooltip eines Flugpunkts auf der Flugkarte (alte TaxiFrame-Knöpfe und neue FlightMap-Pins) | liest über `FlightTime.lua` | `C_TaxiMap`, `GetTaxiMapID`, `TaxiNumRoutes`, `TaxiGetNodeSlot`, `hooksecurefunc` auf `TaxiNodeOnButtonEnter` bzw. `FlightMap_FlightPointPinMixin`, `GameTooltip` |
| `Modules/DeeprunTram/DeeprunTram.xml` | Lädt die Tiefenbahn: Hinweise, Warnungen, Tempo, Anmeldung | – | – |
| `Modules/DeeprunTram/DeeprunTramPoints.lua` | Hinweise der Tiefenbahn: 1 s nach Abfahrt, bei 25/42/75 % der Fahrzeit und bei Ankunft, je Fahrt einmal | – | – |
| `Modules/DeeprunTram/DeeprunTramWarnings.lua` | Rote Zufallswarnung bei Bewegung während der Tiefenbahn-Fahrt, mit Pause | – | – |
| `Modules/DeeprunTram/DeeprunTramSpeed.lua` | Tempo der Tiefenbahn als eigene Zeile „Gnomentacho“, Spruch je Tempostufe | – | `Travel:GetTramRide()` (Yards der laufenden Fahrt), `Glimpse:GetDistanceUnit()` |
| `Modules/DeeprunTram/DeeprunTram.lua` | Tiefenbahn als Fahrtart: Stationsnamen, feste Fahrzeit 58 s, Start, Takt, Bewegung, Ankunft | – | `C_Map.GetMapInfo` |
| `Modules/FlightRide/FlightRide.xml` | Lädt den Flug: Tempo, Anmeldung | – | – |
| `Modules/FlightRide/FlightRideSpeed.lua` | Tempo auf Flügen als eigene Zeile mit Spruch (Allianz Zwerge, Horde Windreiter), einer pro Flug | – | `Glimpse:GetDistanceUnit()` |
| `Modules/FlightRide/FlightRide.lua` | Flugroute als Fahrtart: Zielname (Namen der Flugpunkte, solange die Flugkarte offen ist) und erwartete Zeit | liest über `FlightTime.lua`: `travel` (`flight`, `flighttime`) | `C_TaxiMap`, `GetTaxiMapID`, Ereignis `TAXIMAP_OPENED` |
| `Modules/PlayerSpeed/PlayerSpeed.xml` | Lädt die Tempoanzeige | – | – |
| `Modules/PlayerSpeed/PlayerSpeed.lua` | Aktuelles Tempo des Spielers in yd/s, geheime Werte im Kampf ergeben nichts | – | `GetUnitSpeed` |
| `Modules/PlayerSpeed/PlayerSpeedFrame.lua` | Blaue Tempozahl am rechten Rand des Spielerportraits, alle 0,5 s, km/h oder mph je nach Entfernungseinheit des Core; im Stand und im Kampf leer | – | `PlayerFrame`, `UnitAffectingCombat`, `C_Timer.NewTicker`, `Glimpse:GetDistanceUnit()` |
| `Commands/Commands.xml` | Lädt die Befehle | – | – |
| `Commands/Travel.lua` | `/gli travel`: Einstellungen, Taste, Reittiere, Klassenfertigkeiten, laufende Fahrt mit Sekunden seit der Abfahrt, Log | – | `Glimpse:RegisterCommand` |
| `LICENSE` | MIT-Lizenz | – | – |
| `docs/icon.png` | Icon (512 x 512) für README und CurseForge | – | – |
