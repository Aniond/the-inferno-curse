# Art Bible - The Inferno Curse

## Core Vision

The game is a historically grounded Italian RPG set in real 1200s-1300s Italian cities, framed through Dante's Divine Comedy. Each major city is under the influence of one circle of Hell. The result should feel like Italian sacred and civic art being slowly corrupted by moral, political, and spiritual decay.

The first city is Florence under Limbo.

Florence should not read as demonic or ruined at first glance. It should read as beautiful, learned, solemn, and suspended. This is a city that has not been destroyed, but has forgotten itself: its culture, civic duty, memory, and spiritual direction have gone still. Limbo is expressed through absence, delay, faded grandeur, and unanswered longing.

## Primary References

- Dante Alighieri's Divine Comedy, especially Inferno as moral geography.
- Late medieval and early Italian Renaissance religious painting: fresco, tempera, gilded halos, architectural perspective beginning to emerge.
- Florence, Siena, and Tuscan civic architecture from the 13th-14th centuries.
- Tactical RPG presentation inspired by FFT-style menus and HD-2D spatial composition, without copying either directly.

## Technique

Primary technique: HD-2D / 3D HD with painterly historical materials.

- Environments are real 3D spaces built from historically grounded architectural props.
- Characters are pixel-art sprites with crisp silhouettes and restrained animation.
- UI uses painted manuscript, fresco, and gilded panel language.
- Lighting is cinematic but not modern glossy fantasy.
- Textures should feel painted, aged, and hand-authored rather than photographic.

## Mood

- Sacred
- Melancholic
- Suspended
- Weathered
- Intimate

## Florence - Limbo Direction

Florence is the city of forgotten inheritance.

Visual meaning:
- Beautiful civic spaces feel emotionally distant.
- Fresco colors are faded, not destroyed.
- Gold exists, but it is tarnished or muted.
- Churches and guild halls feel like memory containers.
- Fog, dust, candle smoke, and late-afternoon light soften the city.
- Shadows are blue-gray and quiet, not horror-black.
- Hell's influence is psychological and cultural: stillness, repetition, bureaucracy, empty ritual, lost names, unfinished works.

Avoid for Florence:
- No lava, fire pits, horns, skull piles, or obvious Hell imagery.
- No generic gothic fantasy excess.
- No saturated red demonic palette.
- No modern horror grime covering everything.
- No cheerful Renaissance festival look.

## Corruption Direction

Corruption is a penalty and a perception system, not a simple morality meter.

The player can gain powerful absorbed skills, but many of those skills cost corruption. This should create a real choice: power now versus the stability of the self and the world later. Corruption changes what the player sees, hears, understands, and is offered by the city.

As corruption rises:

- Familiar rooms feel darker, more claustrophobic, or subtly wrong.
- UI can become more stained, cracked, or severe.
- Dialogue can become less reliable, harsher, or more suspicious.
- Secret or distorted nodes can appear on city maps.
- NPCs affected by the city's circle can deteriorate.

In Florence/Limbo, corruption expresses itself as forgetting and cultural erosion. NPCs may forget recent events, names, relationships, duties, where they live, or why their work mattered. Limbo should feel like a city losing memory, not like a burning hellscape.

NPCs should eventually have their own default corruption value or susceptibility. This controls how strongly the circle affects them and how quickly they show local symptoms.

## Guilds, Church, And Social Power

1200s-1300s Italian cities were shaped by guilds, the Church, civic factions, trade networks, and reputation. These institutions must have teeth.

The player should often feel the question:

```text
Will this decision offend one of them?
```

Guild power is practical. They control beds, bread, contracts, tools, repairs, access, rumors, prices, and introductions. A guild does not need to attack the player directly to hurt them. It can make the city stop helping.

The Catholic Church is a major counterweight to corruption. Aligning with the Church can lower corruption, protect against corruption effects, and eventually convert some corrupt skills into holy variants. Purification should change a skill's identity rather than simply removing a downside. A corrupt skill may lose raw damage but gain holy damage, faith scaling, protection, or bonuses against corrupted enemies.

Guilds can provide a human/civic alternative to corruption. A monster skill might be interpreted three ways:

- Infernal: stronger, corrupting, dangerous.
- Guild: practical, crafted, civic, non-corrupting.
- Church: purified, holy, disciplined, less wild.

This triangle should be a major progression identity:

```text
Monster skills = power through corruption
Guilds = power through craft, profession, civic identity
Church = power through purification, vows, sanctification
```

## Reputation Consequences

Reputation should affect the player's daily life in the city.

Innkeepers and hospitality guilds:

- Hostile: sleep on the streets, poor recovery, possible risk events, higher corruption pressure.
- Neutral/no alliance: sleep in the stables, basic recovery.
- Accepted: common room cot, good HP recovery, partial MP recovery.
- Trusted: private room, full recovery, reduced corruption stress, better rumors.
- Favored: best rooms or patron lodging, full recovery, temporary buffs, rare rumors, safer storage.

Shopkeepers and merchant/craft guilds:

