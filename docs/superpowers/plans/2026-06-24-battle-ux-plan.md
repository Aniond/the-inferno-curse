# Implementation Plan: Battle UX — Hover Preview & Cover Indicators
**Spec:** `docs/superpowers/specs/2026-06-24-battle-ux-design.md`  
**Date:** 2026-06-24

---

## Files to change

- `scripts/combat/battle_overlay.gd`
- `scripts/combat/battle_test_map.gd`

---

## Step 1 — Add preview methods to BattleOverlay

**File:** `scripts/combat/battle_overlay.gd`

Add four new public methods after `clear_target_preview()`:

### 1a. `update_move_preview(data: Dictionary) -> void`

Populates `_preview_panel` with move-phase content. `data` keys:
- `"reachable": bool` — false shows "Out of reach" in muted style
- `"move_cost": int`
- `"targets": Array[Dictionary]` — each entry has `"name": String`, `"melee": bool`, `"ranged": bool`, `"arc_label": String`

Builds BBCode string and sets `_preview_panel.visible = true`.

### 1b. `clear_move_preview() -> void`

Hides `_preview_panel`, clears `_preview_body.text`.

### 1c. `update_rotate_preview(data: Dictionary) -> void`

Populates `_preview_panel` with rotate-phase content. `data` keys:
- `"facing": String` — e.g. "north"
- `"targets": Array[Dictionary]` — each entry has `"name": String`, `"arc_label": String`, `"arc_bonus": int`

### 1d. `clear_rotate_preview() -> void`

Hides `_preview_panel`, clears content.

**Preview title** for each phase:
- Move: `"Move Preview"`
- Rotate: `"Facing Preview"`
- Attack: `"Target Preview"` (unchanged)

---

## Step 2 — Cover cell indicators

**File:** `scripts/combat/battle_test_map.gd`

### 2a. Add `_create_cover_indicators() -> void`

Call this at the end of `_ensure_tactical_grid_ready()`, after `_apply_test_map_tactical_cells()` and `_create_test_cover_volumes()`.

Iterates all cells in `combat_grid.cells`. For each cell where `cover_level != CombatCell.CoverLevel.NONE`:
- Creates a `MeshInstance3D` with a flat `BoxMesh` (`size = Vector3(grid_cell_size * 0.94, 0.02, grid_cell_size * 0.94)`)
- Half cover: `Color(0.75, 0.58, 0.18, 0.35)`
- Full cover: `Color(0.28, 0.38, 0.62, 0.45)`
- Position: `_cell_world_position(cell) + Vector3(0, 0.03, 0)`
- Add to group `"cover_indicator"`
- Parent to `_highlight_root`

### 2b. Guard `_clear_highlights()` against cover indicators

Add group check:
```gdscript
if child.is_in_group("cover_indicator"):
    continue
```
after the existing `_facing_indicator` / `_grid_cursor` guards.

---

## Step 3 — Move-phase hover preview

**File:** `scripts/combat/battle_test_map.gd`

### 3a. Add `_hypothetical_melee_reachable(from_cell: CombatCell, target: CombatActor) -> bool`

```
var dist := max(abs(from_cell.grid_position.x - target.current_cell.grid_position.x),
                abs(from_cell.grid_position.y - target.current_cell.grid_position.y))
var h_delta := abs(from_cell.get_effective_height_level() - target.current_cell.get_effective_height_level())
return dist <= 1 and h_delta <= player_actor.jump
```

### 3b. Add `_hypothetical_ranged_reachable(from_cell: CombatCell, target: CombatActor) -> bool`

```
var dist := max(abs(...))  # same chebyshev distance
return dist <= 5 and combat_grid.is_grid_line_of_sight_clear(from_cell, target.current_cell, true)
```

### 3c. Add `_build_move_preview(cell: CombatCell) -> Dictionary`

