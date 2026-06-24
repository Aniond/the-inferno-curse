# Implementation Plan: Enemy Tactical AI

**Spec:** `docs/superpowers/specs/2026-06-24-enemy-tactical-ai-design.md`
**Date:** 2026-06-24

Build order: **Phase 1** (per-unit scorer) fully built and verified before **Phase 2** (commander). Each step lists its file(s), the change, and how it's checked. Run `summer_get_script_errors` after every GDScript edit.

---

## PHASE 1 — Per-unit utility scorer

### Step 1 — Data class: `AiTurnPlan`

**File:** `scripts/combat/ai_turn_plan.gd` (new)

`extends RefCounted`, `class_name AiTurnPlan`. Fields with defaults:
- `destination_cell: CombatCell = null`
- `target: CombatActor = null`
- `facing: int = 0` (TacticalFacing direction)
- `score: float = 0.0`
- `reasons: Array[String] = []`

No methods beyond an optional `func describe() -> String` joining `reasons` for logging.

**Check:** script compiles clean.

---

### Step 2 — Data model: intelligence stat

**Files:** `scripts/data/monster_sheet.gd`, `scripts/combat/combat_actor.gd`

`monster_sheet.gd`:
- Add `@export_range(1, 10) var intelligence: int = 5` near `ai_tags`.
- Add `func get_intelligence() -> int: return clampi(intelligence, 1, 10)`.

`combat_actor.gd`:
- Add `var intelligence: int = 5`.
- In `_sync_stats()`, add guarded sync: `if sheet_resource.has_method("get_intelligence"): intelligence = sheet_resource.get_intelligence()`.
- Add `var pending_directive = null` (typed loosely now; `AiDirective` arrives in Phase 2 — use untyped or a forward-safe type to avoid a Phase-1 dependency on a not-yet-existing class).

**Check:** scripts compile; existing `guglielmo_da_siena.tres` and the brigand sheet still load (open main scene, no resource errors).

---

### Step 3 — Shared hypothetical-reach + move helpers

**File:** `scripts/combat/battle_test_map.gd` (refactor, no behavior change yet)

- Confirm `_hypothetical_melee_reachable` / `_hypothetical_ranged_reachable` are pure (no actor mutation). They are — keep them callable; the AI will receive the grid/state and replicate or call equivalent logic. Simplest: make the AI self-contained with its own copies (they are short) to avoid coupling the AI to the battle map. Decision: **duplicate the two small helpers into `EnemyTacticalAI`** so the AI depends only on `CombatState`/`CombatGrid`, not the map node.
- Extract the enemy-relevant move execution into a shared helper `_apply_actor_move(actor, dest_cell)` that does: capture old height, `set_current_cell`, optional `animate_grid_move` if the actor's node supports it, height-CT delay logic. The player path and the AI path both call it. Keep player input/cursor code out of this helper.

**Check:** player turn still moves/animates correctly after the refactor (quick F11 during a player move). No enemy behavior change yet.

---

### Step 4 — `EnemyTacticalAI` core (no lookahead, no directives)

**File:** `scripts/combat/enemy_tactical_ai.gd` (new)

`extends RefCounted`, `class_name EnemyTacticalAI`.
- Constructor / init takes `CombatState` and `CombatGrid` refs and an optional `RandomNumberGenerator`.
- Constants: `MAX_CANDIDATE_CELLS := 24`, `TEMP_HIGH := 0.8`, `TEMP_LOW := 0.05`, base consideration weight table (Dictionary), per-consideration INT-gate table.
- `choose_turn(actor, directive = null) -> AiTurnPlan`:
  1. Enumerate candidate cells (cheapest `MAX_CANDIDATE_CELLS` from `get_reachable_cell_costs` + current cell).
  2. For each cell, find attackable targets via the duplicated hypothetical-reach helpers; build `AiTurnPlan`s (cell × target, plus cell × no-target). Compute best `facing` per (cell,target).
  3. Score each plan: `damage`, `close_distance` (always); `flank`, `cover`, `height`, `exposure`, `self_preserve` gated by `intelligence`. Each contribution appended to `reasons`.
  4. `self_preserve` active only when `current_hp/max_hp < retreat_hp_frac` where `retreat_hp_frac = lerp(0.0, 0.4, int/10)`.
  5. `temperature = lerp(TEMP_HIGH, TEMP_LOW, clamp(int/10,0,1))`; softmax over scores; sample one (injected RNG). Return it.
- Lookahead and directive hooks present as `func _lookahead_penalty(...) -> float: return 0.0` and a `if directive != null` block that's currently a no-op. (Filled in Steps 5–6 / Phase 2.)

**Check:** offline unit test harness (Step 7) — but first a compile check.

---

### Step 5 — 1-ply lookahead

**File:** `scripts/combat/enemy_tactical_ai.gd`

Implement `_lookahead_penalty(actor, plan)`:
- Gate: `if actor.intelligence < 7: return 0.0`.
- Only invoked for the top `LOOKAHEAD_PLAN_COUNT := 3` plans by pre-lookahead score.
- Hypothetically treat `actor` as on `plan.destination_cell`; for each living opposing actor, compute its single best retaliation damage against `actor` next turn (reuse enumeration + `calculate_damage` + flank; NO nested lookahead).
- `worst := max over opponents`; subtract `LOOKAHEAD_WEIGHT * worst` from `plan.score`, append a reason.

**Check:** unit test — a cell that scores best ignoring lookahead but exposes a next-turn kill is rejected by an INT-8 actor, accepted by an INT-5 actor.

---

