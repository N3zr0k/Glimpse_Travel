# Glimpse: Travel – Funktionen

Stand 0.3.12-alpha.1. Benötigt Glimpse (Core) 0.3.21 oder neuer.

## Funktionen

| Funktion | Beschreibung | Option (Standard) |
| --- | --- | --- |
| Reittier per Doppelklick | Taste + Doppelklick in die Spielwelt (Standard Alt + rechts) ruft ein Reittier, Favoriten zuerst. Zweiter Doppelklick steigt ab. | Reittier automatisch (an) |
| Klassenfertigkeit | Ohne erlaubtes oder gelerntes Reittier: Reisegestalt, Geisterwolf, Aspekt des Geparden. Ein zweiter Doppelklick verlässt die Gestalt. | Klassenfertigkeit (an) |
| Im Wasser | Wassergestalt, sonst ein Schwimmtrank aus den Taschen. | Schwimmtrank (aus) |
| Tempo-Fähigkeit und Trank | Geht nichts anderes: Sprinten oder Spurt (mit Abklingzeit), sonst ein Tempotrank. | Tempo-Fähigkeit (an), Tempotrank (aus) |
| Taste des Doppelklicks | Modifikator und Maustaste wählbar, ausgeblendet, wenn alles aus ist. | – |
| Flugzeit im Tooltip | Auf der Flugkarte zeigt jeder Flugpunkt die Flugzeit, gemessen vom Core. Nie direkt geflogene Strecken werden aus Teilstrecken geschätzt. | Flugzeit (an) |
| Countdown bis zur Ankunft | Grüne Zeile oben mit der Restzeit in der Tiefenbahn (fest 58 s) und auf Flugrouten. | Countdown (an), Ton 5 s vorher (aus) |
| Hinweise in der Tiefenbahn | Weiße Hinweise 1 s nach Abfahrt, bei 25, 42 und 75 % der Fahrt und bei Ankunft. Titel vor dem Doppelpunkt fett. | Hinweise (an) |
| Warnungen in der Tiefenbahn | Bewegt man sich während der Fahrt, erscheint zufällig eine von sechs roten Sicherheitswarnungen, danach 20 s Pause. | Warnungen (an) |
| Tempo der Tiefenbahn | Eigene Zeile „Gnomentacho“ in km/h oder mph (Entfernungseinheit des Core) mit Spruch je Tempostufe, ab 138 km/h wechselnde Sprüche. | Tempo (an) |
| `/gli travel` | Einstellungen, Taste, Reittiere, Klassenfertigkeiten, laufende Fahrt, letzte Doppelklicks. | – |

## Datenbank

Travel schreibt nichts in die Datenbank. Alle Werte erfasst der Core, Travel liest sie nur.

| Namespace | Daten | Lesen | Schreiben |
| --- | --- | --- | --- |
| `travel` | `flight`, `flighttime` (Flüge und Flugzeit je Route, Scope `account`) | ja | nein |

Einstellungen liegen nicht in der Datenbank, sondern im Namespace `Glimpse_Travel` von `Glimpse.db` (Profil).

Außerdem liest Travel vom Core, ohne zu speichern: die Nachrichten `GLIMPSE_TRAVEL_RIDE_START`/`_END`, die laufende
Tiefenbahn-Fahrt (`Travel:GetTramRide()`) und die Entfernungseinheit (`Glimpse:GetDistanceUnit()`).
