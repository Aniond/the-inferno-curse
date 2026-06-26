---
name: limbos-embrace-wiring
overview: >-
  Wire the 4-frame Limbo's Embrace sprite sheet as a playable AnimatedSprite3D
  effect, place a test instance in the tavern, and add a trigger key.
createdAt: '2026-06-25T19:31:55.449Z'
todos:
  - id: effect-script
    content: >-
      Create limbos_embrace_effect.gd following the ClawSlash pattern
      (AtlasTexture regions, 4 frames, play_grab, queue_free on finish)
    status: completed
  - id: add-to-scene
    content: >-
      Add LimboEmbrace AnimatedSprite3D node to main.tscn at a test position
      visible in the tavern
    status: completed
  - id: trigger-key
    content: >-
      Add a test input binding (e.g. key G) and wire it to call play_grab() on
      the effect
    status: completed
  - id: verify
    content: runAndVerify to confirm compilation and visualCheck
    status: completed
---
## Scene hierarchy
- Resuses existing World > Player pattern
- LimboEmbraceGrab: AnimatedSprite3D, billboard=1, pixel_size=0.012, script=limbos_embrace_effect.gd

## Script pattern
- Clone ClawSlash pattern: SpriteFrames built from AtlasTexture regions
- Texture: res://assets/images/limbos_embrace_sprite_sheet.png
- 4 frames, animation name "grab", loop=false
- play_grab() triggers, queue_free on animation_finished

## Trigger
- Bind InputMap "grab_effect" to key G
- In player_3d.gd, add grab test on G press (calls play_grab on the effect instance)
