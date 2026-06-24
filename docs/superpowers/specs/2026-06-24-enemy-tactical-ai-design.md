# Enemy Tactical AI — Utility Scorer with Intelligence & Squad Command

**Date:** 2026-06-24
**Status:** Approved
**Scope:** `scripts/combat/enemy_tactical_ai.gd` (new), `scripts/combat/ai_turn_plan.gd` (new), `scripts/combat/enemy_commander.gd` (new), `scripts/combat/ai_directive.gd` (new), `scripts/combat/battle_test_map.gd`, `scripts/data/monster_sheet.gd`, `scripts/combat/combat_actor.gd`

---

## Problem

Enemy turns are purely scripted: `_resolve_enemy_turn` attacks the first target already in melee range and otherwise does nothing. Enemies do not move toward targets, seek flanks, use cover or height, or preserve themselves. There is no notion of an enemy being smarter or dumber than another, and no way for a boss to coordinate lower-level mobs.

We want a tactical AI that:
1. Decides each turn *where to stand and what to attack* using weighted utility scoring.
2. Scales sophistication with an **intelligence score** — a brute charges; a tactician flanks, takes cover, and retreats when losing.
3. Lets a **commander** (boss) coordinate subordinate mobs via formations, focus-fire, maneuvers, and posture/timing calls.
4. Stays fully scripted and offline-testable now, with typed hooks for a later Gemini advisor, belief/fog layer, influence maps, and a difficulty slider.

---

## Design framework

This design is the turn-based-tactics reduction of the hybrid architecture in the project's Sun Tzu / Infernal Curse AI research document. The load-bearing principle from that document drives the whole structure:

> **Separate intent (the "why") from motion (the "how").** Intent should feel Sunzian and infernal; motion should be physically grounded. If you later add learning, learn the intent weights first, not the locomotion.

We build the **intent + motion core** now: a utility scorer (intent) cleanly separated from the existing move/rotate/attack execution (motion), plus a squad command layer above it. Influence maps, belief state, curse ecology, GOAP planning, and offline RL from the document are explicitly deferred and left as typed hooks.

