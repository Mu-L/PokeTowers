# PokeTowers Enhancement Roadmap

*Generated: 2026-02-08 | Last reviewed: 2026-02-08*

---

## ✅ Phase 1: Core Foundation — COMPLETE

- [x] Core TD loop: tower placement, Path2D enemies, wave spawning, lives/currency
- [x] 9-type system with effectiveness chart (Normal, Fire, Water, Grass, Electric, Ground, Rock, Flying, Bug)
- [x] Type-based attacks (chain lightning, AOE, slow, poison DOT, splash, cone, multi-hit)
- [x] 200+ Pokémon species as resources with stats, icons, learnsets
- [x] Move system: 15 moves, physical/special categories, STAB
- [x] Catching mechanic: auto-catch at <25% HP, ball types, catch rate formula
- [x] Evolution: level-based tracking
- [x] Save system: 3 slots via SaveManager autoload
- [x] Campaign: 8 regions (Kanto→Galar), ~6 maps each, progression unlocking
- [x] Party system with Zenny-based size upgrades
- [x] Full UI flow: Main Menu → Save → Starter → Campaign → Map → Party → Game
- [x] Map editor tool with path + zone export
- [x] Projectile system (homing, AOE fire, slow water)
- [x] Visual effects: damage numbers, lightning, per-type particles, super effective flash
- [x] XP/leveling with stat scaling
- [x] Dynamic wave generation with boss waves every 5th

## ✅ Phase 2: IV System & Demo — COMPLETE

- [x] Individual Values (IVs): 5 stats (HP, Attack, Defense, Speed, Special)
- [x] Star ratings (1-5★) based on IV totals
- [x] Visual star indicators in UI
- [x] Bug fix & polish pass (enemy detection, save migration, evolution stats)
- [x] Playable demo scene (Route 1, 3 starters)

---

## 🔲 Phase 3: Game Feel & Audio (Next Up)

- [ ] Sound effects & music (AudioManager autoload, per-type attack SFX, BGM)
- [ ] Game speed controls (1×/2×/3× via `Engine.time_scale`)
- [ ] Tower sell button (70% refund)
- [ ] Evolution visual swap (sprite + effects)
- [ ] Screen shake & hit juice
- [ ] Victory rewards screen (Zenny, catches, star rating)

## 🔲 Phase 4: Tutorial & Onboarding

- [ ] Tutorial system for first map (Pallet Town guided walkthrough)
- [ ] Type effectiveness tutorial hints
- [ ] Contextual tooltips for new players
- [ ] Skip tutorial on replay (`SaveManager.has_completed_tutorial`)

## 🔲 Phase 5: Content Expansion

- [ ] Remaining 9 Pokémon types (Ice, Psychic, Fighting, Ghost, Dark, Poison, Steel, Fairy, Dragon)
- [ ] Tower specializations (branching evolution paths)
- [ ] More maps per region
- [ ] Legendary Pokémon as boss-wave catches
- [ ] Endless mode (infinite scaling after final wave)
- [ ] Pokédex viewer screen

## 🔲 Phase 6: Difficulty & Balance

- [ ] Difficulty settings (Easy / Normal / Hard per map)
- [ ] Difficulty curve tuning (S-curve scaling, rubber-banding)
- [ ] Wave preview (show enemy types before each wave)
- [ ] Economy balancing (`economy_config.tres` resource)
- [ ] Star rating system (★/★★/★★★ per map based on lives remaining)

## 🔲 Phase 7: Multiplayer & Social

- [ ] Co-op multiplayer (shared map, split party)
- [ ] Pokémon trading between players
- [ ] Leaderboards (endless mode high scores)
- [ ] Achievement system with rewards

## 🔲 Phase 8: Mobile & Release Prep

- [ ] Touch input (drag-to-place, tap-to-select)
- [ ] Responsive UI scaling for mobile aspect ratios
- [ ] Object pooling (projectiles, enemies, particles)
- [ ] Fix stretch/aspect settings in project.godot
- [ ] Configure physics collision layers
- [ ] Android/iOS export templates
- [ ] Performance profiling (60 FPS target on mid-range mobile)
- [ ] Settings screen (volume, shake toggle, damage numbers toggle)

## 🔲 Phase 9: Distribution

- [ ] Steam store page & build pipeline
- [ ] itch.io page with web export
- [ ] Trailer / gameplay GIF
- [ ] Press kit

---

## Detailed Technical Notes

*(Preserved from previous roadmap revision for reference.)*

## Priority 0: Project Configuration Fixes 🔧

*These are wrong/missing right now and will cause pain if not fixed first.*