- Hostile: inflated prices, limited stock, rare goods withheld.
- Neutral: basic goods at standard prices.
- Accepted: better stock, small discounts, repairs or crafting access.
- Trusted: rare items, custom orders, better equipment, hidden-goods rumors.
- Favored: best inventory tier, deep discounts, guild-only goods, warnings about danger.

Reputation should be a city permission system. Choices should alter access to rooms, shops, secret nodes, services, recruits, legal protection, and rumors.

## Palette

| Hex | Role |
| --- | --- |
| #2a2630 | Limbo shadow violet-gray |
| #3d4658 | Cool civic stone shadow |
| #6f6250 | Weathered Tuscan stone |
| #9c7a43 | Tarnished gold |
| #c5a05a | Muted icon gold |
| #b66b3f | Burnt sienna / aged brick |
| #7f3f2f | Dark red fresco pigment |
| #d3bd87 | Aged parchment highlight |
| #e3d6ad | Fresco plaster light |
| #1c140f | Ink and deepest UI line |
| #f0e5c8 | UI readable light text |
| #6d7f74 | Desaturated robe green accent |
| #3f5875 | Marian blue / sacred blue accent |

Do not use pure white or pure black. Use `#f0e5c8` for light UI text and `#1c140f` for dark ink.

## Lighting Plan

General:
- Warm key light, cool shadow fill.
- Light should feel like late afternoon, candlelight, or filtered church interior light.
- Shadows should be present but soft enough to preserve the painterly look.

3D scenes:
- DirectionalLight3D: warm low-angle sun, roughly `#ffe0a3`, medium energy.
- Indoor torch/candle lights: warm amber `#d38a3e`, short range, soft falloff.
- Ambient/world fill: cool blue-gray `#30384a`, low energy.
- Tavern and interiors: practical candle/torch light with readable pools, not full-scene brightness.

Florence/Limbo:
- Use fog, dust, and cool shadow planes sparingly.
- Let gold and fresco tones appear muted under haze.
- Keep the player readable with a small warm light pool.

Never:
- No pure-white sun.
- No full black shadows.
- No bloom-heavy fantasy glow.
- No red hell lighting in Florence unless a specific story beat breaks the rule.

## UI Direction

UI should feel like a playable illuminated manuscript and civic ledger.

Use:
- Fresco backgrounds.
- Tempera-like figure panels.
- Gilded or inked borders.
- Worn parchment and cracked plaster texture.
- Dark ink labels with muted gold accents.
- Fixed-layout character sheets inspired by tactical RPG menus.

Avoid:
- Flat beige parchment without art.
- Modern transparent glass panels.
- Neon highlights.
- Generic fantasy leather-and-metal menus.
- Overly clean vector UI.

## Character Art Direction

Characters should feel historically grounded first, then stylized.

Use:
- 13th-14th century Italian clothing silhouettes.
- Clear role language: priest, baker, squire, guild worker, noble, not generic fantasy class costumes.
- Muted textile colors with one readable accent.
- Pixel-art sprites with strong silhouette and consistent scale.

Avoid:
- Modern fantasy armor proportions.
- Oversized weapons unless narratively justified.
- Anime hair and modern costume language.
- Unmotivated glowing magic effects.

## Environment Direction

Use:
- Tuscan limestone, brick, cracked stucco, terracotta roof tile, dark chestnut wood.
- Romanesque arches, Gothic transition details, biforate windows, civic interiors, churches, workshops, guild halls.
- Repeated real-city node structure: city map, illustrated node, small explorable room or street.

Avoid:
- Building every street at full scale.
- Generic medieval European assets that do not read Italian.
- Overfilled environments that obscure tactical readability.

## Do

- Make every city express its circle of Hell through culture, architecture, lighting, and social behavior.
- Keep Florence beautiful but emotionally suspended.
- Prefer fresco, manuscript, and civic art references over generic fantasy references.
- Use warm gold against cool blue-gray shadows as the core contrast.
- Keep player and interactables readable even when the world is moody.
- Save reusable prompts and visual rules so generated assets remain consistent.

## Don't

- Do not make Florence look like literal Hell.
- Do not use modern horror cliches for Limbo.
- Do not mix photoreal UI with pixel characters.
- Do not let generated assets drift into generic fantasy castles, taverns, or armor.
- Do not use pure black, pure white, neon colors, or heavy bloom as default styling.

## Prompt Prefix For Future Assets

Use this prefix when generating UI, props, portraits, or environments:

```text
Historically grounded 1200s-1300s Italian dark fantasy RPG, inspired by Dante's Divine Comedy and early Italian Renaissance sacred/civic art. Painterly HD-2D / 3D HD style with aged fresco texture, muted Tuscan stone, tarnished gold, burnt sienna, cool blue-gray shadows, and warm candlelit highlights. Serious, sacred, melancholic, weathered, and intimate. Avoid generic fantasy, modern horror, neon colors, pure black, pure white, and obvious demonic cliches unless specifically requested.
```
