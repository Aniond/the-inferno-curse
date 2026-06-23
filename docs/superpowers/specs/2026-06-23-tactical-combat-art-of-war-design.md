# Tactical Combat & Art of War Design Spec

**Date:** 2026-06-23  
**Status:** Approved for review  
**Scope:** Full positional tactical combat (8-way facing, directional cover, height-cost movement) with Sun Tzu–inspired enemy AI gated by monster INT.

---

## Summary

Battles in *The Inferno Curse* should feel like positional chess on explorable battle maps: every facing, cover angle, height step, and rotation matters. Enemy NPCs use **authored tactical plans** selected by a **secret `TacticalMind` layer** derived from **INT** (Intellect). Players see INT on monster sheets but never see internal AI scores — they learn enemy doctrine through telegraphed behavior and optional post-encounter codex notes.

This spec extends the existing `CombatGrid`, `CombatCell`, `CombatActor`, `CombatState`, and `CombatTerrain` stack documented in `docs/turn_based_battle_system.md` and aligns with `docs/ai_tactical_combat.md` and the Sun Tzu game-AI design brief.

---

## Goals

1. **Full directional tactics (Option D):** true 8-way facing, 8-way adjacency combat, directional object cover.
2. **Very tactical player loop:** move, rotate, act — with readable overlays for cover, flank, and height.
3. **Height costs movement:** climbing/descending consumes MOV; skills can reduce jump cost.
4. **Art of War as pretense:** doctrine-driven enemies shape terrain, timing, and deception — never omniscient cheating.
5. **Secret AI intelligence:** `TacticalMind` depth scales with INT; formulations (plans) are authored, selection is utility-scored.

## Non-Goals (this spec)

- Full GOAP for every unit at runtime.
- Online reinforcement learning in shipping builds.
- Edge-based per-cell wall cover (deferred unless a map requires it).
- Player battle orders UI (noted as future; ally AI uses defensive defaults).

---

## Core Tactical Loop

### Turn order

Unchanged: CT threshold 100, speed-based tick, highest CT acts first.

### Action economy (per actor turn)

When CT ≥ 100, the actor receives one turn with three optional phases in order:

1. **Move** (optional) — spend MOV budget across path steps.
2. **Rotate** (optional, 0 MOV cost) — set facing to any of 8 directions.
3. **Act** — attack, ability, item, defend, or wait.

**Rules:**

- Rotate may occur after move, before act.
- Rotate is **not** allowed after act.
- If the actor moves without rotating, previous facing is retained.
- Defend sets a facing and ends the turn without attacking.

### Movement costs

| Component | Cost |
|-----------|------|
| Cardinal step | 1 |
| Diagonal step | 2 |
| Climb (per height level up) | +2 per level |
| Descent (per height level down) | +1 per level |
| Terrain `movement_cost` | Replaces base step minimum (not additive) |

**Jump stat:** maximum height difference traversable in a single step (capability gate, not a resource).

**Skill modifiers** (passive or buff):

| Modifier | Effect |
|----------|--------|
| `jump_cost_reduction: int` | Flat discount on height cost (floor 0) |
| `jump_cost_multiplier: float` | Multiplier on height cost |
| `ignore_first_height_level: bool` | First level up/down on a step is free |
| `downhill_free: bool` | Descent costs 0 |

Pathfinder sums per-step cost; unreachable if any step exceeds MOV budget or `jump` cap.

### 8-way facing and flank arcs

`CombatActor` uses **8 tactical facings** (no collapse to 4). Each facing defines a 45° arc.

| Arc | Angular coverage (relative to facing) | Attack bonus |
|-----|---------------------------------------|--------------|
| Front | ±45° | 0 |
| Right flank | +45° to +135° | +10 |
| Back | rear 90° (±180° ±45°) | +20 |
| Left flank | −45° to −135° | +10 |

**Pincer:** +10 when an allied actor threatens the defender from the opposite arc and is adjacent (cardinal or diagonal).

Arc is computed from the vector attacker cell → defender cell vs defender facing.

### 8-way adjacency combat

- **Melee:** any of 8 adjacent cells; Chebyshev distance 1; height delta ≤ attacker `jump`.
- **Ranged:** Chebyshev distance ≤ effective range; grid LOS + `CoverVolume` ray checks.
- **Effective ranged range:** base range + `get_range_bonus_from_height` (existing).

### Directional cover — `CoverVolume`

New node/class extending `CombatTerrain`:

```
facing: 8-way enum
cover_type: NONE | HALF | FULL
coverage_arc: degrees (default 180 — protected hemisphere in front of facing)
height_band: LOW | MID | TALL
```

**Resolution:** Ray from attacker cell center → defender cell center (height-aware). A volume contributes cover only if:

1. The ray intersects the volume's protected region, and  
2. The attack direction enters through the volume's **front arc** (the covered side).

Multiple volumes: **strongest bonus only** (not stacked). Wrong-side approach grants no cover from that volume.

**Cell-level cover** (`CombatCell.cover_level`) remains for zone terrain (fog, rubble fields). Object cover handles furniture and props.

**Cover bonuses (unchanged):** Half +12 DEF equivalent, Full +26; Full blocks LOS when `blocks_ranged_line_of_sight` applies.

---

## Abilities & Spell Terrain

### `TacticalProfile` (per ability)

```
range_min: int
range_max: int
attack_pattern: SINGLE | LINE | CONE | RADIUS | ARC
valid_directions: 8-way flags (default all)
ignores_cover: bool
ignores_height: bool
creates_terrain: TerrainSpec | null
facing_required: bool
```

- **CONE:** 90° default arc from current facing, range N.
- **LINE:** pierces cells; each `CoverVolume` on ray evaluated per defender.
- **Facing required:** must rotate to valid direction before cast.

### Spell terrain examples

| Terrain | Behavior |
|---------|----------|
| Cursed fog | Cell zone, half cover all dirs, may block LOS at full density |
| Sanctified circle | Half cover from outside approaches |
| Hellfire vein | Line, damage-on-enter, no cover, blocks retreat |
| Barricade ritual | Spawns `CoverVolume` facing caster, 180° half, timed |

Uses existing `CombatState.place_terrain()` / `remove_terrain()` snapshot system.

---

## Curse ↔ Tactics

| Curse stage | Stacks | Combat effect |
|-------------|--------|---------------|
| Latent | 0–2 | None; `ambush` doctrine may wait |
| Active | 3–5 | −1 MOV; AI prioritizes isolation |
| Compounding | 6+ | Rotate costs 1 MOV; AI commits `pincer` |

Purification clears stacks — counterplay axis beyond damage.

---

## Influence Maps

Shared per-encounter fields on `CombatGrid`, rebuilt on move/terrain change:

| Map | Meaning |
|-----|---------|
| `threat[cell]` | Expected damage if player ends turn here |
| `cover_quality[cell]` | Best directional cover value from nearby volumes |
| `height_advantage[cell]` | Ranged/melee bonus vs current enemy positions |
| `chokepoint[cell]` | Few exits + high cover = lane value |
| `retreat_safety[cell]` | Distance from threats × cover × downhill bonus |

**Player:** optional faint heat overlay toggle.  
**AI:** reads same maps; belief-weighted player position (last seen + route guess), not omniscient.

---

## Art of War — Doctrine & Fair Deception

Doctrine tags on enemy groups drive intent, not stat inflation:

| Doctrine | Behavior |
|----------|----------|
| `hold_ground` | Defend cover, refuse flanks, slow advance |
| `ambush` | Wrong facing at start; burst when player overextends |
| `pincer` | Split force; converge on isolated/low-DEF target |
| `feint_retreat` | Back-step to lure into kill box |
| `economy_of_force` | Ranged + curse pressure; avoids fair trades |
| `terrain_mastery` | Seize height + chokepoints |

**Fairness rules:**

- Deception is telegraphed (formation, facing order, audio/visual cues).
- AI uses belief state, not perfect player knowledge.
- No silent parameter cheating; boss "mind reading" requires visible fiction cues.

Player doctrine hints: icon only after first encounter with enemy type. Optional codex: diegetic summary, not algorithm dump.

---

## Secret AI — `TacticalMind`

### Concept

Each AI-controlled `CombatActor` owns a `TacticalMind` (runtime only, not in player HUD). Effective intellect drives tier:

```
effective_int = core_stats.intellect + active INT modifiers
mind_tier = floor(effective_int / 3)   # 1 at INT 3, 2 at INT 6, …
```

| Tier | INT range | Label (dev only) | Capabilities |
|------|-----------|------------------|--------------|
| 1 | 1–2 | Instinct | Nearest target; no rotate planning |
| 2 | 3–5 | Cunning | Nearest `CoverVolume`; chase side arcs |
| 3 | 6–8 | Tactician | One doctrine plan; 1-turn lookahead; rotate |
| 4 | 9–11 | Strategist | 2–3 plan comparison; influence maps; telegraphed feint |
| 5 | 12–14 | Mastermind | Belief model; pincer coordination; 2-turn plan cache |
| 6 | 15+ | Infernal Mind | Multi-unit sync; curse exploitation; bounded habit memory |

INT affects planning depth, not raw damage. Monster sheet shows INT; internal scores stay secret.

### Tactical formulations (authored plans)