### 0.1 Fix Stretch Settings in project.godot
Current `stretch/mode="canvas_items"` is correct, but `stretch/aspect` is unset (defaults to `ignore` = distortion).
- **Action**: Set `window/stretch/aspect="keep_height"` in project.godot — this letterboxes on wider screens and expands vertically on taller (portrait) screens. Best for mobile TD where vertical space matters more.
- For portrait mode support later, switch to `"keep_width"`.

### 0.2 Configure Physics Layers
Everything is on layer 1. This means every physics body checks against every other — O(n²) waste.
- **Action**: Define collision layers in Project Settings → Layer Names → 2D Physics:
  - Layer 1: `towers`
  - Layer 2: `enemies`
  - Layer 3: `projectiles`
  - Layer 4: `ui_raycast`
  - Layer 5: `placement_zones`
- Set each node's `collision_layer` and `collision_mask` appropriately. Towers only need to detect enemies (mask=2). Projectiles only need enemies (mask=2). Enemies need nothing (they follow Path2D, no physics needed — consider removing their collision bodies entirely and using `Area2D` overlap checks only).

### 0.3 Add Android Export Preset
- **Action**: In Godot Editor → Project → Export → Add Android preset
- Set minimum SDK 24 (Android 7.0), target SDK 34
- Enable `Touch` input in export settings
- Set screen orientation to `landscape` (or `sensor_landscape` for auto-rotate)
- Add `INTERNET` permission if adding leaderboards later
- Generate debug keystore: `keytool -genkey -v -keystore debug.keystore -alias debug -keyalg RSA -validity 10000`

### 0.4 Add Input Map Actions for Touch
Current input map only has `click` (mouse button). Touch events auto-map to left-click in Godot 4, BUT:
- **Action**: Add `"touch"` action mapped to `InputEventScreenTouch` for explicit touch handling
- Add `"drag"` action mapped to `InputEventScreenDrag`
- In Project Settings: set `Input Devices > Pointing > Emulate Mouse From Touch = true` (should be default, verify)
- Set `Emulate Touch From Mouse = true` for desktop testing

---

## Priority 1: Quick Wins 🏃

*Low effort, high impact. 1-2 sessions each.*

### 1.1 Game Speed Controls
- **Action**: Add HUD buttons for 1×/2×/3× speed. Set `Engine.time_scale` on press.
- Use `Button` nodes with icons (▶, ▶▶, ▶▶▶), minimum size 48×48px for touch.
- Add pause button that sets `get_tree().paused = true` — ensure towers/enemies are in `pause_mode = PROCESS_MODE_PAUSABLE` group and UI is `PROCESS_MODE_ALWAYS`.
- **Gotcha**: `Engine.time_scale` affects physics AND audio pitch. For audio, compensate with `AudioServer.playback_speed_scale = 1.0 / Engine.time_scale` to keep music at normal pitch, or accept the chipmunk effect as a feature.

### 1.2 Tower Sell Button
- **Action**: On tower tap/select, show a `PanelContainer` popup anchored to tower position with Sell button.
- Refund formula: `floor(original_cost * 0.7)` — 70% is the TD genre standard (50% feels punishing, 100% removes commitment).
- Free the `PlacementZone` by calling its `clear()` method and resetting `is_occupied`.
- Include tower's earned XP in a "bank" so the Pokemon retains progress if re-placed.

### 1.3 Evolution Visual Swap
- **Action**: In `check_evolution()`, after `pokemon_evolved` signal:
  1. Store current `animated_sprite` frame and modulate
  2. Load new species resource → update `sprite_frames` or swap `SpriteFrames` resource
  3. Play a 0.5s white flash (`modulate = Color.WHITE` tween → normal) + scale bounce tween (1.0 → 1.3 → 1.0 over 0.4s)
  4. Spawn `GPUParticles2D` evolution sparkle (see §5.5 for particle specs)
  5. Update tower stats from new species data
  6. Play evolution jingle (when audio exists)

### 1.4 Wave Complete Auto-Enable
- **Action**: Connect `wave_completed` signal to HUD's `_on_wave_completed()`. In handler: `start_wave_button.disabled = false`, show wave clear banner (tween alpha 0→1→hold 1s→0).

### 1.5 Clean Up Legacy HUD
- **Action**: Delete the hardcoded `tower_data` dictionary from `hud.gd`. If it's referenced anywhere, grep for it: `grep -r "tower_data" scripts/`. Replace any remaining references with `GameManager.current_party` lookups.