### Step 6 — Wire AI into the motion layer

**File:** `scripts/combat/battle_test_map.gd`

Rewrite `_resolve_enemy_turn(actor)`:
1. `var ai := EnemyTacticalAI.new(combat_state, combat_grid)`.
2. `var plan := ai.choose_turn(actor, actor.pending_directive)` (directive null in Phase 1).
3. Execute: `_apply_actor_move(actor, plan.destination_cell)`; `skip_move()` vs `finish_move()` by whether the cell changed; rotate to `plan.facing` + `finish_rotate()`; if `plan.target`, `resolve_attack`, set `_last_action_text`; advance CT at each step exactly as the player flow does; `finish_act()`; `end_actor_turn()`; weather roll; `_refresh_battle_ui()`.
4. `print(plan.describe())`.
5. Clear `actor.pending_directive = null`.

**Check (playtest):** F11/F12.
- Brigand sheet `intelligence = 2`: walks toward player and attacks (replaces stand-still).
- Brigand `intelligence = 8`: seeks flank/cover; at low HP, disengages.
- CT/turn order remains fair (enemy doesn't get extra turns).

---

### Step 7 — Offline unit tests for the scorer

**File:** `scripts/combat/tests/test_enemy_tactical_ai.gd` (new) — a headless `SceneTree` script or simple `_run()` invoked via a test scene; match any existing test pattern in the repo (check `tests/` first; if none, a minimal `@tool`-runnable script printing PASS/FAIL).

Cases (fixed RNG seed / `TEMP_LOW`):
- INT 1 charges nearest, ignores flank/cover cell.
- INT 8 picks back-arc + cover cell over naive adjacent.
- INT 8 low-HP picks disengage (no target).
- INT 8 lookahead avoids next-turn kill-box.

**Check:** all cases PASS in console.

**Phase 1 verification gate:** Steps 1–7 green (compile + unit tests + playtest) before starting Phase 2.

---

## PHASE 2 — Commander layer

### Step 8 — Data class: `AiDirective`

**File:** `scripts/combat/ai_directive.gd` (new)

`extends RefCounted`, `class_name AiDirective`. Enums `Posture {PRESS, HOLD, HARASS}`, `Slot {NONE, SCREEN, FLANK_LEFT, FLANK_RIGHT, ANCHOR}`. Fields: `posture`, `formation_slot`, `focus_target: CombatActor`, `anchor_cell: CombatCell`. Retype `CombatActor.pending_directive` to `AiDirective` now that it exists.

**Check:** compiles; Phase 1 still runs (directive stays null for uncommanded enemies).

---

### Step 9 — Directive biases in the scorer

**File:** `scripts/combat/enemy_tactical_ai.gd`

Fill the `if directive != null` block: `focus_target` adds damage weight when `plan.target == focus_target`; `formation_slot` rewards cells near the slot's ideal position relative to `anchor_cell` (SCREEN = between player and anchor; FLANK_LEFT/RIGHT = assigned side of focus target); `posture` shifts exposure/aggression/cover weights. Directives are biases — a high-INT unit can still reject a suicidal one. Append directive reasons.

**Check:** unit tests — `focus_target` shifts target; `FLANK_LEFT/RIGHT` shifts destination; suicidal directive overridden by INT-8 unit.

---

### Step 10 — `EnemyCommander`

**File:** `scripts/combat/enemy_commander.gd` (new)

`extends RefCounted`, `class_name EnemyCommander`. `plan_round(commander_actor, allies, enemies) -> void` (writes `pending_directive` onto each ally):
- Read player over-extension → posture (`PRESS`/`HOLD`/`HARASS`).
- Pick focus target (lowest effective HP / highest threat).
- Assign formation slots consistent with posture; two allies → opposite flanks (pincer); anchor cell = commander's cell.
- Commander INT scales quality (low INT → all-`PRESS`, no real formation).

**Check:** unit tests for `EnemyCommander` (posture by over-extension; pincer slotting; INT scaling).

---

### Step 11 — Wire commander into the turn flow

**File:** `scripts/combat/battle_test_map.gd`

At the start of an enemy turn group (first enemy to act in a round, or when round increments), if a living actor has `"commander"` in its sheet `ai_tags`, run `EnemyCommander.plan_round(...)` once to populate directives. Track a per-round "directives planned" flag so it runs once per round, not per unit. Uncommanded factions: no commander → directives stay null.

**Check (playtest):** temporary 1-commander + 2-mob encounter (add a test spawn). Confirm via F11/F12 + decision log: a called pincer forms, focus-fire concentrates on one target, posture shifts with player exposure.

---

### Step 12 — Phase 2 verification gate

All unit tests green; multi-enemy playtest shows coordinated behavior; lone-enemy behavior (Phase 1) unchanged. Remove the temporary multi-enemy test spawn or gate it behind a debug flag.

---

## Notes / risks

- **CT accounting** is the main correctness risk: the enemy must advance CT through move/rotate/attack exactly as the player does, or turn order desyncs. Mirror the player flow's `advance_ct` calls precisely in Step 6.
- **Self-containment:** AI depends only on `CombatState` + `CombatGrid`, never the map node — keep it that way so it stays unit-testable.
- **Tuning knobs** (INT gates, temperatures, weights, retreat fraction, lookahead weight) are constants in `EnemyTacticalAI` — easy to adjust in playtest. The future difficulty slider multiplies these.
- **Deferred hooks** (Gemini advisor, difficulty slider, belief, influence maps) are not built here; the seams (`choose_turn` return, commander posture) are where they attach.