| `plan_id` | Doctrine | Summary |
|-----------|----------|---------|
| `shield_wall` | hold_ground | Front holds choke; ranged behind cover |
| `kill_box` | ambush | Lure into lane; block exits |
| `pincer_close` | pincer | Opposite flanks on priority target |
| `feint_withdraw` | economy_of_force | Retreat lure then burst |
| `high_ground_seize` | terrain_mastery | Height + cover pathing |
| `curse_press` | infernal | Curse terrain; isolate corrupted |
| `break_the_line` | aggressive | Commander finds weak flank; commit window |

### Enemy turn algorithm

```
1. TacticalMind.update_belief(world, observations)
2. eligible_plans = doctrine_plans ∩ tier_unlocked_plans
3. score each plan (utility + influence maps; depth limited by tier)
4. commander (group_role == "commander") sets group plan; roles assign sub-goals
5. execute: rotate → move → act
```

Low INT: single hardcoded plan per doctrine. High INT: switch plans when belief changes.

### NPC combat

- Recruitable NPCs use same `TacticalMind` when AI-controlled.
- Ally default doctrines: `hold_ground`, `support_healer`.
- Enemy doctrines from `MonsterSheet` / `ai_tags` + `formation_tag`.
- Limbo Florence: `hold_ground`, slow morale break (`docs/ai_tactical_combat.md`).

---

## Data Schema Extensions

### `MonsterSheet` / `NpcSheet` (new exports)

```
doctrine: String
formation_tag: String
group_role: String          # front | flanker | ranged | commander
morale: int                 # 0–100
discipline: int             # 0–100
preferred_range: int
terrain_preferences: Array[String]
retreat_behavior: String    # never | leader_falls | morale_break
tactical_mind_profile: String  # optional override; default from INT
```

Existing `ai_tags` extended with doctrine strings. `core_stats.intellect` already exists.

### New types

| Type | Responsibility |
|------|----------------|
| `CoverVolume` | Directional cover object on grid |
| `TacticalMind` | Belief, tier, plan scoring, execution hints |
| `TacticalProfile` | Ability pattern metadata |
| `CombatInfluenceMaps` | Shared threat/cover/choke/retreat fields |
| `GroupBattlePlan` | Commander-selected plan + role assignments |

---

## Player UI

| Element | When |
|---------|------|
| Move range overlay | Player move phase |
| Attackable cells / targets | Player act phase |
| Flank arc colors from facing | Hover attack |
| Cover warning with approach dir | Hover target |
| Height advantage chip | Hover target |
| Doctrine hint icon | After first fight vs type |
| Influence heat overlay | Optional toggle |
| AI debug (plan, scores) | Dev builds only |

---

## Architecture

```
CombatState
├── CombatGrid
│   ├── CombatCell[]
│   ├── CoverVolume[] (registered)
│   └── CombatInfluenceMaps
├── CombatActor[]
│   └── TacticalMind (AI only)
└── GroupBattlePlan (per faction group)
```

Damage resolution path (unchanged entry point, extended modifiers):

`calculate_damage` → height + flank + pincer + directional cover + defense.

---

## Implementation Phases

| Phase | Deliverable |
|-------|-------------|
| P1 | 8-way tactical facing; rotate action; angle-based flank arcs |
| P2 | `CoverVolume`; directional cover ray; LOS integration |
| P3 | Jump movement costs; skill cost modifiers |
| P4 | Battle overlay UI (cover, flank, height warnings) |
| P5 | `TacticalMind` tiers 1–3; plans: instinct + shield_wall + basic attack |
| P6 | Influence maps; tiers 4–5; commander group sync; pincer/kill_box |
| P7 | Curse-stage tactics; tier 6; belief model |
| P8 | Ability cones/lines; spell-spawned `CoverVolume` |

Each phase is playable standalone.

---

## Testing

1. **P1:** Back attack from diagonal facing grants +20; rotate-after-move enables backstab setup.
2. **P2:** Barrel cover blocks south approach only; north approach exposed.
3. **P3:** Diagonal climb 1 level costs 4 MOV; `jump_cost_reduction` skill lowers it.
4. **P5:** INT 4 brigand seeks cover; INT 10 brigand flanks after feint rotate.
5. **P6:** Two-enemy pincer triggers bonus when player faces one ally.
6. **Fairness:** AI without line of sight does not attack through full cover unless ability ignores it.

---

## References

- `docs/turn_based_battle_system.md` — existing combat components
- `docs/ai_tactical_combat.md` — doctrine and formations
- `docs/stat_sheet_foundation.md` — INT definition
- Sun Tzu / Infernal Curse Game AI brief (desktop PDF) — condition-shaping AI, belief state, influence maps

---

## Open Questions (deferred)

- Player battle orders UI scope and PRS-based obedience.
- Whether INT is hidden on monster sheet until Scan/Absorb ability.
- MCTS for boss duel phases only — budget TBD in boss design specs.