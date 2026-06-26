# Sanity System Design
*The Inferno Curse — 2026-06-26*

---

## Overview

The sanity system models Guglielmo da Siena's psychological deterioration as he witnesses the supernatural corruption of Hell's circles bleeding into the mortal world. It is CoC-inspired: event-driven, roll-to-resist, and visually expressed through progressive environmental distortion.

**Key separation of concerns:**
- **Sanity** — personal, psychological, belongs to Guglielmo only
- **Corruption** — world-state value, affects NPCs and the environment (separate system)

---

## 1. Core Data

### SanitySheet (Resource)
Attached to Guglielmo's `CharacterSheet`. Not shared with party members.

```
sanity_current: int        # 0–100, starts at 100
sanity_max: int            # 100 (reduced by asylum penalty if taken)
witnessed_events: Array    # Array of event_id strings already seen
perception_skill: int      # Pulled from CoreStats at runtime
```

### SanityEvent (Resource)
Lives in `data/sanity/<circle>/`. One .tres file per event.

```
event_id: String           # Unique identifier e.g. "limbo_forget_spouse"
circle: String             # "limbo", "lust", "gluttony", etc.
description: String        # What Guglielmo witnesses (flavor text)
sanity_cost: int           # Sanity lost on failed roll
roll_difficulty: int       # DC on a d20 roll
trigger_type: String       # "on_enter" | "on_interact" | "on_story_beat" | "on_timer"
```

### Sanity Bands

| Band | Range | Name | State |
|------|-------|------|-------|
| 4 | 75–100 | Stable | No distortion |
| 3 | 50–74 | Unsettled | Subtle desaturation, ambient echo |
| 2 | 25–49 | Fractured | Near-grayscale, NPC name loss, UI flickers |
| 1 | 0–24 | Breaking | Full distortion, manifestations, crisis prompt |

---

## 2. Roll Mechanics

When a `SanityEvent` fires:

### Step 1 — Roll
```
roll = randi_range(1, 20)
modifier = (perception_skill - 10) / 2    # D&D-style ability modifier
repeat_penalty = -2 if event_id in witnessed_events else 0
result = roll + modifier + repeat_penalty
```

**Perception interpretation:** High Perception means Guglielmo can rationalize what he sees — he's less likely to break. But he always *sees* the event regardless. Being perceptive is both a gift and a curse.

**Repeat exposure:** Once an event is witnessed (resisted or not), re-exposure adds -2 to future rolls. The world wears you down even when you're strong.

### Step 2 — Outcome

| Result | Outcome |
|--------|---------|
| `result >= roll_difficulty` | **Resisted.** No sanity loss. Event logged. |
| `result < roll_difficulty` | **Failed.** Sanity decremented by `sanity_cost`. Event logged. |
| Natural 1 (pre-modifier) | Always fail. Sanity cost doubled. |
| Natural 20 (pre-modifier) | Always resist. Brief positive visual flash (colors momentarily vivid). |

### Step 3 — Recovery (flat values, no roll unless noted)

| Source | Sanity Restored | Notes |
|--------|----------------|-------|
| Sleep at inn | +5 | Flat, always |
| Clergy prayer / pray at cross | +8 on success, +3 on fail | Perception roll vs DC 8 |
| Guild reputation tier-up | +10 | Flat, community anchors Guglielmo |

---

## 3. Visual Distortion System

Distortions are driven by a single `sanity_band` shader uniform on `WorldEnvironment`, lerped smoothly between band transitions. Each circle of Hell has its own distortion vocabulary on top of the band system. Florence = Limbo = memory/identity themed.

### Band 4 — Stable (75–100)
No distortions. World appears normal.

### Band 3 — Unsettled (50–74)
- Colors desaturate 20–30%
- NPCs occasionally freeze mid-sentence, then continue as if nothing happened
- Ambient audio gains a faint echo

### Band 2 — Fractured (25–49)
- Colors nearly grayscale
- River water shifts to sickly pale/gray tint
- NPC names appear as "???" in dialogue
- Distant figures flicker out of existence for a frame
- UI elements (HP bars) briefly show wrong values before correcting

### Band 1 — Breaking (0–24)
- Full desaturation
- Ghostly silhouettes of "should-be-there" people walk through walls
- Guglielmo's portrait on UI distorts
- Manifestation events fire (shadowy figures, whispered voices, wrong faces on NPCs)
- **Crisis prompt:** *"Guglielmo can no longer trust what he sees. Seek asylum, or press on?"*

