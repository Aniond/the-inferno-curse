---
name: inferno-curse-base
overview: >-
  Build the playable foundation for The Inferno Curse: 2D top-down HD-2D-style
  exploration in a medieval Italian setting, with the player character, camera,
  and environment as the first slice.
createdAt: '2026-06-20T18:54:40.911Z'
todos:
  - id: base-scene-skeleton
    content: >-
      Write main.tscn: 2D top-down with Node2D root, Camera2D, player
      CharacterBody2D, and a tile-based medieval ground
    status: completed
  - id: player-movement
    content: >-
      Write player.gd: WASD 8-directional movement with acceleration and
      idle/walk states
    status: completed
  - id: world-tilemap
    content: >-
      Build a small medieval Italian environment: cobblestone ground, walls,
      candlelit interior feel with TileMapLayer
    status: completed
  - id: camera-follow
    content: Wire Camera2D to smoothly follow the player with limits
    status: completed
  - id: input-bindings
    content: 'Bind input actions: move_up/down/left/right, interact, menu'
    status: completed
  - id: run-and-verify
    content: 'runAndVerify the base scene, confirm player moves around the environment'
    status: completed
---
# The Inferno Curse -- Base Foundation

## Architecture
- **2D top-down** RPG exploration (Octopath-style HD 2D aesthetic target)
- **Scene-rooted**: main.tscn is the playable entry point
- **GDScript** for rapid iteration

## Scene Hierarchy (main.tscn)
```
World (Node2D)
  Camera (Camera2D) -- smooth follow, positioned above player
  Ground (TileMapLayer) -- cobblestone/medieval tiles
  Walls (TileMapLayer) -- collision walls, buildings
  Player (CharacterBody2D)
    Sprite2D -- placeholder character
    CollisionShape2D -- circle/capsule
  Decorations (Node2D) -- torches, barrels, mood
```

## Player Controller (player.gd)
- 8-directional WASD movement with acceleration/deceleration
- Idle vs walk state tracking
- Collision with walls via TileMapLayer physics

## Camera
- Smooth follow with some look-ahead
- Camera2D with drag margins for screen-edge push

## Visual Target
- Deep golds, shadow blues, warm burnt oranges
- Dark and moody -- candlelit tavern feel
- Placeholder shapes first, then tile-based art

## Verification
- runAndVerify after each major step
- Player moves with WASD, camera follows, walls block movement
