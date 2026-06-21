---
name: character-sheet-wiring
overview: >-
  Build PlayerData autoload + character sheet UI scene that populates the status
  screen template with real character data, toggles with C key.
createdAt: '2026-06-21T22:34:17.465Z'
todos:
  - id: player-data-autoload
    content: >-
      Create PlayerData autoload with all character stats, signals, and default
      priest values
    status: completed
  - id: character-sheet-scene
    content: >-
      Create character sheet UI scene (CanvasLayer + TextureRect + positioned
      labels) and script
    status: completed
  - id: register-autoload
    content: Register PlayerData autoload in project.godot
    status: completed
  - id: verify
    content: 'Run the game and verify character sheet opens with C key, displays data'
    status: completed
---
## Architecture

### PlayerData (autoload `res://autoload/player_data.gd`)
Singleton holding all character stats. Exposes signals for UI binding.
- Name, title, level, exp
- HP/MP/CT (current + max)
- 12 attributes: STR, SPD, INT, FTH, ATK, DEF, CRT, PRS, POW, MOV, JMP, DEF(2)
- 6 elemental resistances: Physical, Fire, Ice, Thunder, Holy, Dark
- Abilities array with AT cost and C-EV

### Character Sheet UI (`res://scenes/ui/character_sheet_ui.tscn` + `res://scripts/ui/character_sheet_ui.gd`)
CanvasLayer-based overlay. Press C to toggle.
- ColorRect dark overlay on toggle
- TextureRect with the background PNG, scaled to fit viewport, centered
- Labels + gauge fill ColorRects positioned as fractions of TextureRect size
- Reads all values from PlayerData autoload

### Positioning strategy
Background image is 1536x1024. All label positions are stored as fractions of (1536, 1024).
In _ready(), calculate the actual offset based on TextureRect's displayed size.
This handles any viewport resolution / aspect ratio automatically.

### Key positions (fractional, 0-1 within the image)
- Left page: x 0.0-0.5
- Right page: x 0.5-1.0
- Portrait frame: x=0.04-0.18, y=0.06-0.28
- Resource labels: Lv/Exp/Hp/Mp/CT at x~0.22, y spaced
- Gauge bars: x=0.28-0.42
- Attribute matrix Col A: x=0.05, Col B: x=0.30, rows y=0.42-0.78
- Info panel: x=0.53-0.94, y=0.06-0.44
- Abilities: x=0.53, y=0.50-0.78
- Elemental strip: x=0.92-0.97, rows y=0.12-0.82
