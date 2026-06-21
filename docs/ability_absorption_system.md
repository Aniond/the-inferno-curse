# Ability Absorption System

## Core Idea

The main character grows by absorbing abilities from creatures and enemies.

This is inspired by the feeling of discovering powers from monsters, but adapted to a tactical RPG with historical dark-fantasy tone. Monsters are not only obstacles; they are sources of knowledge, corruption, instinct, miracles, tactics, and forbidden techniques.

The job/class system should eventually grow around what the main character has absorbed.

Corruption is the price of power. Strong absorbed skills can give damage, stats, or tactical advantages, but they may increase corruption when equipped or used. This forces the player to decide whether a powerful skill is worth the cost to sanity, perception, and the surrounding world.

## Monster Ability Structure

Each monster has three learnable abilities:

1. **Normal**
2. **Uncommon**
3. **Rare**

These three abilities define what the monster can teach the player.

## Rarity Roles

### Normal Ability

The normal ability is the most basic learnable technique.

Typical effects:

- Single-target attack.
- Single-target heal.
- Simple elemental strike.
- Basic status poke.
- Low-cost utility.

Design purpose:

- Gives the player frequent small rewards.
- Teaches what the monster is about.
- Expands the main character's toolbox without breaking balance.

### Uncommon Ability

The uncommon ability is a stronger tactical tool.

Typical effects:

- Area attack.
- Area heal.
- Buff.
- Debuff.
- Zone control.
- Forced movement.
- Multi-target status effect.

Design purpose:

- Makes monster hunting meaningful.
- Adds tactical decisions to combat.
- Gives enemies abilities worth respecting before the player owns them.

### Rare Ability

The rare ability is a passive or identity-shaping trait.

Typical effects:

- Passive stat modifier.
- Elemental resistance.
- Counterattack rule.
- Healing boost.
- Morale effect.
- Movement rule.
- Formation or terrain bonus.
- Conditional trigger, such as bonus damage against isolated targets.

Design purpose:

- Creates long-term build identity.
- Gives the player a reason to revisit or farm specific monsters.
- Connects monster ecology to character progression.

## Absorption Rules

Exact unlock math can be tuned later, but the system should support:

- Defeating a monster can unlock one of its learnable abilities.
- Rarity affects unlock chance or required conditions.
- Rare abilities should require intent, not pure luck alone.
- Bosses and unique enemies can have authored absorption rewards.
- Some abilities may require the main character to witness, survive, counter, or be targeted by the ability before absorbing it.

Possible unlock conditions:

- Defeat the monster.
- Defeat the monster with the main character.
- Survive the ability being used.
- Interrupt the monster's tactic.
- Win without killing the monster, if mercy matters.
- Complete a city/node investigation tied to the creature.
- Break a formation or ritual pattern.

## Job/Class Connection

The job/class system should not only be a menu choice. It should reflect the abilities the player has absorbed.

Possible model:

- Abilities are grouped by theme, doctrine, or spiritual source.
- Learning enough abilities from a theme unlocks a class path.
- Passive rare abilities shape class identity.
- Classes can modify which absorbed abilities are available, improved, or combined.

Example groupings:

- Martial instincts.
- Sacred vows.
- Guild techniques.
- Beast forms.
- Infernal corruptions.
- Civic memories.
- Limbo echoes.

## Corruption And Purification

Corruption changes the player's perception of the world and can worsen each city's circle effects. It is not simply an evil score.

Example absorbed skill:

```text
Shadow Claw
Damage +5
STR +2 while equipped
Corruption +1% per use
Mana 1
```

Skills can level through use or duplicate drops of the same skill. Leveling can increase damage, stat bonuses, cost, corruption pressure, or special effects.

The Catholic Church can eventually reduce corruption and purify some corrupt skills into holy variants. Purified skills should change identity rather than act as free upgrades.

Guilds can sometimes reinterpret corrupt skills as grounded trade or martial techniques, removing corruption at the cost of raw supernatural power.

## Florence - Limbo Flavor

In Florence, absorbed abilities should feel connected to memory, delay, lost civic order, and suspended souls.

Possible Limbo-themed abilities:

- Delay a target's turn.
- Preserve a unit from death once.
- Repeat the last simple action.
- Reduce enemy morale.
- Create a zone of hesitation.
- Passive resistance to fear or confusion.
- Gain defense while holding position.
- Punish enemies that move out of formation.

These abilities should feel quiet and unsettling, not flashy or fiery.

## Data Model Implications

Monster data should eventually separate combat abilities from learnable absorption rewards.

Future monster sheet fields:

- `normal_ability`
- `uncommon_ability`
- `rare_ability`
- `normal_absorb_rate`
- `uncommon_absorb_rate`
- `rare_absorb_rate`
- `absorb_conditions`
- `ability_theme_tags`

Current `MonsterSheet.abilities` can remain as the combat-facing list for now. Absorption fields should be added when the combat and reward systems are scaffolded.

## Design Rules

- Every monster should teach the player something about the world.
- Normal abilities are useful but simple.
- Uncommon abilities change tactics.
- Rare abilities change builds.
- Rare abilities should feel earned.
- Passive abilities should be limited enough that builds remain readable.
- Absorption should support story and investigation, not only farming.

## Open Questions

- Should absorption happen automatically after battle or through a post-battle choice?
- Can the player miss abilities permanently?
- How many passive rare abilities can be equipped at once?
- Can party members use absorbed abilities, or only the main character?
- Do city circles modify absorption rates or ability corruption?
- Can AI enemies recognize and react to absorbed abilities?
