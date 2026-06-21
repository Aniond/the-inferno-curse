# City Node Structure

## Core Approach

Cities are not built as full open-world maps. Each city uses a Persona-style navigation layer:

1. A stylized city overview map.
2. Selectable nodes placed on that map.
3. Each node has a description, artwork, and available actions.
4. Selecting a node loads a focused explorable street, room, shop, church, guild hall, or combat space.

This keeps production focused on high-quality spaces instead of trying to build every major street and building in Florence.

## Why This Works

The game is about historical atmosphere, character drama, tactical encounters, and Dante-inspired moral geography. Small, carefully made locations will sell that better than a massive empty city.

The test tavern room proves the foundation:

- 3D room shell.
- HD-2D camera and sprite scale.
- Modular floor, wall, furniture, and prop placement.
- Character traversal inside a believable space.
- UI overlay working on top of the scene.

That room is the prototype for all future explorable city nodes.

## Florence - Limbo

Florence begins as the first city, under the influence of Limbo.

The city overview should feel like a beautiful but suspended memory of Florence. Nodes should suggest culture, civic life, faith, commerce, and learning, but with a sense that the city has forgotten its purpose.

Possible node types:

- Inn common room.
- Street outside a guild hall.
- Church interior.
- Market street.
- Civic square.
- Workshop or artisan room.
- Noble house room.
- Library, archive, or scriptorium.
- Hidden memory node.
- Battle test location or ambush street.

## Rumors, Investigation, And Secret Nodes

Secret areas are handled by unlocking new city-map nodes, not by requiring every hidden place to exist inside a large walkable city.

Example flow:

1. The player hears a rumor about a troubled shop.
2. A journal clue, dialogue flag, or investigation action records that lead.
3. The city map reveals a new optional node for that shop.
4. The player chooses whether to investigate.
5. Selecting the node loads the focused shop room, back room, alley entrance, or combat version of that location.

This lets secrets feel like discoveries in the city rather than checklist icons.

Secret node sources:

- Tavern rumors.
- Guild gossip.
- Church confessions.
- Market overheard dialogue.
- Letters, ledgers, or legal records.
- Battle aftermath clues.
- NPC trust or faction reputation.
- Dante/Limbo memory fragments.

Faction reputation can change node access. Guilds, shops, inns, churches, and civic offices should open or close options based on how much they trust the player. A good city decision should often make the player wonder which institution might be offended.

Secret node types:

- Hidden shop.
- Back room.
- Cellar.
- Private chapel.
- Forgotten archive.
- Rooftop or alley route.
- Sealed civic chamber.
- Memory version of a known location.

Design rule:

The player should often learn that a place exists before they can go there. Unlocking a node is a reward for paying attention, asking questions, or following a moral/story thread.

## Node Content Contract

Each node should eventually define:

- `id`
- `display_name`
- `city_id`
- `circle_influence`
- `description`
- `preview_image`
- `scene_path`
- `available_actions`
- `connected_nodes`
- `unlock_conditions`
- `secret_conditions`
- `faction_requirements`
- `reputation_effects`
- `corruption_effects`

## Production Rule

Build one strong room or street at a time.

Do not attempt a full walkable Florence. Use the city map to imply scale, then let selected scenes provide detail, mood, characters, and encounters.

## Exploration To Battle Reuse

Explorable street and room scenes should be designed so they can later become tactical battle maps.

The ideal workflow:

1. Build a focused explorable street, room, shop, church, or civic space.
2. Keep its floor plan readable from the HD-2D camera.
3. Add collision and clear walkable lanes.
4. Overlay or generate a tactical grid from the same space when combat starts.
5. Reuse the same props, walls, lighting, and mood so battles feel grounded in the city instead of disconnected from it.

This means a street node can serve three jobs:

- Exploration scene.
- Story/dialogue scene.
- Tactical battle map.

Design implications:

- Streets need readable width and landmark props.
- Furniture should create tactical cover and movement choices, not only decoration.
- Props should avoid blocking the camera or hiding characters.
- Doorways, alleys, stairs, counters, pews, and market stalls can become tactical features.
- Grid alignment should be considered early, even if the visible grid is hidden during exploration.

The goal is not to make every node combat-ready immediately. The goal is to build reusable spaces whose geometry can support combat later without rebuilding the scene from scratch.

## Reputation-Based City Services

Inns, shops, and guild services are part of city navigation.

The hospitality guild controls rest quality. With no alliance the player may sleep in the stables. If the player works against them, they may be forced onto the streets. Higher reputation gives better rooms, stronger recovery, buffs, safer storage, and better rumors.

Shopkeepers and craft guilds should provide better items, more stock, custom orders, repairs, and discounts as reputation increases. Low reputation can mean inflated prices, basic stock only, withheld goods, or being reported to rival factions.