### 1.6 Object Pool System *(NEW — critical for mobile)*
- **Action**: Create `scripts/autoload/object_pool.gd` as a new autoload.
- Pool pattern:
  ```gdscript
  var _pools: Dictionary = {}  # {scene_path: Array[Node]}
  
  func get_instance(scene: PackedScene) -> Node:
      var path = scene.resource_path
      if _pools.has(path) and _pools[path].size() > 0:
          var inst = _pools[path].pop_back()
          inst.visible = true
          inst.set_process(true)
          return inst
      return scene.instantiate()
  
  func return_instance(node: Node, scene: PackedScene) -> void:
      node.visible = false
      node.set_process(false)
      node.set_physics_process(false)
      if node.get_parent():
          node.get_parent().remove_child(node)
      _pools[scene.resource_path].append(node)
  ```
- Use for: **projectiles** (highest churn), **damage numbers**, **enemy instances** (pre-warm 20 per wave).
- Pre-warm pools at wave start: instantiate expected enemy count + 20% buffer.
- **Why**: `instantiate()` + `queue_free()` every frame causes GC stutter on mobile. Pooling eliminates this.

---

## Priority 2: Mobile-Ready UI 📱

### 2.1 Touch Input Implementation
- **Tower placement**: Tap party icon → icon attaches to finger → drag over map → valid zones highlight green (invalid = red) → release to place. If released on invalid area, cancel placement. No long-press (adds latency, frustrating on mobile).
- **Tower selection**: Tap placed tower → info popup appears above tower with Sell/Info buttons. Tap empty area to dismiss.
- **Cancel placement**: Add a visible ✕ button in bottom-left during placement mode, OR drag back to party bar to cancel.
- **Minimum touch targets**: All interactive elements must be ≥48×48dp (≈48px at 1× density). Godot's `Control.custom_minimum_size = Vector2(48, 48)`. For finger-friendly, prefer 56×56dp.
- **Touch feedback**: On every tap, play a subtle scale tween (1.0 → 0.9 → 1.0 over 0.1s) on the pressed element. Add `AudioStreamPlayer` click sound.

### 2.2 Responsive Scaling
- **Action**: After fixing §0.1, set up UI with anchor presets:
  - Top bar (lives, currency, wave counter): `PRESET_TOP_WIDE`, 64px height
  - Party bar: `PRESET_BOTTOM_WIDE`, 80px height (holds 6 Pokemon icons at 64×64)
  - Speed/pause buttons: `PRESET_CENTER_RIGHT`, offset 16px from edge
  - Wave start button: `PRESET_BOTTOM_RIGHT`, above party bar
- **Safe area handling for notched phones**: Use `DisplayServer.get_display_safe_area()` and offset UI margins accordingly. Wrap top-level UI in a `MarginContainer` whose margins are set from safe area insets.
- **Aspect ratio support**: Test at 16:9 (standard), 19.5:9 (modern phones), 4:3 (tablets). With `keep_height`, wider screens just show more horizontal map — which is fine for landscape TD.

### 2.3 Mobile HUD Layout
- **Bottom-anchored party bar**: Horizontal `HBoxContainer` with `ScrollContainer` (swipe if >6 Pokemon). Each icon is a `TextureButton` 64×64px with species icon + level badge.
- **Thumb zone design**: Keep primary actions (place tower, start wave, speed) in the bottom 40% of screen — this is the natural thumb reach zone in landscape grip. Info displays (lives, currency) go to top corners (glanceable, not interactive).
- **Tower info panel**: Slides up from bottom (tween `position.y` from offscreen), 30% screen height max. Shows: Pokemon name, level, type, DPS, range, sell value. Dismiss by tapping outside or swipe down.
- **No pinch-to-zoom** initially — adds complexity and TD maps are designed for fixed camera. Revisit only if maps become too large for the viewport.

---

## Priority 3: Sound & Music 🎵

*Moved UP from Priority 6. Sound is the single biggest "game feel" multiplier and is noticeable immediately. A silent game feels broken.*

### 3.1 Audio System Architecture
- **Action**: Create `scripts/autoload/audio_manager.gd` as autoload:
  - Properties: `music_bus`, `sfx_bus`, `ui_bus` (String names matching AudioServer buses)
  - Methods: `play_sfx(stream: AudioStream, pitch_variance: float = 0.05)`, `play_music(stream: AudioStream, fade_time: float = 1.0)`, `stop_music(fade_time: float = 0.5)`
- **AudioServer bus layout** (set in default_bus_layout.tres):
  ```
  Master
  ├── Music (volume: -6dB, add AudioEffectLimiter)
  ├── SFX (volume: 0dB)
  │   └── add AudioEffectLimiter (ceiling: -1dB) to prevent clipping when many towers fire
  └── UI (volume: -3dB)
  ```
