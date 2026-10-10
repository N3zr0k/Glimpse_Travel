# Glimpse: Travel – CurseForge-Texte

Zum Kopieren in die Projektseite auf CurseForge (Projekt-ID 1735124).

## Projektname

```
Glimpse: Travel
```

## Summary

```
Mount or travel form with one double click, flight times on the flight map, an arrival countdown and your speed.
```

## Kategorie

```
Miscellaneous
```

## Logo

`docs/icon.png` (512 x 512)

## Beschreibung

Alles unter dieser Zeile in den Beschreibungs-Editor (Markdown) kopieren.

---

# Glimpse: Travel

[![latest](https://img.shields.io/github/v/release/N3zr0k/Glimpse_Travel?include_prereleases&amp;sort=date&amp;label=latest)](https://github.com/N3zr0k/Glimpse_Travel/releases) [![last push](https://img.shields.io/github/last-commit/N3zr0k/Glimpse_Travel/main?label=last%20push)](https://github.com/N3zr0k/Glimpse_Travel/commits/main) [![CI](https://img.shields.io/github/actions/workflow/status/N3zr0k/Glimpse_Travel/ci.yml?branch=main&amp;label=CI)](https://github.com/N3zr0k/Glimpse_Travel/actions/workflows/ci.yml)

> ## ⚠ Requires the Glimpse core addon
> **Glimpse: Travel only works together with [Glimpse](https://www.curseforge.com/wow/addons/glimpse).** Install Glimpse first (version 0.3.21 or newer), otherwise this addon does not load.
> 👉 https://www.curseforge.com/wow/addons/glimpse

Comfort for travelling: **Glimpse: Travel** gets you moving with one double click, tells you how long a flight takes, counts down to your arrival and shows how fast you are.

## Travel with a double click

Hold a key (Alt by default) and double right-click the game world:

- **Mounted?** You dismount. **In a travel form?** You leave it.
- **On land:** a mount from your collection, favorites first.
- **No mount allowed or riding not learned yet:** Travel Form, Ghost Wolf or Aspect of the Cheetah.
- **In water:** Aquatic Form, or a Swim Speed Potion if you like.
- **Nothing else possible:** Sprint, Dash or a Swiftness Potion if you like.

Works out of combat only, because the game blocks it for all addons in combat.

## Flight map

Hover a flight point to see how long the flight takes, measured by Glimpse on your characters. Routes you never flew in one go are estimated from their legs.

## Arrival countdown

On flight routes and on the Deeprun Tram a green line counts down to your arrival, with an optional sound 5 seconds before.

The Deeprun Tram gets a little extra:

- notes along the way, from departure to arrival
- red safety notices from the tram management when you walk around in the car
- a gnome speedometer with a quip that fits the speed

## Your speed

- **Flights:** an extra line below the flight time shows your flight speed, with a quip: dwarves for the Alliance, wind riders for the Horde.
- **Player portrait:** a blue number at the right edge of your portrait, next to your name, shows how fast you are moving. It is hidden while standing still and in combat.
- The unit follows the distance unit in the Glimpse options: km/h or mph.

## Good to know

- Everything can be switched on or off in the options (Glimpse options, tab *Travel*).
- Travel stores nothing itself; the Glimpse core measures and Travel only reads.
- German and English.

## Commands

`/gli travel` shows your settings, mounts, class abilities, the current ride and your last double clicks.

## Links

- Core addon: [Glimpse on CurseForge](https://www.curseforge.com/wow/addons/glimpse) · [GitHub](https://github.com/N3zr0k/Glimpse)
- Source and issues: [GitHub](https://github.com/N3zr0k/Glimpse_Travel)
- MIT license
