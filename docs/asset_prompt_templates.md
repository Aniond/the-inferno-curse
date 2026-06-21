# Asset Prompt Templates

## Medieval Italian Townhouse

Use this prompt for Summer 3D asset generation:

```text
Create a game-ready 3D model of a narrow medieval Italian townhouse from the mid-13th to 14th century, Gothic/Romanesque transition, suitable for a high-end RPG game engine.

Architecture:
- Narrow multi-story urban residence, roughly 3 stories tall.
- Rough-hewn Tuscan limestone mixed with weathered red brickwork.
- Lower level has a sturdy round Romanesque archway for a storefront or workshop entrance.
- Upper floors have biforate windows: paired Gothic/Romanesque arched windows divided by slender marble columns.
- Add dark distressed chestnut wood doors, shutters, beams, and trim.
- Top floor includes a small practical balcony on heavy stone or wooden corbels.
- Shallow terracotta barrel-tile roof with aged coppi tiles, mild moss, chipped edges, and uneven historical wear.

Materials:
- PBR materials with coarse stone, mortar, weathered brick, cracked stucco patches, terracotta roof tiles, aged marble, and dark distressed wood.
- Add grime streaks below windowsills, ambient dirt in crevices, erosion around stone edges, and subtle damp staining near the base.
- Do not bake strong directional lighting into the textures.

Game asset requirements:
- Standalone architectural prop.
- Real 3D geometry, not a flat facade.
- Clean topology suitable for a game engine.
- Reasonable polycount for a hero environment asset.
- Correct real-world scale for a medieval townhouse.
- Origin centered at ground level.
- Include separate material slots for stone, brick, stucco, wood, roof tile, and marble.
- No characters, no street, no skybox, no decorative background.

Presentation:
- Isolated on a neutral background.
- 3/4 isometric preview angle.
- Warm late-afternoon Mediterranean lighting only for preview.
```

## Medieval Italian Blacksmith Shop

Use this prompt for Summer 3D asset generation:

```text
Create a game-ready 3D model of a medieval Italian blacksmith shop from the mid-13th to 14th century, suitable for a high-end RPG game engine with a dark historical HD-2D / 3D HD visual style.

Architecture:
- Small urban workshop built into a narrow medieval street frontage.
- Rough Tuscan limestone foundation with weathered brick and cracked stucco upper walls.
- Large open Romanesque stone arch at street level, revealing a recessed forge/workshop bay.
- Heavy dark chestnut wood beams frame the storefront opening.
- Add a soot-darkened chimney stack or forge vent rising along one side of the building.
- Upper floor is a modest residence or storage loft with small biforate or arched windows.
- Include simple wooden shutters, iron hinges, and a worn hanging sign bracket without readable text.
- Shallow terracotta barrel-tile roof with uneven coppi tiles, chipped edges, and mild moss growth.

Workshop Details:
- Visible stone forge set into the rear or side wall.
- Add an anvil, quenching barrel, stacked firewood or charcoal sacks, tool rack, iron tongs, hammers, horseshoes, unfinished blades, and metal bars.
- Include soot stains around the forge, heat discoloration on nearby stone, and scattered ash or coal dust on the floor.
- Keep props historically grounded and practical, not fantasy oversized.

Materials:
- PBR materials with rough limestone, old brick, cracked stucco, dark distressed wood, blackened iron, ash, charcoal, and terracotta roof tile.
- Add grime streaks, soot buildup, chipped stone edges, worn threshold stones, oxidized metal, and dirt collected in crevices.
- Do not bake strong directional lighting into the textures.

Game asset requirements:
- Standalone architectural prop with readable interior workshop depth.
- Real 3D geometry, not a flat facade.
- Clean topology suitable for a game engine.
- Reasonable polycount for a hero environment asset.
- Correct real-world scale for a medieval urban workshop.
- Origin centered at ground level.
- Include separate material slots for stone, brick, stucco, wood, roof tile, iron, soot/ash, and forge stone.
- No characters, no street, no skybox, no decorative background.
- Avoid modern tools, modern signage, fantasy weapons, glowing magic effects, or exaggerated cartoon proportions.

Presentation:
- Isolated on a neutral background.
- 3/4 isometric preview angle showing the storefront opening and forge depth.
- Warm late-afternoon Mediterranean lighting for preview, with subtle forge warmth only as a lighting suggestion.
```

