# Sanity System — Implementation Plan
*The Inferno Curse — 2026-06-26*

Reference spec: `docs/superpowers/specs/2026-06-26-sanity-system-design.md`

---

## Phase 1: Data Layer

### Step 1 — `SanitySheet` resource class
**File:** `scripts/data/sanity_sheet.gd`
- Extends `Resource`
- Fields: `sanity_current`, `sanity_max`, `witnessed_events`, `perception_skill`
- Method: `get_band() -> int` — returns 1–4 based on `sanity_current`
- Method: `apply_delta(delta: int)` — clamps to 0–`sanity_max`, returns new value

### Step 2 — `SanityEvent` resource class
**File:** `scripts/data/sanity_event.gd`
- Extends `Resource`
- Fields: `event_id`, `circle`, `description`, `sanity_cost`, `roll_difficulty`, `trigger_type`

### Step 3 — Attach `SanitySheet` to `CharacterSheet`
**File:** `scripts/data/character_sheet.gd`
- Add `@export var sanity: SanitySheet` field
- Update `data/characters/guglielmo_da_siena.tres` to include a SanitySheet with `sanity_current = 100`

---

## Phase 2: Event Library

### Step 4 — Author 7 Limbo SanityEvent .tres files
**Directory:** `data/sanity/limbo/`

| File | event_id | DC | Cost | trigger_type |
|------|----------|----|------|-------------|
| `limbo_npc_forget_name.tres` | limbo_npc_forget_name | 10 | 5 | on_enter |
| `limbo_river_pale.tres` | limbo_river_pale | 8 | 4 | on_enter |
| `limbo_ritual_repeat.tres` | limbo_ritual_repeat | 12 | 6 | on_enter |
| `limbo_forget_spouse.tres` | limbo_forget_spouse | 11 | 7 | on_interact |
| `limbo_wrong_face.tres` | limbo_wrong_face | 14 | 9 | on_interact |
| `limbo_dante_echo.tres` | limbo_dante_echo | 13 | 8 | on_story_beat |
| `limbo_ambient_fade.tres` | limbo_ambient_fade | 7 | 3 | on_timer |

### Step 5 — `SanityEventLibrary` autoload
**File:** `autoload/sanity_event_library.gd`
- On `_ready`: recursively load all `.tres` files under `data/sanity/`
- Store in `Dictionary` keyed by `event_id`
- Expose `get_event(id: String) -> SanityEvent`

---

## Phase 3: Core Logic

### Step 6 — `SanityEventBus` autoload
**File:** `autoload/sanity_event_bus.gd`

Signals:
```gdscript
signal sanity_changed(new_value: int, delta: int)
signal band_changed(new_band: int)
```

Method: `trigger(event_id: String)`
1. Fetch event from `SanityEventLibrary`
2. Get `SanitySheet` from `PlayerData`
3. Check repeat penalty (`-2` if already in `witnessed_events`)
4. Roll: `randi_range(1, 20) + modifier + repeat_penalty`
5. Compare vs `roll_difficulty`
6. Apply sanity delta (double on natural 1, skip on natural 20)
7. Log `event_id` to `witnessed_events`
8. Emit `sanity_changed`
9. If band changed, emit `band_changed`

Method: `recover(source: String)` — handles inn/clergy/guild recovery
- `"inn"` → flat +5
- `"clergy"` → roll Perception vs DC 8, +8 or +3
- `"guild"` → flat +10

Register in `project.godot` autoloads after `SanityEventLibrary`.

---

## Phase 4: Visual Distortion

### Step 7 — WorldEnvironment shader uniform
**File:** `scripts/ui/sanity_shader_controller.gd`
- On `_ready`: connect to `SanityEventBus.band_changed`
- On `band_changed(new_band)`: tween `sanity_band` uniform on `WorldEnvironment`
  - Band 4 → 0.0 (no distortion)
  - Band 3 → 0.33
  - Band 2 → 0.66
  - Band 1 → 1.0
- Wire to main scene's `WorldEnvironment` node

### Step 8 — Desaturation shader on WorldEnvironment
**File:** `materials/sanity_distortion.gdshader` (or environment post-process)
- Single `uniform float sanity_band` (0.0–1.0)
- At 0.0: no effect
- At 0.33: 25% desaturation
- At 0.66: 80% desaturation + subtle color tint (pale/gray)
- At 1.0: full desaturation + ghostly overlay

*Note: Manifestation VFX at Band 1 (ghostly silhouettes, wrong faces) are separate scene instancing — authored in a follow-up pass.*

---

## Phase 5: Scene Triggers

### Step 9 — Example trigger placements in main.tscn
Wire up 2–3 Limbo events to verify the full pipeline:

1. **`limbo_ambient_fade`** — Add a `Timer` node to main scene, 240s interval, calls `SanityEventBus.trigger("limbo_ambient_fade")`
2. **`limbo_river_pale`** — Add `Area3D` trigger zone near the Ponte Vecchio node; `body_entered` calls the bus
3. **`limbo_dante_echo`** — Hook into cathedral story beat (or a placeholder button for testing)

### Step 10 — Recovery hookups
- Inn rest action → calls `SanityEventBus.recover("inn")`
- Placeholder test button in main scene for verifying recovery math

---

## Phase 6: Crisis UI

### Step 11 — Breaking band crisis prompt
**File:** `scripts/ui/sanity_crisis_ui.gd` + `scenes/ui/sanity_crisis_ui.tscn`
- Shown when `band_changed` emits band = 1
- Two buttons: "Seek Asylum" / "Press On"
- Seek Asylum: restore sanity to 50, reduce `sanity_max` by 20 permanently
- Press On: dismiss, no change

---

## Phase 7: Register & Test

### Step 12 — Register autoloads in project.godot
Order:
1. `SanityEventLibrary` (loads resources)
2. `SanityEventBus` (depends on library + PlayerData)

### Step 13 — Smoke test checklist
- [ ] `SanityEventBus.trigger("limbo_ambient_fade")` fires and sanity decrements
- [ ] Natural 20 fires and colors briefly vivify
- [ ] Band 3 desaturates the world
- [ ] Band 1 shows crisis prompt
- [ ] "Seek Asylum" restores sanity and reduces `sanity_max`
- [ ] Inn recovery adds +5
- [ ] Repeat exposure applies -2 penalty

---

## Implementation Order Summary

| # | Task | File(s) |
|---|------|---------|
| 1 | SanitySheet resource | `scripts/data/sanity_sheet.gd` |
| 2 | SanityEvent resource | `scripts/data/sanity_event.gd` |
| 3 | Attach to CharacterSheet | `character_sheet.gd`, `guglielmo_da_siena.tres` |
| 4 | Author 7 .tres events | `data/sanity/limbo/*.tres` |
| 5 | SanityEventLibrary autoload | `autoload/sanity_event_library.gd` |
| 6 | SanityEventBus autoload | `autoload/sanity_event_bus.gd` |
| 7 | ShaderController | `scripts/ui/sanity_shader_controller.gd` |
| 8 | Desaturation shader | `materials/sanity_distortion.gdshader` |
| 9 | Scene trigger placements | `scenes/main.tscn` |
| 10 | Recovery hookups | `scenes/main.tscn` |
| 11 | Crisis UI | `scripts/ui/sanity_crisis_ui.gd` + `.tscn` |
| 12 | Register autoloads | `project.godot` |
| 13 | Smoke test | — |
