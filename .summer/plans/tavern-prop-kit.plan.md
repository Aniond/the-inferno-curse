---
name: tavern-prop-kit
overview: >-
  Generate 4 separate 3D medieval tavern prop meshes (modular floor, modular
  wall, L-shaped bar counter, round table with chairs) via concept-image then
  image-to-3D pipeline. Import into project. No scene placement - user is using
  MCP to place them.
createdAt: '2026-06-21T02:24:21.494Z'
todos:
  - id: concept-images
    content: >-
      Generate 4 concept images (floor, wall, bar counter, table+chairs)
      referencing existing priest/scene aesthetic
    status: completed
  - id: image-to-3d
    content: Convert all 4 concept images to 3D meshes via generate3DFromImage
    status: completed
  - id: import-assets
    content: >-
      Import all 4 completed meshes into res://assets/models/ via importAssets
      batch
    status: completed
  - id: verify-and-handoff
    content: 'Confirm all 4 assets present and report res:// paths to user'
    status: completed
---
## Pipeline
1. Concept images: 4 parallel `generateImage` calls. Single object on neutral background, 3/4 view, warm medieval tavern lighting. Match project palette (deep golds, shadow blues, burnt oranges, dark moody). Use separate images per object (not one composite) so that each image-to-3D produces one clean mesh.
2. Image to 3D: For each concept, `generate3DFromImage` with `meshy-6` for high-fidelity mesh from clean prop concept. Enable PBR maps. Target ~30-60k polys depending on object complexity.
3. Import all 4 GLBs as a single batch via `importAssets`.
4. User explicitly stated they will place them via MCP, so do NOT use callEditorOps or update main.tscn. Only generate the objects and import them so their res:// paths are available.

## Props and key dimensions
- Floor module: 4m x 4m square, dark oak planks, tileable edge geometry.
- Wall section: 4m wide x 3m tall, plaster + timber + wainscot, origin at base.
- Bar counter: L-shape, ~7m long + ~4m return, ~1.1m height, clear L silhouette from 3/4 view.
- Tavern table + chairs: 1.4m diameter round table + 4 round stools, chairs separate meshes within same asset.

## Verification
- Poll each job with `checkGenerationStatus` / `meshyJobStatus` until completed.
- Use `listUserAssets` to confirm all 4 assets exist and get IDs for the import batch.
- Report final res:// paths to user.