## Medieval Tavern Interior Kit

Use these prompts for Summer 3D asset generation. Generate these as separate assets when possible so we can resize and place them cleanly inside the room.

Target output paths:

| Asset | Path |
| --- | --- |
| Modular wood floor (4x4m) | `res://assets/models/tavern_floor_4x4.glb` |
| Floor corner module (4x4m) | `res://assets/models/tavern_floor_corner_4x4.glb` |
| Modular wall panel (4x3m) | `res://assets/models/tavern_wall_4x3.glb` |
| L-shaped bar counter (7m + 4m) | `res://assets/models/tavern_bar_counter_l_shape.glb` |
| Round table + 4 stools (1.4m) | `res://assets/models/tavern_table_and_stools.glb` |
| Single stool (standalone) | `res://assets/models/tavern_single_stool.glb` |

Combined Summer prompt:

```text
Create a game-ready 3D medieval tavern interior prop kit for a dark fantasy HD-2D / 3D HD RPG.

Generate these as separate objects within one asset pack if possible:

1. Modular wood floor
- Export target: res://assets/models/tavern_floor_4x4.glb
- Square 4m x 4m floor module.
- Wide, uneven, hand-planed dark oak planks.
- Slight plank height variation, beveled edges, seams, peg holes, scratches, stains, worn paths, and dirt in gaps.
- Must tile cleanly with adjacent modules.
- Real 3D geometry, not a flat image plane.

2. Floor corner module
- Export target: res://assets/models/tavern_floor_corner_4x4.glb
- Square 4m x 4m matching corner floor module.
- Same plank scale, material, wear, color, and height profile as the modular wood floor.
- Include subtle edge/corner wear for room corners while still aligning cleanly to the main floor module.
- Real 3D geometry, not a flat image plane.

3. Modular wall panel
- Export target: res://assets/models/tavern_wall_4x3.glb
- 4m wide x 3m tall wall section.
- Aged rough plaster, dark oak timber framing, and lower wood wainscoting.
- Cracks, repairs, soot, grime, exposed old stone or brick patches, water stains, nail heads, and smoke darkening.
- Shallow-relief geometry for beams and boards.
- Origin at floor contact line.

4. L-shaped bartender counter
- Export target: res://assets/models/tavern_bar_counter_l_shape.glb
- Heavy dark oak bar counter with long side about 7m, short return about 4m, counter height about 1.1m.
- Thick posts, peg joinery, iron straps, worn countertop, shelves, cubbies, foot rail, hooks, and space for mugs or bottles.
- Clear readable L-shaped silhouette from a 3/4 isometric camera.
- No modern bar taps, neon bottles, or readable labels.

5. Round table and stools
- Export target: res://assets/models/tavern_table_and_stools.glb
- One sturdy round dark-oak tavern table with four matching round stools or simple round-backed chairs.
- Table diameter about 1.4m, height about 0.75m, human-scale seats.
- Thick legs, cross braces, peg joinery, worn edges, scratches, dents, stains, cup rings, and knife marks.
- Chairs/stools should be separate mesh parts within the same asset if possible.

6. Single standalone stool
- Export target: res://assets/models/tavern_single_stool.glb
- One matching standalone dark-oak tavern stool.
- Human-scale, sturdy, round seat, thick legs, cross braces, peg joinery, worn edges, scratches, dents, and grime in joints.
- Must visually match the stools from the table set.

Materials:
- PBR dark aged oak, aged plaster, rough stone/brick patches, iron, grime, soot, stains, and worn edges.
- Use separate material slots for wood, plaster, stone/brick, iron, grime/stains.
- Do not bake strong directional lighting into textures.

Game asset requirements:
- Real 3D meshes with usable scale and clean topology.
- Origins placed sensibly for each object.
- Modular pieces should tile or align cleanly.
- Suitable for placement inside a rectangular tavern room.
- No characters, no exterior building, no full room shell, no fantasy glowing effects, no modern furniture, no food clutter unless minimal and removable.

Presentation:
- Isolated on a neutral background.
- 3/4 isometric preview angle.
- Warm medieval tavern lighting for preview only.
```

