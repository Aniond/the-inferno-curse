# Turn-Based Battle System Architecture

This new battle system is designed to support the strategic features you requested:
- flank & side advantage
- height advantage for ranged attacks
- full cover and obstruction handling
- terrain created by spells and abilities

## Core Components

### CombatGrid
- Represents the battle map as a grid of `CombatCell` objects.
- Tracks walkability, cover, height, and obstruction metadata.
- Provides neighbor lookup, line-of-sight checks, and modifier helpers.

### CombatCell
- Holds the grid coordinate, world position, height level, cover state, and occupancy.
- Supports `Half Cover` and `Full Cover` bonuses.
- Can be marked as obstruction by terrain or spell effects.
- Tracks movement cost, line-of-sight blocking, terrain height changes, and temporary effect ids.

### CombatActor
- Wraps a battle unit as a `Node3D` so actors can be placed directly in a 3D encounter scene.
- Syncs movement, jump, speed, power, and defense from existing `CharacterSheet` or `MonsterSheet` resources.
- Keeps track of current HP, MP, CT, and the current combat cell.
- Stores an 8-direction visual facing that resolves into 4-direction tactical facing for combat rules.

### CombatState
- Drives encounter flow, turn order, and round progression.
- Calculates reachable movement range and attackable target sets.
- Resolves damage with height, flank, and cover modifiers.
- Detects victory/defeat conditions.
- Places and expires temporary terrain effects created by spells or abilities.

## Strategic Rules Included

### Flank & Side
- Actors support 8-direction visual facing for HD-2D presentation.
- Combat rules collapse that into 4 tactical arcs so positioning stays readable.
- Front attacks are normal, side attacks receive a moderate bonus, and back attacks receive a larger bonus.
- Pincer pressure adds a bonus when an ally threatens the target from the opposite side.

### Height
- Height difference between attacker and defender is converted into an attack modifier.
- Ranged attacks get the strongest high-ground value through damage modifier and effective range bonus.
- Melee attacks require the height difference to fit within the attacker's jump value.
- Movement also checks jump before allowing a unit to traverse elevation changes.

### Cover
- Cover is directional: the grid checks cells between attacker and defender before applying cover.
- Half cover adds a ranged defense modifier.
- Full cover and sight-blocking obstruction block normal ranged line of sight.
- Cover can come from authored cells, props, or temporary spell terrain.

### Terrain & Obstructions
- `CombatTerrain` is a scene node that can represent temporary or permanent battlefield objects.
- It exposes movement blocking, cover, height, and obstruction properties.
- Spell effects can instantiate `CombatTerrain` and update the grid accordingly.
- Terrain can also define movement cost, line-of-sight blocking, damage-on-enter, owner id, source ability id, and duration.
- Temporary terrain keeps track of affected cells so it can be removed cleanly when its duration expires.

## Next Steps

1. Create a battle encounter scene that owns `CombatGrid`, `CombatState`, and `CombatActor` instances.
2. Add a small UI overlay for turn order and selected action feedback.
3. Add a spell ability data system that can call `CombatState.place_terrain()`.
4. Add a battle preview UI for targetable cells, cover warnings, flank/back attack hints, and height advantage.
5. Build a small tavern or street encounter scene to test movement, ranged line of sight, cover, and spell-created obstructions.