### Crisis Resolution
| Choice | Effect |
|--------|--------|
| Seek asylum | Sanity restored significantly. `sanity_max` permanently reduced (power cost). |
| Press on | Sanity stays at 0. Manifestations continue. Player keeps all power. |

### Future Cities
Each circle of Hell layers its own distortion theme on top of the band system. Limbo = forgetting/fading. Future circles will have their own vocabulary (obsession/repetition, violence/visceral imagery, etc.). The shader and event system stay identical — only content changes.

---

## 4. Architecture

### SanityEventBus (Autoload Singleton)
Single source of truth for all sanity logic.

- Exposes `trigger(event_id: String)` — the only public API scenes need
- Looks up event in `SanityEventLibrary`
- Runs the roll
- Updates `SanitySheet` on `PlayerData`
- Emits `sanity_changed(new_value: int, delta: int)`
- Emits `band_changed(new_band: int)` when band crosses a threshold
- Nothing else performs sanity math

### SanityEventLibrary (Autoload or preloaded dict)
- Dictionary of all `SanityEvent` resources keyed by `event_id`
- Loaded once at startup from `data/sanity/`
- Queried exclusively by `SanityEventBus`

### ShaderController
- Listens to `band_changed` signal from `SanityEventBus`
- Lerps `sanity_band` uniform on `WorldEnvironment` shader
- Handles per-circle distortion overlays

### Trigger Hooks (placed in scene scripts)
| Type | How it fires |
|------|-------------|
| `on_enter` | `Area3D` body_entered → `SanityEventBus.trigger("event_id")` |
| `on_interact` | NPC/object interaction script → `SanityEventBus.trigger("event_id")` |
| `on_story_beat` | Dialogue system calls bus at named story moment |
| `on_timer` | `Timer` node in corrupted zone fires periodically |

### Signal Flow
```
Scene trigger
  → SanityEventBus.trigger(id)
    → roll resolves
    → SanitySheet.sanity_current updated
    → sanity_changed signal → UI updates portrait/bars
    → band_changed signal → ShaderController updates WorldEnvironment
    → band_changed signal → UI updates band-specific overlays
```

---

## 5. Limbo Event Library (Starter Set)

Files live in `data/sanity/limbo/`.

### on_enter (zone-based)

| event_id | Location | What Guglielmo Sees | DC | Cost |
|----------|----------|--------------------|----|------|
| `limbo_npc_forget_name` | Market | A merchant calls his apprentice by three different names in one sentence, confused each time | 10 | 5 |
| `limbo_river_pale` | Ponte Vecchio | The Arno runs colorless, like water over ash | 8 | 4 |
| `limbo_ritual_repeat` | Piazza | The same civic procession passes twice within minutes. No one notices. | 12 | 6 |

### on_interact (NPC conversations)

| event_id | NPC | What Happens | DC | Cost |
|----------|-----|-------------|----|------|
| `limbo_forget_spouse` | Tavern regular | Mid-conversation he forgets his wife's name, searches his hands for a ring that isn't there | 11 | 7 |
| `limbo_wrong_face` | Any NPC | NPC's face briefly becomes someone else's — a dead relative, a stranger | 14 | 9 |

### on_story_beat

| event_id | Beat | What Happens | DC | Cost |
|----------|------|-------------|----|------|
| `limbo_dante_echo` | First cathedral visit | Guglielmo hears his own name spoken in a voice that isn't there | 13 | 8 |

### on_timer (ambient, fires every ~4 minutes in corrupted zones)

| event_id | What Happens | DC | Cost |
|----------|--------------|----|------|
| `limbo_ambient_fade` | World color briefly drains for 2 seconds then returns | 7 | 3 |

---

## 6. File Layout

```
autoload/
  sanity_event_bus.gd        # Singleton — all roll logic and signals
  sanity_event_library.gd    # Loads and caches all SanityEvent resources

scripts/data/
  sanity_sheet.gd            # Resource class — current/max sanity, witnessed_events
  sanity_event.gd            # Resource class — event definition

data/sanity/
  limbo/
    limbo_npc_forget_name.tres
    limbo_river_pale.tres
    limbo_ritual_repeat.tres
    limbo_forget_spouse.tres
    limbo_wrong_face.tres
    limbo_dante_echo.tres
    limbo_ambient_fade.tres

scripts/ui/
  sanity_shader_controller.gd   # Listens to band_changed, drives WorldEnvironment uniform
```

---

## 7. Out of Scope (this spec)

- Corruption system (world-state, NPCs) — separate design
- Per-NPC sanity responses
- Multiplayer sanity sync
- Sanity-gated dialogue branches (future feature)
- Additional circle distortion vocabularies (authored per city as built)