### Wood Flooring Module

```text
Create a game-ready 3D modular medieval tavern wood flooring asset for a dark fantasy HD-2D / 3D HD RPG.

Asset:
- Square floor module made from wide, uneven, hand-planed dark oak planks.
- Slight plank height variation, beveled edges, visible seams, peg holes, cuts, scratches, stains, and age.
- Subtle dirt in plank gaps and worn paths where people walk.
- Designed to tile cleanly with adjacent floor modules in a rectangular tavern room.

Materials:
- PBR dark oak wood with roughness variation, normal detail, dirt in crevices, and old tavern wear.
- No glossy modern varnish, no polished palace floor, no fantasy glowing effects.
- Do not bake strong directional lighting into the texture.

Game asset requirements:
- Real 3D geometry with slight plank relief, not a flat image plane.
- Low-to-mid poly modular environment piece.
- Origin centered at ground level.
- Scale target: 4m x 4m module, thin height suitable for placement over the existing floor.
- Seamless edges for tiling.
- Separate material slot for wood.
- No walls, furniture, props, characters, or background.

Presentation:
- Isolated on a neutral background.
- 3/4 isometric preview angle.
- Warm tavern lighting only for preview.
```

### Wall Covering Module

```text
Create a game-ready 3D medieval tavern interior wall-covering module for a dark fantasy HD-2D / 3D HD RPG.

Asset:
- Interior wall section sized for a tavern room, combining rough plaster, dark timber framing, and lower wood wainscoting.
- Aged off-white to smoke-stained gray plaster with cracks, repairs, soot, grime, and exposed patches of old stone or brick.
- Dark oak beams, simple vertical supports, and worn lower boards to protect the wall from chairs and foot traffic.
- Subtle nail heads, water stains near the lower edge, and smoke darkening near the top.

Materials:
- PBR aged plaster, dark oak timber, rough stone or brick patches, soot, and grime masks.
- No wallpaper, no modern paint, no bright clean surfaces, no readable signs.
- Do not bake strong directional lighting into the texture.

Game asset requirements:
- Standalone modular wall covering, intended to sit against the existing room walls.
- Real geometry with shallow relief for beams and wainscoting.
- Origin centered at floor contact line.
- Scale target: 4m wide x 3m tall wall module, thin depth.
- Clean tileable side edges for repeated wall segments.
- Separate material slots for plaster, timber, stone/brick, and grime.
- No furniture, no characters, no exterior facade, no background.

Presentation:
- Isolated on a neutral background.
- 3/4 isometric preview angle.
- Warm tavern lighting only for preview.
```

### L-Shaped Bartender Counter

```text
Create a game-ready 3D L-shaped medieval tavern bartender counter for a dark fantasy HD-2D / 3D HD RPG.

Asset:
- Sturdy L-shaped bar counter that can fit a medium rectangular tavern room.
- Heavy dark oak planks, thick posts, iron straps, peg joinery, and a worn countertop.
- Long side serves patrons; short return creates an L shape for a bartender work area.
- Under-counter shelves, small cubbies, a foot rail, a few hooks, and space for mugs or bottles without overcrowding.
- Clear readable silhouette from a 3/4 isometric camera.

Materials:
- PBR dark aged oak, worn edge highlights, iron bands, dirt in seams, scratches, spills, cup rings, and subtle grime.
- Historically grounded medieval construction, no modern bar taps, no glass neon bottles, no readable labels.
- Do not bake strong directional lighting into the texture.

Game asset requirements:
- Standalone static 3D prop with real depth and underside details.
- Origin centered at floor level near the inside corner of the L for easy placement.
- Scale target: long side about 7m, short side about 4m, counter height about 1.1m.
- Clean topology suitable for a game engine.
- Separate material slots for wood, iron, and grime/spills.
- No bartender, no characters, no surrounding room, no background.

Presentation:
- Isolated on a neutral background.
- 3/4 isometric preview angle showing the L shape clearly.
- Warm tavern lighting only for preview.
```