Two further document principles are guardrails on this design:
- **"Apparent cunning, not hidden omnipotence."** v1 uses full-board honest reasoning (no future-RNG peeking, no reading the player's next input), and every decision is loggable as named reasons. A belief/fog layer is a later hook, not a v1 requirement.
- **"Cap coordination bandwidth."** Commanded mobs treat directives as strong biases, not blind orders. A high-INT mob can override a suicidal directive; the squad is not a perfect hive mind.

---

## Architecture — three layers with clean seams

```
SQUAD layer (Phase 2)
  EnemyCommander (RefCounted)
    reads board -> picks squad posture + per-mob directives
    writes an AiDirective onto each subordinate's turn
        │  AiDirective (data) biases unit scoring
        ▼
UNIT layer (Phase 1)
  EnemyTacticalAI (RefCounted)
    choose_turn(actor, directive=null)
      -> enumerate plans -> score (INT-gated considerations
         + directive biases) -> 1-ply lookahead -> softmax top-k
      -> returns AiTurnPlan + decision log
        │  AiTurnPlan (data): destination, target, facing
        ▼
MOTION layer (exists)
  battle_test_map._resolve_enemy_turn
    executes plan: move -> rotate -> attack
```

**The seam that keeps it thin:** an `AiDirective` is data the commander writes and the unit scorer reads as extra biases. A lone enemy receives `directive = null` and scores normally. The unit AI is **identical** whether solo or commanded — the squad layer only tilts its weights. This lets Phase 1 be built and verified in complete isolation before Phase 2 exists.

`EnemyTacticalAI` and `EnemyCommander` extend `RefCounted` (pure logic, no scene nodes), so both are unit-testable by feeding handcrafted board state and asserting the returned plan/directives.

---

## Section 1 — Data classes

### `AiTurnPlan` (`scripts/combat/ai_turn_plan.gd`, `extends RefCounted`)

One candidate action for a unit's turn.

| Field | Type | Meaning |
|---|---|---|
| `destination_cell` | `CombatCell` | where the unit ends its move (may equal current cell) |
| `target` | `CombatActor` | who to attack from there, or `null` (no attack / retreat) |
| `facing` | `int` | tactical facing direction to attack from (best arc) |
| `score` | `float` | final weighted score |
| `reasons` | `Array[String]` | human-readable contributions for explainability |

### `AiDirective` (`scripts/combat/ai_directive.gd`, `extends RefCounted`)

A commander's instruction to one subordinate. All fields optional; `null`/empty means "no tilt."

| Field | Type | Meaning |
|---|---|---|
| `posture` | `int` (enum `PRESS`, `HOLD`, `HARASS`) | squad-wide stance this round |
| `formation_slot` | `int` (enum `NONE`, `SCREEN`, `FLANK_LEFT`, `FLANK_RIGHT`, `ANCHOR`) | role/position relative to commander or target |
| `focus_target` | `CombatActor` | priority target to concentrate damage on |
| `anchor_cell` | `CombatCell` | reference cell for formation slotting (commander cell or chosen anchor) |

---

## Section 2 — Per-unit scorer (`EnemyTacticalAI`, Phase 1)

Constructed with references to `CombatState` and `CombatGrid`. One public method:

```gdscript
func choose_turn(actor: CombatActor, directive: AiDirective = null) -> AiTurnPlan
```

### Step 1 — Enumerate candidate plans

- Reachable cells from `combat_state.get_reachable_cell_costs(actor)`.
- Bound cost: keep only the cheapest `MAX_CANDIDATE_CELLS` cells (constant, e.g. 24) plus the current cell.
- For each candidate cell, find targets attackable *from that cell* using hypothetical-reach helpers (no actor mutation): mirror `_hypothetical_melee_reachable` / `_hypothetical_ranged_reachable` already in `battle_test_map.gd`. Move those helpers (or equivalents) into the AI so it is self-contained.
- Each (cell, target) pair — and each (cell, no-target) pair — becomes one `AiTurnPlan`. Compute best attack `facing` per plan (the arc that maximizes flank bonus).

### Step 2 — Score considerations (weighted sum)

Every consideration writes a line into `reasons`. Each has an **INT gate**; below the gate its weight is forced to `0.0` (the unit literally cannot value it).

| Consideration | Rewards | INT gate | Source data |
|---|---|---|---|
| `damage` | predicted damage to `target` | always | `combat_state.calculate_damage(actor, target, 0, is_ranged)` |
| `close_distance` | reducing grid distance to best target | always | chebyshev distance delta |
| `flank` | attacking from side/back arc | INT ≥ 3 | `combat_grid.get_attack_arc` + arc bonus |
| `cover` | ending on a cover cell | INT ≥ 4 | `destination_cell.cover_level` |
| `height` | height advantage vs target | INT ≥ 4 | effective height levels |
| `exposure` | **penalty** for ending exposed to living enemies (in their reach/LOS) | INT ≥ 5 | reach/LOS of opposing actors |
| `self_preserve` | safety (distance from threats, cover) when `current_hp / max_hp < retreat_hp_frac` | INT ≥ 5 | HP fraction + threat proximity |

Base weights live in a constant table. Per-archetype overrides come later, keyed on `MonsterSheet.ai_tags`.

### Step 3 — 1-ply counter-threat lookahead (INT ≥ 7)

For the top `LOOKAHEAD_PLAN_COUNT` plans only (e.g. 3): hypothetically place `actor` on `destination_cell`, then for each living opposing actor compute its single best retaliatory plan against `actor` next turn — reusing the same enumeration + `calculate_damage` + flank logic this scorer already has. Define the worst-case incoming threat as the maximum predicted retaliation damage (flank bonus included) across all opponents. Subtract `LOOKAHEAD_WEIGHT * worst_case_damage` from the plan score. Bounded: only a few plans, only 1 ply, no recursion (the retaliation enumeration does NOT itself run lookahead). Below INT 7 this returns `0.0` (the function exists and is gated, not stubbed).

### Step 4 — Directive biases (Phase 2 active; null = no-op)

If `directive != null`, add tilts:
- `focus_target`: extra `damage` weight when `plan.target == directive.focus_target`.
- `formation_slot`: bonus for `destination_cell` near the slot's ideal position relative to `anchor_cell` (e.g. `SCREEN` = between player and anchor; `FLANK_LEFT/RIGHT` = the assigned side of the focus target).
- `posture`: `PRESS` raises aggression (down-weights `exposure`); `HOLD` raises `cover`/`exposure` avoidance and down-weights `close_distance`; `HARASS` favors ranged/chip + maneuver.

Directives are **biases, not overrides** — a high-INT unit whose honest score still rejects the directive (e.g. obeying means death) may pick a different plan.

### Step 5 — Softmax top-k selection

- `temperature = lerp(TEMP_HIGH, TEMP_LOW, clamp(intelligence/10, 0, 1))` (e.g. `TEMP_HIGH=0.8`, `TEMP_LOW=0.05`).
- Softmax over plan scores at that temperature; sample one. High INT → near-deterministic optimal; low INT → frequently a sloppy near-best.
- Determinism for tests: the scorer accepts an optional injected RNG (default a fresh `RandomNumberGenerator`); tests set a fixed seed or `TEMP_LOW≈0` for argmax behavior.

### Explainability

The chosen plan's `reasons` array reads like the document's example:
`"FLANK plan: damage 12 (back arc +20%), cover +2, exposure -3, lookahead safe"`.
Printed to the console now (the existing playtest channel); surfaceable in the debug HUD later.

---

## Section 3 — Intelligence score

`intelligence: int` (1–10) on `MonsterSheet`, surfaced onto `CombatActor` like other synced stats. It is the master dial driving four levers simultaneously:

| Lever | INT 1 (brute) | INT 10 (tactician) | Mechanism |
|---|---|---|---|
| Considerations weighed | damage + close-distance only | full set incl. flank, cover, height, exposure, self-preserve | per-consideration INT gate |
| Decision temperature | high (~0.8, sloppy) | low (~0.05, near-optimal) | `lerp` over INT |
| Self-preservation threshold | ~0% HP (fights to death) | ~40% HP (disengages) | `retreat_hp_frac = lerp(0.0, 0.4, INT/10)` |
| Lookahead | 0-ply | 1-ply counter-threat | gated at INT ≥ 7 |

A commander's own INT scales how good its directives are (Section 4).

---

## Section 4 — Commander layer (`EnemyCommander`, Phase 2)

Runs **once at the start of a commanded unit's turn group**, before subordinates act. Emits only data; never moves anything.

**Who commands:** an actor whose `MonsterSheet.ai_tags` contains `"commander"`. It coordinates living same-faction allies. No commander present → all enemies act solo with `directive = null` (pure Phase 1 behavior).

**Decisions each round:**
1. **Squad posture** (timing principle): read the board for player over-extension (HP, exposure, distance from cover/allies) and pick `PRESS` / `HOLD` / `HARASS`. One posture for the squad that round.
2. **Focus target** (economy of force): designate one priority target (e.g. lowest effective HP or highest threat).
3. **Per-mob directives**: assign each subordinate a `formation_slot` consistent with posture, plus the focus target and an `anchor_cell`. A pincer is two mobs given `FLANK_LEFT` and `FLANK_RIGHT` on the focus target.

**Delivery:** commander writes an `AiDirective` onto each subordinate (e.g. a transient field on `CombatActor`, cleared after the unit's turn). When that mob's turn resolves, `_resolve_enemy_turn` passes its directive into `choose_turn`.

**Commander INT** scales directive quality: low-INT commander issues crude "all attack focus target" calls (posture always `PRESS`, no real formations); high-INT commander reads over-extension and orchestrates genuine pincers and hold-and-bait.

---

## Section 5 — Motion layer changes (`battle_test_map.gd`)

Rewrite `_resolve_enemy_turn(actor)`:

1. If a commander exists and has not yet planned this round, run `EnemyCommander` to populate directives (Phase 2; skipped in Phase 1).
2. Construct `EnemyTacticalAI`, call `choose_turn(actor, actor_directive)`.
3. Execute the returned `AiTurnPlan` via existing motion calls:
   - Move to `destination_cell`. Extract the enemy-relevant parts of the player move path (`set_current_cell`, optional node animation if the enemy node supports `animate_grid_move`, height-CT delay logic) into a shared helper both the player and enemy call, so the AI is not coupled to player input/cursor code. If `destination_cell == current_cell`, call `turn_controller.skip_move()`; otherwise `turn_controller.finish_move()`.
   - Rotate to `plan.facing` (`turn_controller.finish_rotate()`), advancing CT consistently with how the player's actions advance it.
   - If `plan.target`, `combat_state.resolve_attack(...)`, set `_last_action_text`, log reasons.
   - `turn_controller.finish_act()`, `combat_state.end_actor_turn()`, weather roll, `_refresh_battle_ui()`.
4. Print the decision log.

CT/action accounting must mirror the player's flow (move, rotate, attack each advance CT as they do today) so turn order stays fair.

Move `_hypothetical_melee_reachable` / `_hypothetical_ranged_reachable` logic into `EnemyTacticalAI` (or a shared helper) so the AI is self-contained; the move-preview code can call the shared version.

---

## Section 6 — Data model changes

### `MonsterSheet` (`scripts/data/monster_sheet.gd`)
- Add `@export_range(1, 10) var intelligence: int = 5`.
- Add `func get_intelligence() -> int: return clampi(intelligence, 1, 10)`.
- `ai_tags` already exists; `"commander"` is the recognized tag for the squad layer. Archetype weight overrides (later) also key on `ai_tags`.

### `CombatActor` (`scripts/combat/combat_actor.gd`)
- Add `var intelligence: int = 5`.
- In `_sync_stats()`, set `intelligence` from `sheet_resource.get_intelligence()` when available (same guarded pattern as other stats).
- Add a transient `var pending_directive: AiDirective = null` field the commander writes and the motion layer reads/clears.

---

## Section 7 — Deferred hooks (designed, not built)

- **Gemini advisor:** repoint `TacticalAiClient` at `gemini-2.5-flash` via the Generative Language API (`generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent`, key in header `x-goog-api-key`, reusing `TACTICAL_AI_API_KEY`), with `responseMimeType: application/json` + `responseSchema` for structured output. It serializes the board and either re-ranks `choose_turn`'s top-k plans or overrides the commander's posture/focus. Plugs into the existing seam; never touches motion. The stale `grok-2-latest` ping is removed/repointed.
- **Difficulty slider:** a single global `difficulty_scalar` multiplying the INT→temperature and INT→consideration-gate curves. One knob, blocked by nothing in this design.
- **Belief / fog layer:** swap full-board reads for a per-unit belief state (last-seen position, LOS gating). The scorer already isolates "what the AI knows" behind its state reads.
- **Influence maps:** precomputed shared scalar fields (threat, cover, exposure, flank-opportunity) the considerations sample instead of recomputing per plan. A performance/ richness upgrade; the consideration interface is unchanged.

---

## Section 8 — Testing

### Unit tests (offline, no engine) — `EnemyTacticalAI`
Feed handcrafted boards, assert the chosen plan with a fixed RNG seed / near-zero temperature:
- INT 1 brute charges the nearest target, ignores an available flank/cover cell.
- INT 8 tactician picks the back-arc + cover cell over a naive adjacent cell.
- INT 8 at low HP (below retreat threshold) picks a disengage plan with no target.
- INT 8 with lookahead avoids a cell that exposes it to a next-turn kill, even if that cell scores best ignoring lookahead.
- Directive bias: `focus_target` shifts target selection; `FLANK_LEFT/RIGHT` shifts destination to the assigned side; a suicidal directive is overridden by a high-INT unit.

### Unit tests — `EnemyCommander`
- Player over-extended → posture `PRESS`; player strong/covered → `HOLD`.
- Two subordinates → opposite flank slots on the focus target (pincer).
- Low-INT commander → crude all-attack directives; high-INT → real formation.

### Playtest (in-engine, F11/F12 + console decision log)
- Existing 1v1 brigand set to low INT: confirm it charges and attacks (replaces today's stand-still bug).
- Brigand set to high INT: confirm it seeks flank/cover and retreats when low.
- Temporary 1-commander + 2-mob encounter: confirm a called pincer forms and focus-fire concentrates on one target.
- Confirm CT/turn order stays fair (enemy actions advance CT like the player's).

---

## Out of scope (this spec)

- Gemini advisor implementation (hook only).
- Difficulty slider implementation (hook only).
- Belief/fog, influence maps, curse ecology, GOAP planning, offline RL.
- Abilities/spells in AI planning (v1 considers move + basic attack only).
- Player-facing diegetic telegraphs of AI intent (debug-console explainability only for now).
