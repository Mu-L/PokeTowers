# PokeTowers

![Godot 4.5+](https://img.shields.io/badge/Godot-4.5%2B-blue?logo=godotengine&logoColor=white)
![GDScript](https://img.shields.io/badge/Language-GDScript-green)
![License](https://img.shields.io/badge/License-Educational-yellow)

A Pokémon-themed tower defense game built with Godot 4. Place Pokémon as towers, exploit type matchups, catch weakened enemies, and evolve your team across 8 regions.

## 🚀 Quick Start

**Want to play right now?** See **[DEMO.md](DEMO.md)** — open the demo scene and play Route 1 with 3 starters in under a minute.

## Features

- **200+ Pokémon** defined as tower/enemy species with full stats and learnsets
- **9-type system** with effectiveness chart — Electric=chain lightning, Fire=AOE, Water=slow, Grass=poison DOT, and more
- **IV System** — Each Pokémon has randomised Individual Values (HP, Attack, Defense, Speed, Special) with 1-5★ star ratings
- **Catching mechanic** — Weaken enemies below 25% HP to catch them with Poké/Great/Ultra Balls
- **Evolution** — Towers level up from kills and evolve at level thresholds
- **Dynamic waves** — Difficulty scales per wave with boss waves every 5th round
- **8 Regions** — Kanto through Galar, ~6 maps each, with campaign progression
- **Save system** — 3 save slots with starter selection
- **Playable demo** — Route 1 demo scene ready to go

## Play Locally

1. Install [Godot 4.5+](https://godotengine.org/download)
2. Clone this repo: `git clone https://github.com/LittleBennos/PokeTowers.git`
3. Open Godot → Import → Select `project.godot`
4. Press F5 or click Play

## Controls

- Click a Pokémon in the party panel to select
- Click a placement zone to deploy (costs currency)
- Right-click to cancel placement
- Start Wave button to begin each round

## Project Structure

```
resources/
  pokemon/       # Species data (stats, types, costs)
  maps/          # Map definitions
  campaigns/     # Region data

scenes/
  towers/        # Generic tower scene
  enemies/       # Enemy scenes
  demo/          # Playable demo scene
  ui/            # Menu screens

scripts/
  autoload/      # GameManager, SaveManager
  resources/     # Resource classes (PokemonData, IVData)
  towers/        # Tower logic (type-based attacks)
  enemies/       # Enemy logic
```

## Roadmap

See [ROADMAP.md](ROADMAP.md) for the full development roadmap. Phases 1-2 (core game + IV system) are complete. Next up: audio, tutorial, more types, multiplayer, and release prep.

See [CHANGELOG.md](CHANGELOG.md) for version history.

## Requirements

- Godot 4.5+

## License

For educational purposes only. Pokémon is a trademark of Nintendo/Game Freak.