### Tavern Table And Round Chairs Set

```text
Create a game-ready 3D medieval tavern dining set for a dark fantasy HD-2D / 3D HD RPG.

Asset:
- One sturdy round wooden tavern table with four matching round stools or round-backed simple chairs.
- Dark oak construction with thick legs, cross braces, peg joinery, and worn edges.
- Table surface has scratches, dents, stains, cup rings, knife marks, and small unevenness.
- Chairs or stools fit naturally around the table without clipping and read clearly from a 3/4 isometric camera.

Materials:
- PBR dark aged oak, rough wood grain, worn edges, grime in joints, and old tavern stains.
- Optional simple iron nail heads or straps, but keep it historically grounded.
- No modern chairs, no cushions, no ornate palace furniture, no fantasy oversized proportions.
- Do not bake strong directional lighting into the texture.

Game asset requirements:
- Static 3D prop set intended for room dressing.
- Origin centered at floor level under the table center.
- Scale target: table diameter about 1.4m, table height about 0.75m, seats human-scale.
- Chairs or stools can be separate mesh parts within the same asset so we can later split or hide them if needed.
- Clean topology suitable for a game engine.
- Separate material slots for wood, iron, and grime/stains.
- No characters, no food, no mugs, no surrounding room, no background.

Presentation:
- Isolated on a neutral background.
- 3/4 isometric preview angle.
- Warm tavern lighting only for preview.
```

## PixelLab Character Sprite Template

Use this template when asking PixelLab to create or animate a playable character.
Keep the identity block identical across all directions and actions.

### Character Identity Block

```text
[ERA / ROLE / CULTURE], historically grounded dark fantasy RPG character.
[AGE / GENDER / BUILD / EXPRESSION], [HAIR COLOR / HAIR STYLE], [EYE COLOR], [FACIAL HAIR OR DISTINCT FACE NOTES].
Wearing [PRIMARY CLOTHING / ARMOR], [SECONDARY CLOTHING DETAILS], [FOOTWEAR], and [IMPORTANT ACCESSORY OR SYMBOL].
No modern clothing, no unwanted genre drift, no oversized props unless requested, no cartoon proportions.
Pixel art style for HD-2D RPG: crisp readable silhouette, clean 32-bit style, strong shape language, limited palette, dark fantasy mood, no blurry edges.
Transparent background. Single character only. Full body visible. Character centered in frame. Consistent head size, silhouette, clothing, accessories, colors, and proportions in every frame.
```

Example identity block:

```text
A 13th-century Catholic priest, mid-30s, black hair, green eyes, wearing flowing white robes with embroidered gold trim and a polished brass cross pendant at the neck.
```

### Base 4-Direction Character Prompt

Use this first to establish the reference character.

```text
Create a 4-direction pixel art character sheet using this exact character identity:

[PASTE CHARACTER IDENTITY BLOCK]

Directions required:
- South/front view
- North/back view
- East/right-facing side view
- West/left-facing side view

Frame requirements:
- One neutral idle standing frame per direction.
- Same character, same face, hair, eyes, clothing, accessories, scale, palette, and pose weight across all directions.
- Feet aligned to the same baseline in every frame.
- No perspective camera tilt; use RPG sprite projection.
- Transparent background.
- 64x64 or 96x96 pixel frames, with enough margin for animation.

Negative constraints:
Do not change the character between directions. Do not change hair, eyes, clothing, accessories, body scale, or palette. Do not add weapons or props unless requested. Do not crop the feet. Do not create a portrait. Do not create a 3D render.
```

### Walking Animation Prompt