- **SFX pooling**: Pre-create 8 `AudioStreamPlayer` nodes as children of AudioManager. When `play_sfx()` is called, find first non-playing player, assign stream, call `play()`. If all busy, skip (don't queue — real-time audio shouldn't lag).
- **Music crossfade**: Keep 2 `AudioStreamPlayer` nodes for music. To transition: fade current out (tween `volume_db` from 0 to -40 over `fade_time`), start new on second player (fade in from -40 to 0). After fade-out completes, stop old player.

### 3.2 Sound Effects (Priority Order)
Implement in this order — each one adds noticeable feel:
1. **Tower attacks**: One sound per type, with ±5% random pitch variation to avoid repetition:
   - Electric: short zap crackle (0.1-0.2s)
   - Fire: whoosh+crackle (0.2s)
   - Water: splash/bubble (0.2s)
   - Grass: leafy swoosh (0.15s)
   - Rock: heavy thunk (0.15s)
   - Ground: rumble (0.3s)
   - Bug: chittery buzz (0.15s)
   - Normal: generic pew (0.1s)
   - Flying: wind swoosh (0.2s)
2. **Enemy death**: Pop/poof sound (0.2s), pitch-shifted slightly per enemy
3. **Pokemon catch**: Success jingle (ascending 3-note chime, 0.5s), fail (descending buzz, 0.3s)
4. **UI sounds**: Button click (soft pop, 0.05s), button hover (subtle tick), menu transition (whoosh)
5. **Wave start**: Horn/trumpet sting (0.5s)
6. **Wave complete**: Victory chime (0.8s ascending arpeggio)
7. **Level up**: Sparkle+ding (0.5s)
8. **Super effective hit**: Impactful boom (0.3s) — this is a key Pokemon feel moment

### 3.3 Background Music
- **Music format**: Use `.ogg` (OGG Vorbis) for music — Godot imports natively, smaller than WAV, supports looping via `loop = true` in import settings. Set loop points in the import dock.
- **SFX format**: Use `.wav` for short SFX — no decoding overhead, critical for low-latency playback.
- **Track list** (minimum viable):
  - Main menu: Chill Pokemon-inspired theme, 60-90 BPM, looping
  - Battle (standard): Upbeat 120-140 BPM, looping. Use for most maps.
  - Battle (boss wave): Same key as standard battle but add percussion layers and raise tempo 10%. Crossfade when boss wave starts.
  - Victory: 4-bar triumphant fanfare, non-looping
  - Defeat: 2-bar somber sting, non-looping
- **Dynamic music approach**: Instead of separate boss tracks, use Godot's `AudioStreamInteractive` (4.5 feature) or manual layer approach: have battle music as stems (drums, bass, melody, tension layer). Play all simultaneously, mute tension layer normally, unmute during boss waves. This is more memory-efficient than loading separate tracks.

---

## Priority 4: Wave & Balance Improvements ⚖️

### 4.1 Difficulty Curve Design
- **Core principle**: Difficulty should follow an **S-curve**, not linear. Easy start (waves 1-3 teach mechanics), gradual ramp (waves 4-8), steep mid-game challenge (waves 9-15), plateau for strategic play (waves 16-20), then final boss spike.
- **Action**: Add per-map tuning variables to the wave generator:
  ```gdscript
  @export var base_enemy_hp_scale: float = 1.0
  @export var hp_growth_per_wave: float = 0.12  # 12% HP increase per wave
  @export var speed_growth_per_wave: float = 0.05  # 5% speed increase per wave
  @export var max_speed_multiplier: float = 2.0  # cap so enemies don't become undodgeable
  @export var enemy_count_growth: float = 0.15  # 15% more enemies per wave
  ```
- **Boss wave telegraph**: 3 seconds before boss wave (every 5th), show screen-wide banner "BOSS WAVE INCOMING!", play warning horn, camera does a subtle 2px shake over 0.5s. Gives player time to reposition/sell/upgrade.
- **Rubber-banding**: If player loses 3+ lives in a wave, reduce next wave's HP by 10%. If player clears with 0 lives lost, increase next wave HP by 5%. Keeps it challenging without brick-walling.

### 4.2 Economy Balancing
- **Income formula**: End-of-wave bonus = `base_income + (lives_remaining * interest_rate)`.
  - Suggested: `base_income = 50 + (wave_number * 10)`, `interest_rate = 5` Zenny per life.
  - This rewards clean play without making early mistakes unrecoverable.
- **Tower cost curve**: Ensure tower costs follow a clear power curve. Suggested framework:
  - Starter (unevolved): 100-150 Zenny
  - Mid (stage 2): 250-350 Zenny (via evolution, not purchase — evolution should feel like value)
  - Late (stage 3): 500+ Zenny equivalent in invested XP
