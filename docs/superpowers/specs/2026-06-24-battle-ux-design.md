# Battle UX — Hover Preview & Cover Indicators
**Date:** 2026-06-24  
**Status:** Approved  
**Scope:** `scripts/combat/battle_test_map.gd`, `scripts/combat/battle_overlay.gd`

---

## Problem

The tactical grid combat system has correct mechanics but poor information feedback:

1. During **move phase**, hovering a reachable cell shows nothing — the player cannot see whether they'd be in attack range from that position.
2. During **rotate phase**, the yellow facing wedge shows the player's own facing but doesn't indicate what arc each enemy would be attacked from, making Q/E rotation feel meaningless.
3. **Cover cells** (half/full) have no in-world visual marker — the player can only discover cover reactively when an attack resolves.

---

## Approach

Reuse the existing `_preview_panel` (bottom-right `PanelContainer` in `BattleOverlay`) for all three phases — it already works for attack phase. Extend it to show context-sensitive info in move and rotate phases. Add persistent cover tints to the grid at build time.

No new UI panels. No new scene nodes beyond the cover tile markers.

---

## Section 1 — Move-Phase Preview Panel

### Trigger
Whenever `_hovered_cell` changes during `PlayerTurnPhase.MOVE`, compute a preview and call a new `BattleOverlay` method `update_move_preview(data)`. Clear it when the mouse leaves the grid or hovers an unwalkable cell.

### Content

**Reachable cell:**
```
From here:
  [Enemy name]: melee range ✓  (side flank)
  [Enemy name]: ranged range ✓  (LOS clear)
  MOV cost: 3
```

**Unreachable cell:**
```
Out of reach
```

**Player's current cell:**
Panel stays hidden (no preview on standing cell).

### Computation (in `battle_test_map.gd`)

For each enemy actor alive and on the grid:
- **Melee reachable:** `_hypothetical_melee_reachable(hovered_cell, enemy)` — checks grid distance ≤ 1 and height delta ≤ player jump, without moving any actor.
- **Ranged reachable:** `_hypothetical_ranged_reachable(hovered_cell, enemy)` — checks grid distance ≤ 5 and LOS from `hovered_cell` to enemy cell, without moving any actor.
- **Flank angle:** `TacticalFacing.classify_attack_arc(enemy.get_tactical_facing(), hovered_cell.grid_position - enemy.current_cell.grid_position)` — uses enemy's *current* facing, not player's.

### BattleOverlay API addition

```gdscript
func update_move_preview(data: Dictionary) -> void
func clear_move_preview() -> void
```

`update_move_preview` populates `_preview_panel` with move-phase content. `clear_move_preview` hides it. Both are no-ops if `_preview_panel` is null.

The existing `update_target_preview` / `clear_target_preview` remain unchanged for attack phase. Move and attack phases share the same panel widget but call different update methods.

---

## Section 2 — Rotate-Phase Arc Visualization

### Cell highlights

When `_player_phase == PlayerTurnPhase.ROTATE`, after any Q/E press or on phase entry, replace the current `_clear_highlights()` + `_show_facing_indicator()` calls with a combined `_show_rotate_highlights()` that:

1. Draws the existing yellow facing wedge on the player's cell.
2. For each living enemy, draws a tinted overlay on their cell:
   - **Front arc** → `Color(0.9, 0.25, 0.15, 0.45)` (red — hardest, no flank bonus)
   - **Side arc** → `Color(0.95, 0.75, 0.15, 0.45)` (amber — +10%)
   - **Back arc** → `Color(0.55, 0.15, 0.85, 0.45)` (purple — +20%)

Arc is computed from the player's *current* tactical facing toward each enemy cell using `TacticalFacing.classify_attack_arc`.

### Preview panel

`update_rotate_preview(data)` populates `_preview_panel` with:
```
Facing: North
  [Enemy name]: side flank (+10% hit)
```

Updates live on every Q/E press. Cleared when rotate phase ends.

### BattleOverlay API addition

```gdscript
func update_rotate_preview(data: Dictionary) -> void
func clear_rotate_preview() -> void
```

---

## Section 3 — Cover Cell Indicators

### When

Applied once in `_create_grid_visuals()` (or a new `_create_cover_indicators()` call immediately after `_apply_test_map_tactical_cells()`), after all cover data has been written to cells.

### Visual

A thin flat tile slightly above the grid surface (`y + 0.03`), sized `grid_cell_size * 0.94` on each axis, `height = 0.02`:

| Cover level | Color |
|---|---|
| `CoverLevel.HALF` | `Color(0.75, 0.58, 0.18, 0.35)` — muted gold |
| `CoverLevel.FULL` | `Color(0.28, 0.38, 0.62, 0.45)` — steel blue |

These are **always visible**, dim enough not to compete with movement/attack highlights. They are parented to `_highlight_root` but excluded from `_clear_highlights()` by name tag — give each a group `"cover_indicator"` and skip that group in the clear loop.

### No tooltip

Cover tooltip is already handled in the attack-phase preview panel. No additional hover logic needed here.

---

## Architecture Notes

### No state mutation for hypothetical checks

The move-preview range check must not call `player_actor.set_current_cell()`. Instead, introduce a private helper in `battle_test_map.gd`:

```gdscript
func _hypothetical_melee_reachable(from_cell: CombatCell, target: CombatActor) -> bool
func _hypothetical_ranged_reachable(from_cell: CombatCell, target: CombatActor) -> bool
```

These compute distance/LOS directly from `from_cell` without moving any actor.

### Shared preview panel

`_preview_panel` is phase-multiplexed. The active phase determines which `update_*_preview` / `clear_*_preview` pair is live. Only one phase is active at a time, so there is no conflict. Transition logic:

- Enter move phase → `clear_target_preview()`, then call `update_move_preview` on hover
- Enter rotate phase → `clear_move_preview()`, then call `update_rotate_preview` on entry + Q/E
- Enter attack phase → `clear_rotate_preview()`, then existing `update_target_preview` on hover
- Phase ends → clear the active preview

### `_clear_highlights()` guard

Cover indicators must survive `_clear_highlights()`. Implementation:
```gdscript
func _clear_highlights() -> void:
    for child in _highlight_root.get_children():
        if child == _facing_indicator or child == _grid_cursor:
            continue
        if child.is_in_group("cover_indicator"):
            continue
        child.queue_free()
```

---

## Files Changed

| File | Change |
|---|---|
| `scripts/combat/battle_test_map.gd` | Add `_show_rotate_highlights()`, `_update_move_preview()`, `_update_rotate_preview()`, `_hypothetical_melee_reachable()`, `_hypothetical_ranged_reachable()`, `_create_cover_indicators()`. Hook into phase transitions and `_update_grid_cursor()`. |
| `scripts/combat/battle_overlay.gd` | Add `update_move_preview()`, `clear_move_preview()`, `update_rotate_preview()`, `clear_rotate_preview()`. |

No other files touched.

---

## Out of Scope

- Turn order bar / HP bars above actor heads (separate HUD task)
- Ability/spell system
- Post-combat sync
- Multi-enemy encounters (design works for N enemies; test harness has 1)
