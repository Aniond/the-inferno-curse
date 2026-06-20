---
name: torch-lights-and-moody-materials
overview: >-
  Add flickering torch OmniLight3D nodes and polish all materials to match the
  dark moody palette (deep golds, shadow blues, warm burnt oranges)
createdAt: '2026-06-20T22:23:59.209Z'
todos:
  - id: update-materials
    content: >-
      Update ground, wall, pillar, and bar materials to deep golds, shadow
      blues, and burnt oranges
    status: completed
  - id: torch-script
    content: >-
      Write torch_light.gd with flickering OmniLight3D and point-light shadow
      casting
    status: completed
  - id: add-torch-lights
    content: Add 4 torch lights to main.tscn walls and wire the torch script
    status: completed
  - id: add-world-environment
    content: Add WorldEnvironment node with dark ambient fog/tone for atmosphere
    status: completed
  - id: verify
    content: >-
      runAndVerify to confirm scene compiles and moody lighting renders
      correctly
    status: completed
---
## Material Palette

- Ground: deep shadow-brown, high roughness, zero metallic
- Walls: dark shadow-blue/grey, high roughness, slight metallic for stone sheen
- Pillars: warm burnt orange-brown, medium roughness
- Bar: deep gold-brown, medium roughness, slight metallic for polished wood

## Torch Lights

- OmniLight3D nodes at 4 wall positions
- Flicker via sin() + noise, warm orange/gold color
- Small range (3-4 units) for intimate tavern feel
- Shadow enabled for dramatic light/shadow contrast

## WorldEnvironment

- Dark ambient sky contribution
- Subtle volumetric fog for depth
- Glow enabled for torch bloom