- **"Sell and rebuild" problem**: At 70% refund, selling and rebuilding should be viable but not optimal. If it becomes dominant strategy, reduce to 60%.
- **Action**: Add a `economy_config.tres` resource with all these values. Don't hardcode — makes balancing iterations fast.

### 4.3 Wave Preview
- **Action**: Before each wave, show a `PanelContainer` at top of screen with:
  - Row of enemy species icons (unique types in this wave)
  - Count per species: "×12 ×8 ×3"
  - Total enemy count
  - Type icons below each species for quick reference
- Auto-dismiss when wave starts or player taps "Start Wave".
- **Why this matters**: Type effectiveness is the core strategy. Without preview, players can't plan. This turns the game from reactive to strategic — essential for TD depth.

### 4.4 Type Diversity in Waves
- **Action**: Wave generator should enforce minimum 2 types per wave after wave 3. Weight species selection to avoid >60% of any single type. Ensure at least one type the player's party is weak against appears every 3 waves — forces team diversity decisions.

### 4.5 Endless Mode
- After final wave, show "ENDLESS MODE UNLOCKED" banner.
- Scale: each endless wave increases HP by 20%, speed by 3%, count by 2. Every 10th wave is a boss.
- Track high score (waves survived) per map in save data.
- **Action**: Add `endless_mode: bool` to GameManager. When true, wave generator ignores `max_waves` and scales infinitely.

---

## Priority 5: New Pokemon Types 🆕

### 5.1 Remaining 9 Types
Currently 9 of 18 types. Add in this order (grouped by unique mechanic value):

**Batch 1 — High-impact new mechanics:**
- **Ice**: Freeze effect — enemy stops for 1.2s, then 50% slow for 2s. Projectile: icicle shard, `GPUParticles2D` frost trail. Strong vs Dragon/Grass/Flying/Ground.
- **Psychic**: Confusion — enemy reverses direction on path for 1.5s (use `PathFollow2D.progress -= speed * delta` while confused). Projectile: pink energy orb with wave distortion shader. Strong vs Fighting/Poison.
- **Fighting**: Melee range (64px radius), fastest attack speed (0.3s interval), highest single-target DPS. No projectile — play punch animation + shockwave ring. Strong vs Normal/Rock/Steel/Ice/Dark.

**Batch 2 — Strategic depth:**
- **Ghost**: Attacks pierce armor (ignore 100% of enemy defense stat). Can also hit "ghost-type" enemies that other towers miss (add ghost enemy trait). Projectile: shadow ball, passes through enemies hitting 3 max. Strong vs Ghost/Psychic.
- **Dark**: Attacks apply "Thief" debuff — enemies drop 25% bonus Zenny on death. Lower DPS to compensate. Projectile: dark pulse ring. Strong vs Ghost/Psychic.
- **Poison**: DOT stacking (up to 3 stacks, each ticking 5% max HP/second). Projectile: toxic sludge glob. Strong vs Grass/Fairy.

**Batch 3 — Support/utility:**
- **Steel**: Aura tower — reduces damage taken by towers within 96px radius by 20%. Low direct DPS. Place strategically near high-value towers. Strong vs Ice/Rock/Fairy.
- **Fairy**: Heals adjacent towers for 2% max HP/second (if tower HP system exists, otherwise: buff attack speed by 15% for towers in radius). Projectile: sparkle beam. Strong vs Dragon/Dark/Fighting.
- **Dragon**: Extreme range (256px), high damage, very slow attack speed (2.0s). Projectile: dragon energy beam (line, not homing — can miss fast enemies). Strong vs Dragon.

### 5.2 Tower Specializations
- **Implementation**: At evolution, show choice popup with 2 paths. Each path changes the tower's `attack_type` enum and modifies stats.
- Example specs:
  - **Charizard A** (Inferno): AOE radius +50%, damage -20%, adds burn DOT
  - **Charizard B** (Dragon Rage): Single-target, damage +40%, gains Dragon sub-type
  - **Blastoise A** (Hydro Cannon): 60% slow for 3s, slower fire rate
  - **Blastoise B** (Rapid Spin): Knockback + 360° splash, normal fire rate
- Store specialization choice in save data per Pokemon instance.

### 5.3 Legendary Towers
- Legendaries appear in boss waves. If caught (lower catch rate: 5% base), they become available as towers.
- Limit: 1 legendary per party (enforce in party select).
- Each has a unique "Ultimate" ability on a 60s cooldown (e.g., Mewtwo: freeze all enemies for 3s; Zapdos: chain lightning hitting every enemy once).

