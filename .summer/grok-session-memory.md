# Grok Session Memory — The Inferno Curse

> **Read this file at the start of every session** before making changes.
> Last updated: 2026-06-23

## Project Identity

- **Title:** The Inferno Curse
- **Engine:** Godot 4.6 (Forward Plus), GDScript
- **Entry scene:** `res://scenes/main.tscn`
- **Autoload:** `PlayerData` → `res://autoload/player_data.gd`
- **Workspace:** `c:\Gadot Projects\the-inferno-curse`

A historically grounded Italian RPG (1200s–1300s) framed through Dante's *Inferno*. Each major city sits under one circle of Hell. First city: **Florence under Limbo** — beautiful, solemn, suspended; decay through absence and delay, not fire and ruin.

**Visual target:** HD-2D / 3D HD — 3D environments + billboard pixel-art sprites (Octopath-adjacent). Dark, moody palette: deep golds, shadow blues, burnt orange.

**Deeper vision docs:**
- `.summer/GameSoul.md` — creative brief
- `.summer/art-bible.md` — Florence/Limbo art direction
- `docs/` — systems design (combat, stats, AI, factions, abilities)

---

## Architecture Snapshot

### Exploration (playable now)

| Piece | Path | Notes |
|-------|------|-------|
| Main scene | `scenes/main.tscn` | Tavern test space; root script is `battle_test_map.gd` |
| Player | `scripts/player_3d.gd` | `CharacterBody3D`, WASD on XZ, `AnimatedSprite3D` billboard, `movement_enabled` flag |
| Camera | `scripts/camera_follow.gd` | Orthographic follow |
| Runtime stats | `autoload/player_data.gd` | Bridge from `CharacterSheet` `.tres` to UI/game |

### Stat / data layer

| Resource | Path |
|----------|------|
| Core stats | `scripts/data/core_stats.gd` |
| Modifiers | `scripts/data/stat_modifier.gd` |
| Character sheet | `scripts/data/character_sheet.gd` |
| Monster sheet | `scripts/data/monster_sheet.gd` |
| NPC sheet | `scripts/data/npc_sheet.gd` |
| Player data | `data/characters/guglielmo_da_siena.tres` |
| Test enemy | `data/monsters/training_brigand.tres` |

**Formulas (current):** POW/DEF derived from level + core stats + modifiers. See `docs/stat_sheet_foundation.md`.

### UI (exists, not combat-integrated)

- `scenes/ui/character_sheet_ui.tscn` + `scripts/ui/character_sheet_ui.gd`
- `scenes/ui/monster_sheet_ui.tscn` + `scripts/ui/monster_sheet_ui.gd`
- Status icon PNGs: `assets/ui/status_icons/` (bleed, poison, paralyze, holy, corruption, physical) — **not wired to combat yet**

---

## Active Work: Combat System

**Status:** Core tactical engine scaffolded; playable smoke test in tavern. **Not yet player-facing tactical UI.**

### Core classes (`scripts/combat/`)

| Class | Role |
|-------|------|
| `CombatGrid` | Grid map, neighbors, LOS, height/flank/cover math |
| `CombatCell` | Walkability, half/full cover, height, occupancy, terrain tags |
| `CombatActor` | `Node3D` battle unit; syncs stats from sheets; 8-dir visual → 4-dir tactical facing |
| `CombatState` | CT turn order, movement range, targeting, damage, victory/defeat, temp terrain |
| `CombatTerrain` | Spell/ability battlefield objects with duration |

### Implemented tactical rules

- **CT turns:** threshold 100; speed-based fill; priority by CT → speed → actor_id
- **Flank:** side +10, back +20; pincer +10 when ally threatens opposite side
- **Height:** melee/ranged modifiers; jump limits movement and melee reach
- **Cover:** directional along attack line; half +12 DEF, full +26 / blocks LOS
- **Terrain:** `place_terrain()` / `remove_terrain()` with round-based expiry

### Test harness

- **Script:** `scripts/combat/battle_test_map.gd` (attached to `World` in `main.tscn`)
- **Trigger:** Walk within ~2.75 units of Training Brigand
- **During combat:** player movement locked; 12×12 grid overlay; `Label3D` shows round/CT
- **Player turn:** Enter/Space → auto-melee nearest enemy in range, end turn
- **Enemy turn:** auto-attacks first valid target
- **Test terrain:** table half-cover, bar full-cover/obstruction, raised floor tile

### Combat docs

- `docs/turn_based_battle_system.md` — architecture + next steps
- `docs/ai_tactical_combat.md` — enemy doctrine/formations (future)

### Combat — DONE vs NOT DONE

**Done:**
- Grid, cells, actors, state machine, damage resolution
- CT turn loop, basic melee auto-resolve
- Proximity encounter trigger in tavern
- Stat sheet integration on `CombatActor`

**Not done (priority order from design doc):**
1. ~~Player turn actions — move to cell, pick target~~ — **done** (click blue to move, red to attack; Enter skips)
2. Battle UI — turn order bar, action menu, proper HUD (cell highlights exist)
3. Battle preview — reachable cells, cover warnings, flank/back hints
4. Ability/spell data system calling `CombatState.place_terrain()`
5. Enemy AI beyond "attack first target" (doctrine, formations, morale)
6. Status effects (icons exist, no combat integration)
7. Sync combat outcomes back to `PlayerData` autoload

---

## Key Conventions

- **Match existing style** in GDScript: typed hints, `class_name`, signals, `@export`
- **Sheets are source of truth** for authored stats; `PlayerData` holds mutable runtime state
- **Summer Engine MCP** available for run/diagnostics (`mcps/summer-engine/`)
- **Plans live in** `.summer/plans/`; validation scripts in `.summer/local/`
- **Don't expand scope** unless asked — combat is the current focus

---

## How to Run / Test

1. Main scene is already `scenes/main.tscn`
2. WASD to move in tavern
3. Approach Training Brigand (red capsule marker) to start combat
4. Press Enter/Space on your turn to attack
5. Use Summer `play` skill or Godot editor to verify gameplay changes

---

## Git / WIP Notes (2026-06-23)

Uncommitted / in-progress areas:
- `scripts/combat/` — new combat system (untracked)
- `scenes/main.tscn` — wired to `battle_test_map.gd`
- `scripts/player_3d.gd` — `movement_enabled` for combat lock
- `scripts/data/monster_sheet.gd`, `data/characters/guglielmo_da_siena.tres` — stat tweaks
- `assets/ui/status_icons/` — generated icons + job JSON (not integrated)
- `docs/turn_based_battle_system.md` — architecture doc

---

## Session Start Checklist (for agents)

1. Read this file
2. If combat work: skim `docs/turn_based_battle_system.md` and `scripts/combat/battle_test_map.gd`
3. If art/narrative: read `.summer/art-bible.md` and `.summer/GameSoul.md`
4. If stats/characters: read `docs/stat_sheet_foundation.md` and relevant `.tres` files
5. Ask user which track to continue if unclear

---

## Likely Next Session Tasks

Pick up where the user left off. Natural continuations:

- **Combat UX:** reachable-cell overlay + click-to-move + target selection
- **Combat HUD:** turn order, HP bars, action panel
- **Abilities:** data resource + first spell that places `CombatTerrain`
- **AI:** brigand uses cover / flanking per `docs/ai_tactical_combat.md`
- **Polish:** sync post-combat HP/XP to `PlayerData`