Returns data dict for `update_move_preview`. Loops over `actors` where `faction == "enemy"` and `is_alive()`. For each:
- Calls `_hypothetical_melee_reachable` and `_hypothetical_ranged_reachable`
- Computes arc label via `TacticalFacing.classify_attack_arc` using enemy's current facing and `cell.grid_position - enemy.current_cell.grid_position`
- Converts arc int to label string (same map as `TacticalFacing.arc_label`)

### 3d. Hook into `_update_grid_cursor()`

After updating cursor color, add:

```gdscript
if _player_phase == PlayerTurnPhase.MOVE:
    if _hovered_cell == null or _hovered_cell == player_actor.current_cell:
        _battle_overlay.clear_move_preview()
    elif _reachable_cells.has(_hovered_cell):
        _battle_overlay.update_move_preview(_build_move_preview(_hovered_cell))
    else:
        _battle_overlay.update_move_preview({"reachable": false})
```

### 3e. Clear on phase transitions

- In `_begin_player_rotate_phase()`: call `_battle_overlay.clear_move_preview()`
- In `_finish_player_turn()`: call `_battle_overlay.clear_move_preview()`

---

## Step 4 — Rotate-phase arc visualization

**File:** `scripts/combat/battle_test_map.gd`

### 4a. Replace `_show_facing_indicator()` calls in rotate phase with `_show_rotate_highlights()`

`_show_rotate_highlights()`:
1. Calls `_clear_highlights()` (cover indicators survive per Step 2b)
2. Redraws the yellow facing wedge (copy existing `_show_facing_indicator()` logic inline or keep as separate call)
3. For each living enemy actor:
   - Computes `TacticalFacing.classify_attack_arc(player_actor.get_tactical_facing(), enemy.current_cell.grid_position - player_actor.current_cell.grid_position)`
   - Draws a tinted flat tile on enemy's cell:
     - Front: `Color(0.9, 0.25, 0.15, 0.45)`
     - Side (left or right): `Color(0.95, 0.75, 0.15, 0.45)`
     - Back: `Color(0.55, 0.15, 0.85, 0.45)`
   - Does NOT add these to `"cover_indicator"` group (they should be cleared on phase end)

### 4b. Add `_build_rotate_preview() -> Dictionary`

Builds data dict for `update_rotate_preview`. Loops enemies, computes arc and bonus:
- Front: 0%, Side: +10%, Back: +20%

### 4c. Hook into rotate phase

- In `_begin_player_rotate_phase()`: call `_show_rotate_highlights()` + `_battle_overlay.update_rotate_preview(_build_rotate_preview())`
- In `_player_rotate()`: same two calls after updating facing
- In `_player_confirm_rotate()` and `_player_skip_rotate()`: call `_battle_overlay.clear_rotate_preview()`

---

## Step 5 — Phase cleanup audit

Verify all phase transitions clear the correct preview:

| Transition | Clear |
|---|---|
| Move → Rotate | `clear_move_preview()` |
| Rotate → Attack | `clear_rotate_preview()` |
| Attack → end of turn | `clear_target_preview()` (already exists) |
| Enemy turn starts | `clear_move_preview()`, `clear_rotate_preview()`, `clear_target_preview()` in `_on_actor_turn_started()` |
| Encounter ends | same three clears in `_on_encounter_ended()` |

---

## Step 6 — Playtest

Run the game, trigger combat, verify:

- [ ] Move phase: hover reachable cell shows enemy name + range indicators + MOV cost
- [ ] Move phase: hover unreachable cell shows "Out of reach"
- [ ] Move phase: hover player's own cell hides panel
- [ ] Rotate phase: Q/E updates arc colors on enemy cells live
- [ ] Rotate phase: preview panel shows facing + arc bonus
- [ ] Cover cells: gold/blue tints visible on tables and bar counter from combat start
- [ ] Cover indicators survive `_clear_highlights()` during all phase transitions
- [ ] No preview panel bleed between phases (attack preview doesn't show during move phase etc.)