```text
Create a walking animation for this same character:

[PASTE CHARACTER IDENTITY BLOCK]

Action:
- Walking at a calm exploration pace.
- 4 directions: south, north, east, west.
- 8 frames per direction.
- Subtle robe sway, small step cycle, shoulders stable, head stable.
- Feet must stay on the same baseline and not slide upward.
- Keep the cassock length consistent; do not expose modern pants.
- Keep the hair, eyes, clothing details, accessories, colors, shoes, and body scale identical across all frames.

Output:
- Transparent background.
- Separate frames or a clean sprite sheet.
- Same canvas size for every frame.
- No motion blur.

Negative constraints:
No running pose, no attack pose, no cape, no weapon, no glowing effects, no changing costume, no camera angle changes, no extra characters.
```

### Running Animation Prompt

```text
Create a running animation for this same character:

[PASTE CHARACTER IDENTITY BLOCK]

Action:
- Controlled RPG run, not a sprinting athletic pose.
- 4 directions: south, north, east, west.
- 8 frames per direction.
- Robe swings more than walking, but remains historically plausible and readable.
- Arms move modestly under or beside the robe; no exaggerated anime running.
- Head and torso remain recognizable and consistent.
- Feet stay aligned to a shared baseline for each direction.

Output:
- Transparent background.
- Separate frames or a clean sprite sheet.
- Same canvas size for every frame.
- Crisp pixel art, no blur.

Negative constraints:
No modern running outfit, no exposed legs, no weapon, no magic, no cape, no costume changes, no extreme squash/stretch.
```

### Sitting Animation Prompt

```text
Create sitting frames for this same character:

[PASTE CHARACTER IDENTITY BLOCK]

Action:
- Character sits down calmly onto a simple invisible stool or bench-height seat.
- 4 directions if possible: south, north, east, west.
- 4 to 6 frames per direction.
- Robe folds naturally as the character lowers into a seated posture.
- Keep feet visible and grounded.
- Keep the same character scale, hair, eyes, clothing colors, accessories, and silhouette.

Output:
- Transparent background.
- Same canvas size for every frame.
- No chair or bench unless explicitly requested.

Negative constraints:
No throne, no modern chair, no kneeling prayer pose, no sleeping pose, no extra props, no costume changes.
```

### Getting Up Animation Prompt

```text
Create a getting-up animation for this same character:

[PASTE CHARACTER IDENTITY BLOCK]

Action:
- Character rises from a seated or low crouched position back to standing.
- 4 directions if possible: south, north, east, west.
- 5 frames per direction.
- Movement should be calm and grounded, suitable for an RPG interaction.
- Robe folds and settles naturally as the character stands.
- Final frame must match the neutral standing idle frame for that direction.
- Keep feet aligned and avoid sliding.

Output:
- Transparent background.
- Same canvas size for every frame.
- Crisp pixel art, no blur.

Negative constraints:
No dramatic jump, no combat recovery, no injury animation, no magic, no costume change, no extra characters, no furniture unless explicitly requested.
```

### PixelLab Notes

- Generate and approve the base 4-direction character before requesting animations.
- Reuse the approved image as the reference for walking, running, sitting, and getting up.
- Keep dimensions consistent across the full character set.
- If PixelLab changes the outfit, reduce the prompt and repeat the identity block more literally.
- If feet slide or the character changes size, ask for "same foot baseline, same canvas, same character scale in every frame."

## PixelLab Character: Medieval Italian Baker

Use this prompt for PixelLab character generation:

### Character Identity Block

```text
Mid-30s medieval Italian baker, historically grounded dark fantasy RPG townsfolk character.
Adult male, sturdy working build, kind but tired expression, warm tan skin, dark brown hair mostly covered by a baker's cap, short dark stubble.
Wearing a full baker's uniform: off-white linen baker's cap, long-sleeved cream tunic, flour-dusted white apron tied at the waist, rolled cuffs, simple brown trousers partly visible below the apron, sturdy brown leather work shoes.
Small details: dusting of flour on sleeves and apron hem, worn cloth belt, small folded towel tucked at the waist.
No chef toque, no modern chef jacket, no modern buttons, no fantasy armor, no weapons, no glowing magic, no cartoon proportions.
Pixel art style for HD-2D RPG: crisp readable silhouette, clean 32-bit style, strong shape language, limited medieval palette, dark fantasy village mood, no blurry edges.
Transparent background. Single character only. Full body visible. Character centered in frame. Consistent head size, baker cap, apron, flour marks, colors, and proportions in every frame.
```

