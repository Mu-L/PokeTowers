# Changelog

All notable changes to PokeTowers are documented here.

## [0.3.0] - 2026-02-08 — IV System & Playable Demo

### Added
- **Playable Demo Scene** (`cfc74d4`) — Route 1 map with 3 starter Pokémon (Charmander, Squirtle, Bulbasaur), ready to play from `scenes/demo/demo.tscn`
- **IV (Individual Values) System** (`f24eea2`) — Each caught Pokémon gets 5 random IV stats (HP, Attack, Defense, Speed, Special), star ratings (1-5★) based on IV totals, and visual star indicators in the UI
- **Demo documentation** — See [DEMO.md](DEMO.md) for quick-start instructions

### Fixed
- **Bug fix & polish pass** (`182aa19`) — Fixed critical enemy detection issues, save migration for new IV fields, evolution stat recalculation, and general stability improvements

## [0.2.0] - 2026-02-08 — Waves, Maps & Roadmap

### Added
- **Dynamic wave generation** (`4317534`) — Waves scale with difficulty and wave number; boss waves every 5th wave; epic final wave
- **Map editor tool** (`4f8a0bd`) — Path + zone editing with export support
- **Party select redesign** (`4f8a0bd`) — Overhauled party selection UI
- **Move system** (`4f8a0bd`) — 15 moves with physical/special categories, Pokémon damage formula with STAB
- **Spritesheet animations** (`14e0ed3`, `ecc8d46`, `6c5ab83`) — Animated idle sprites for ~10 Pokémon, static icon fallback for rest
- **Background scaling & game over popup** (`8bcd541`) — Map backgrounds scale properly, game over UI added
- **Project roadmap** (`019a9bb`, `30c07e6`) — Comprehensive development roadmap with 7 priority tiers

### Fixed
- Sprite path fixes after folder migration (`d742074`, `8d3264a`)

## [0.1.0] - 2026-02-07 — Foundation

### Added
- **Core tower defense loop** — Tower placement on zones, Path2D enemy pathing, wave spawning, lives & currency systems
- **200+ Pokémon species** defined as resources with stats, icons, and learnsets
- **9 type system** — Normal, Fire, Water, Grass, Electric, Ground, Rock, Flying, Bug with full effectiveness chart
- **Type-based attacks** — Electric=chain lightning, Fire=AOE projectile, Water=slow, Grass=poison DOT, Rock=splash, Ground=cone, Bug=multi-hit
- **Catching mechanic** — Auto-catch at <25% HP, ball types (Poké/Great/Ultra), catch rate formula
- **Evolution system** — Level-based evolution tracking
- **Save system** — 3 save slots via SaveManager autoload
- **Campaign structure** — 8 regions (Kanto→Galar), ~6 maps each, progression unlocking
- **Party system** — Select Pokémon before each map, party size upgrades with Zenny
- **Full UI flow** — Main Menu → Save Select → Starter Select → Campaign → Map Select → Party Select → Game
- **Projectile system** — Homing projectiles with fire (AOE) and water (slow) variants
- **Visual effects** — Damage numbers, lightning lines, per-type particles, flash on super effective
- **XP & leveling** — Towers gain XP from kills, level up with stat scaling