---

## Priority 6: Visual Polish ✨

### 6.1 GPUParticles2D Specifications
All particles should use `GPUParticles2D` (not `CPUParticles2D`) for mobile GPU acceleration. Key settings for performance:

**Global particle budget**: Cap at 500 total particles on screen. Each emitter should have conservative `amount` values.

**Per-type attack particles:**
- **Fire impact**: `amount=12`, `lifetime=0.4s`, `explosiveness=0.9`, orange→red color ramp, `scale_curve` 1.0→0.0, `gravity=Vector2(0, 20)`. Material: 4×4px white circle texture with `CanvasItemMaterial.blend_mode = ADD`.
- **Water impact**: `amount=8`, `lifetime=0.3s`, `explosiveness=1.0`, blue→transparent, `gravity=Vector2(0, 40)` (drips down). 3×3px circle.
- **Electric hit**: `amount=6`, `lifetime=0.15s`, `explosiveness=1.0`, yellow→white, random `spread=180°`. Tiny 2×2px squares.
- **Grass/Poison**: `amount=10`, `lifetime=0.6s`, green→yellow, `spread=360°`, slow outward velocity. 3×3px circle. `gravity=Vector2(0, -5)` (floats up).
- **Ice freeze**: `amount=16`, `lifetime=0.8s`, white→cyan, `spread=360°`, very low velocity. 2×2px diamond shapes. Persist while frozen.
- **Rock impact**: `amount=6`, `lifetime=0.25s`, brown→grey, high initial velocity, high gravity. 4×4px irregular shapes.

**Enemy death particle**: `amount=20`, `lifetime=0.5s`, `explosiveness=1.0`, white→transparent, outward burst. `one_shot=true`. Reuse via object pool (§1.6) — don't instantiate new particle nodes per death.

**Performance rule**: On mobile, if FPS drops below 55, halve all particle `amount` values dynamically. Check with: `Engine.get_frames_per_second()`.

### 6.2 Spritesheet Strategy
- For the 190+ Pokemon without spritesheets: generate a simple 2-frame idle animation procedurally:
  - Frame 1: base sprite
  - Frame 2: base sprite offset by Vector2(0, -2) (subtle bounce)
  - Alternate at 2 FPS. This is surprisingly effective and costs zero art time.
- **Action**: In the base tower/enemy script, add:
  ```gdscript
  var _bounce_tween: Tween
  func _ready():
      if not animated_sprite.sprite_frames.has_animation("idle"):
          _bounce_tween = create_tween().set_loops()
          _bounce_tween.tween_property(sprite, "position:y", -2.0, 0.3)
          _bounce_tween.tween_property(sprite, "position:y", 0.0, 0.3)
  ```

### 6.3 Screen Shake & Juice
- **Camera shake**: Create `scripts/util/camera_shake.gd`. On trigger, apply random `offset` to Camera2D over duration:
  ```gdscript
  func shake(intensity: float = 3.0, duration: float = 0.2):
      var tween = create_tween()
      for i in range(int(duration / 0.02)):
          tween.tween_property(camera, "offset", Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)), 0.02)
      tween.tween_property(camera, "offset", Vector2.ZERO, 0.02)
  ```
- **Boss spawn**: intensity=5.0, duration=0.4
- **Tower attack recoil**: Tween scale from 1.0→0.85→1.0 over 0.1s on attack (use `tween_property(sprite, "scale", ...)`).
- **Enemy death**: Scale 1.0→1.3 + modulate→white over 0.1s, then scale→0.0 + fade out over 0.15s. Then spawn death particles.
- **Wave complete**: Spawn 30 confetti particles from top of screen (one-shot `GPUParticles2D`, `gravity=Vector2(0, 100)`, rainbow color ramp).
- **Super effective hit**: Brief 0.05s engine pause (`get_tree().paused = true` for 1 frame via timer) — "hit stop" effect used in fighting games. Extremely satisfying.

### 6.4 Map Visual Themes
- Themed background per region: Kanto=grassland, Johto=traditional, Hoenn=tropical, etc.
- **Action**: Create a `MapTheme` resource with: `background_texture`, `path_color`, `ambient_particle_scene`, `color_palette`.
- Ambient particles: forest maps get falling leaves (8 particles, slow, looping), ice maps get snowflakes (12 particles, slow downward drift), etc.