### Base 4-Direction Character Prompt

```text
Create a 4-direction pixel art character sheet using this exact character identity:

[PASTE MEDIEVAL ITALIAN BAKER IDENTITY BLOCK]

Directions required:
- South/front view
- North/back view
- East/right-facing side view
- West/left-facing side view

Frame requirements:
- One neutral idle standing frame per direction.
- Same baker, same cap, same apron, same flour marks, same scale, same palette, same pose weight across all directions.
- Feet aligned to the same baseline in every frame.
- No perspective camera tilt; use RPG sprite projection.
- Transparent background.
- 64x64 or 96x96 pixel frames, with enough margin for animation.

Negative constraints:
Do not change the baker between directions. Do not add bread, trays, ovens, tables, or props unless requested. Do not add a modern chef hat. Do not crop the feet. Do not create a portrait. Do not create a 3D render.
```

### Walking Animation Prompt

```text
Create a walking animation for this same medieval Italian baker:

[PASTE MEDIEVAL ITALIAN BAKER IDENTITY BLOCK]

Action:
- Walking at a calm village NPC pace.
- 4 directions: south, north, east, west.
- 8 frames per direction.
- Subtle apron sway, small step cycle, shoulders stable, head stable.
- Feet must stay on the same baseline and not slide upward.
- Keep the baker cap, apron, flour marks, tunic, trousers, shoes, and body scale identical across all frames.

Output:
- Transparent background.
- Separate frames or a clean sprite sheet.
- Same canvas size for every frame.
- No motion blur.

Negative constraints:
No running pose, no carrying bread, no tray, no oven tools, no costume changes, no camera angle changes, no extra characters.
```

### Running Animation Prompt

```text
Create a running animation for this same medieval Italian baker:

[PASTE MEDIEVAL ITALIAN BAKER IDENTITY BLOCK]

Action:
- Controlled RPG run, as if hurrying through a town street.
- 4 directions: south, north, east, west.
- 8 frames per direction.
- Apron swings more than walking but remains readable and historically plausible.
- Arms move modestly; no exaggerated anime sprint.
- Keep the baker cap, apron, flour marks, tunic, trousers, shoes, and body scale identical across all frames.

Output:
- Transparent background.
- Separate frames or a clean sprite sheet.
- Same canvas size for every frame.
- Crisp pixel art, no blur.

Negative constraints:
No modern athletic pose, no flying apron, no props, no weapon, no magic, no extreme squash/stretch.
```

### Sitting Animation Prompt

```text
Create sitting frames for this same medieval Italian baker:

[PASTE MEDIEVAL ITALIAN BAKER IDENTITY BLOCK]

Action:
- Character sits down calmly onto a simple invisible stool or bench-height seat.
- 4 directions if possible: south, north, east, west.
- 4 to 6 frames per direction.
- Apron folds naturally as the baker lowers into a seated posture.
- Keep feet visible and grounded.
- Keep the same character scale, baker cap, apron, flour marks, clothing colors, shoes, and silhouette.

Output:
- Transparent background.
- Same canvas size for every frame.
- No chair or bench unless explicitly requested.

Negative constraints:
No modern chair, no sleeping pose, no kneeling pose, no extra props, no costume changes.
```

### Getting Up Animation Prompt

```text
Create a getting-up animation for this same medieval Italian baker:

[PASTE MEDIEVAL ITALIAN BAKER IDENTITY BLOCK]

Action:
- Character rises from a seated or low crouched position back to standing.
- 4 directions if possible: south, north, east, west.
- 5 frames per direction.
- Movement should be calm and grounded, suitable for an RPG NPC interaction.
- Apron folds and settles naturally as the character stands.
- Final frame must match the neutral standing idle frame for that direction.
- Keep feet aligned and avoid sliding.

Output:
- Transparent background.
- Same canvas size for every frame.
- Crisp pixel art, no blur.

Negative constraints:
No dramatic jump, no injury animation, no props, no costume change, no extra characters, no furniture unless explicitly requested.
```
