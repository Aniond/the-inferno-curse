---
name: 2d-to-25d-migration
overview: >-
  Migrate 2D tavern to 3D orthographic Octopath-style scene with Camera3D,
  CharacterBody3D player, and Sprite3D billboard animations
createdAt: '2026-06-20T22:12:07.851Z'
todos:
  - id: write-main-scene
    content: >-
      Write new main.tscn with Node3D root, orthographic Camera3D,
      DirectionalLight3D, ground plane, and player skeleton
    status: completed
  - id: write-player-script
    content: >-
      Write player_3d.gd: CharacterBody3D with WASD movement on XZ plane,
      4-direction AnimatedSprite3D billboard, and divine light aura
    status: completed
  - id: write-camera-script
    content: >-
      Write camera_follow.gd: orthographic camera smoothly follows player at
      45-degree isometric angle
    status: completed
  - id: write-walls-and-props
    content: >-
      Add tavern walls, pillars, bar, torches, and scenery as StaticBody3D +
      MeshInstance3D in the scene
    status: completed
  - id: set-main-scene
    content: >-
      Set application/run/main_scene to res://main.tscn and verify input
      bindings
    status: completed
  - id: verify
    content: runAndVerify to confirm scene compiles and renders correctly
    status: completed
---
## Scene structure (res://main.tscn)

```
World (Node3D)
├── Camera3D [orthographic, angled 45 deg down]
├── DirectionalLight3D [angled, shadows enabled]
├── Ground (StaticBody3D)
│   ├── MeshInstance3D [PlaneMesh 30x30, dark wood material]
│   └── CollisionShape3D [BoxShape3D 30x0.1x30]
├── Player (CharacterBody3D)
│   ├── AnimatedSprite3D [billboard, SpriteFrames from Walking/Idle assets]
│   ├── CollisionShape3D [CapsuleShape3D]
│   └── PointLight3D [divine aura]
├── Walls (Node3D)
│   ├── Wall_N/S/E/W (StaticBody3D + MeshInstance3D + CollisionShape3D)
│   ├── Pillar1/2
│   └── Bar
└── Scenery (Node3D)
    ├── House (Sprite3D)
    └── Church (Sprite3D)
```

## Camera
- Orthographic projection (projection=1), size=12
- Follow script positions at player + Vector3(0, 10, 8), rotation_degrees = Vector3(-50, 0, 0)
- Smooth follow via lerp

## Player movement
- CharacterBody3D on XZ plane (no gravity for top-down)
- WASD/arrows move on XZ, direction mapped for sprite facing
- AnimatedSprite3D with billboard (always faces camera)
- Reuses existing Walking/Idle sprite frames, loaded at runtime
- Divine PointLight3D aura (pulses)

## Tavern layout (3D positions, XZ plane)
- Ground: 30x30 at Y=0
- Walls: at X=±14.5 and Z=±14.5
- Player starts at (0,1,0)
- Bar at Z≈-8
- Pillars at X=±5, Z≈-2
- House/Church sprites at X=±10, Z=-12