### 6.5 UI Polish
- **Screen transitions**: Use a shared `TransitionManager` autoload. Fade to black (tween `ColorRect` alpha 0→1 over 0.3s), change scene, fade from black (0.3s). Simple and effective.
- **Tower placement ghost**: Show tower sprite at 50% opacity (`modulate.a = 0.5`) following touch position. Tint green if valid zone nearby, red if not.
- **Range indicator**: Draw circle using `_draw()` override on tower: `draw_arc(Vector2.ZERO, attack_range, 0, TAU, 64, Color(1,1,1,0.2), 2.0)`. Show on tower select and during placement.
- **Health bar colors**: Use a `Gradient` resource: green (#4CAF50) at 1.0, yellow (#FFC107) at 0.5, red (#F44336) at 0.2. Sample with `gradient.sample(hp_ratio)`.

---

## Priority 7: Progression & Meta 🏆

### 7.1 Victory Rewards Screen
- **Action**: Create `scenes/ui/victory_screen.tscn`:
  - Zenny earned (base + bonus for lives remaining)
  - Pokemon caught this round (show icons with catch animation — ball shake sequence)
  - XP gained per tower (show level-up badges)
  - Star rating: ★ = clear, ★★ = clear with ≥50% lives, ★★★ = clear with 100% lives
- Star rating creates replayability — essential for mobile retention.
- Tween elements in sequentially (Zenny counter first, then catches, then stars) over 2-3 seconds. Don't show everything at once.

### 7.2 Tutorial / First-Time Experience
- **Action**: First map (Pallet Town) is a guided tutorial:
  - Step 1: "Tap Charmander to select, then tap a green zone to place" (highlight party + zones, dim everything else)
  - Step 2: "Tap Start Wave to begin!" (highlight button)
  - Step 3: After wave 1, "Nice! Fire is super effective against Grass types" (show type chart snippet)
  - Step 4: Wave 2 introduces catching: "When enemies get low HP, you might catch them!"
  - Step 5: After tutorial map, unlock full campaign
- Use a `TutorialManager` that tracks steps and overlays highlight rects + text bubbles.
- **Never** force-tutorial on replays. Gate with `SaveManager.has_completed_tutorial`.

### 7.3 Pokedex Screen
- **Action**: Grid of all Pokemon (silhouettes for unseen, greyed icons for seen, full color for caught).
- Tap for detail: stats, type, where to find, caught count.
- Completion % per region shown on campaign select screen.
- **Engagement hook**: "X Pokemon remaining in Kanto" drives completionism — this is the core Pokemon engagement loop.

### 7.4 Pokemon Storage/PC
- Box system: 10 boxes of 30 slots each (300 Pokemon storage).
- Accessible from campaign screen. Drag-and-drop between party and storage.
- Required before players' caught Pokemon overflow the party limit.

### 7.5 Achievement System
- Implement as a resource-based system: `AchievementData` resource with `id`, `title`, `description`, `condition`, `reward_zenny`, `is_unlocked`.
- Track in save data.
- Key achievements:
  - "Kanto Complete": Clear all Kanto maps → 500 Zenny
  - "Perfect Clear": Win any map without losing a life → 200 Zenny
  - "Gotta Catch 'Em All": Catch 50 unique species → 1000 Zenny
  - "Evolution Revolution": Evolve 10 Pokemon → 300 Zenny
  - "Type Master": Win using a mono-type team → 400 Zenny
  - "Speed Demon": Clear a map on 3× speed → 150 Zenny
- Show achievement popup as a toast notification (slide down from top, hold 2s, slide up).

### 7.6 Settings Screen *(NEW)*
- **Action**: Create settings screen accessible from main menu and pause menu:
  - Master Volume slider (0-100, maps to `AudioServer.set_bus_volume_db("Master", linear_to_db(value/100))`)
  - Music Volume slider (same pattern, "Music" bus)
  - SFX Volume slider ("SFX" bus)
  - Screen shake toggle (some players get motion sick)
  - Damage numbers toggle
  - Language selector (future-proofing, even if only English now)
- Persist in `user://settings.cfg` using `ConfigFile` — separate from save slots.

---

## Priority 8: Performance & Polish for Release 🚀

### 8.1 Performance Profiling Checklist
Before any mobile release, verify:
- [ ] 60 FPS sustained during 20+ enemy waves on mid-range Android (Snapdragon 6xx)
- [ ] No GC stutters >16ms (check with Godot profiler's frame time graph)
- [ ] Object pools active for projectiles, damage numbers, death particles
- [ ] Physics layers properly configured (§0.2)
- [ ] No orphaned nodes (check with `print_orphan_nodes()` in debug)
- [ ] Texture sizes: No texture larger than 1024×1024 for mobile. Pokemon icons should be 64×64 or 96×96 max.
- [ ] Use texture atlases for Pokemon icons — one atlas per generation, reduces draw calls.

### 8.2 Signal vs Direct Call Guidelines
- **Use signals for**: Loose coupling between systems (tower_placed, enemy_died, wave_completed, pokemon_caught). These are already well-implemented.
- **Use direct calls for**: Performance-critical per-frame logic (tower targeting, projectile movement). Signals add ~2μs overhead per emit — negligible for events, noticeable in tight loops.
- **Never**: Connect signals in `_process()`. Connect once in `_ready()`.
- **Prefer `@onready`** over `get_node()` in `_process()` — caches the reference.

### 8.3 Mobile-Specific Optimizations
- Set `rendering/renderer/rendering_method = "mobile"` in project.godot for mobile export (uses Vulkan mobile renderer, significant perf gain).
- Reduce `physics/common/physics_ticks_per_second` from 60 to 30 if enemies don't need 60Hz physics (Path2D following is visual, not physics-dependent — use `_process` not `_physics_process` for path movement).
- Enable `rendering/textures/canvas_textures/default_texture_filter = "nearest"` for pixel art style (also faster than linear filtering).
- Battery optimization: When game is paused or in menus, reduce FPS with `Engine.max_fps = 30`. Restore to 60 during gameplay.

---

## Implementation Order (Revised)

| Phase | Items | Effort | Rationale |
|-------|-------|--------|-----------|
| **Sprint 0** | Project config fixes (0.1-0.4) | 1 hour | Prevents compounding issues |
| **Sprint 1** | Quick Wins (1.1-1.5) + Object Pool (1.6) | 2 days | Unblocks everything else |
| **Sprint 2** | Audio system + SFX (3.1-3.2) | 2-3 days | Biggest "feel" improvement, no dependencies |
| **Sprint 3** | Victory screen (7.1) + Settings (7.6) | 1-2 days | Complete the core loop |
| **Sprint 4** | Touch input + Mobile HUD (2.1-2.3) | 3-4 days | Makes it playable on target platform |
| **Sprint 5** | Difficulty tuning + Wave preview + Economy (4.1-4.3) | 2-3 days | Makes it *fun* on target platform |
| **Sprint 6** | Visual juice: particles, shake, transitions (6.1, 6.3, 6.5) | 2-3 days | Polish that retains players |
| **Sprint 7** | Tutorial (7.2) + Pokedex (7.3) | 2-3 days | Onboarding + engagement loop |
| **Sprint 8** | New types batch 1: Ice, Psychic, Fighting (5.1) | 3 days | Expands strategic depth |
| **Sprint 9** | BGM + Dynamic music (3.3) | 2 days | Full audio experience |
| **Sprint 10** | New types batch 2-3 + Specializations (5.1-5.2) | 4-5 days | Content expansion |
| **Sprint 11** | Remaining: Endless mode, Achievements, Storage, Legendaries | Ongoing | Long-tail content |
| **Sprint 12** | Performance profiling + Mobile release prep (8.1-8.3) | 2 days | Ship it |

---

## Key Changes from Previous Roadmap

1. **Added Priority 0** (project config) — stretch/aspect, physics layers, export templates, and input map were all unconfigured. These cause real bugs if not fixed first.
2. **Added object pooling** (§1.6) — essential for mobile performance, was completely missing.
3. **Moved Sound/Music from Priority 6 → Priority 3** — a silent game feels broken. Sound is the highest-impact polish per hour invested.
4. **Added Settings screen** (§7.6) — was missing entirely. Players need volume controls, especially on mobile.
5. **Added Performance section** (Priority 8) — mobile release needs explicit performance targets and optimization checklist.
6. **Added specific GPUParticles2D settings** (§6.1) — every particle effect now has exact amount/lifetime/behavior specs.
7. **Added economy balancing framework** (§4.2) — was just "income system" before, now has formulas and resource-based config.
8. **Added rubber-banding difficulty** (§4.1) — prevents player frustration without removing challenge.
9. **Added hit-stop juice** (§6.3) — fighting game technique that makes super-effective hits feel incredible.
10. **Added safe area handling** (§2.2) — notched phones will clip UI without this.
11. **Added star rating to victory screen** (§7.1) — drives replayability, standard in mobile TD games.
12. **Removed pinch-to-zoom** recommendation — adds complexity for minimal value in fixed-camera TD.
13. **Added procedural idle animation** (§6.2) — solves the 190+ static sprite problem with zero art assets.
14. **Added mobile renderer setting** (§8.3) — must use `mobile` rendering method, not `forward_plus`, for Android/iOS.
15. **Reordered implementation sprints** — config fixes first, audio before visual polish, tutorial before content expansion.
