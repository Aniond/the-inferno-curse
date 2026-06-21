# Faction Reputation System

## Core Idea

Guilds, the Catholic Church, civic authorities, merchants, and criminal networks are not flavor text. They control daily life in 1200s-1300s Italian cities.

The player should feel that every important choice may please one faction and offend another.

```text
Who benefits?
Who loses money?
Who loses face?
Who loses authority?
```

## Design Pillars

- Guilds have practical power over access, prices, beds, tools, repairs, jobs, rumors, and services.
- The Church can reduce corruption and purify some corrupt skills into holy variants.
- Reputation consequences should usually be social and economic before they become violent.
- City-node access should depend on faction trust, rumors, investigation, and moral choices.
- The same location can feel different depending on faction standing and corruption level.

## Reputation Bands

Suggested baseline:

- `Hostile`
- `Untrusted`
- `Neutral`
- `Accepted`
- `Trusted`
- `Favored`

The exact numeric thresholds can be tuned later. The important rule is that each band should change what the player can access.

## Hospitality / Innkeepers

The hospitality guild controls rest quality.

- Hostile: sleep on the streets, poor recovery, risk events, possible corruption pressure.
- Neutral/no alliance: sleep in the stables, basic HP recovery, little or no MP recovery.
- Accepted: common room cot, full HP recovery, partial MP recovery, minor morale buff.
- Trusted: private room, full HP/MP recovery, corruption stress reduced, better rumors.
- Favored: best room or patron lodging, full recovery, temporary party buff, rare rumors, safer storage, reduced ambush risk.

## Shops And Craft Guilds

Shop inventory should be reputation-gated.

- Hostile: inflated prices, limited inventory, rare goods withheld, possible reporting to rivals or authorities.
- Neutral: basic goods only at standard prices.
- Accepted: better stock, small discount, repair or crafting service unlocked.
- Trusted: rare items, better equipment, custom orders, rumors about hidden goods.
- Favored: best inventory tier, deep discounts, guild-only goods, reserved items, warnings about danger.

Each shop can eventually define:

- `base_inventory`
- `reputation_inventory`
- `faction_inventory`
- `price_modifier_by_reputation`
- `service_unlocks`

## Church And Corruption

The Church is a counterweight to corruption.

Possible Church benefits:

- Lower current corruption.
- Reduce corruption gained from certain actions.
- Protect NPCs from local circle effects.
- Convert corrupt skills into holy variants.
- Unlock sacred nodes, confessions, relics, blessings, or purification rites.

Purification should change the identity of a skill, not simply remove its cost.

Example:

```text
Shadow Claw
Dark damage
STR +2
Corruption +1% per use
```

Can become:

```text
Sanctified Claw
Holy damage
STR +1
FTH +2
Corruption +0%
Bonus damage against corrupted enemies
```

## Guild Interpretation Of Skills

Some monster or corrupt abilities may be reinterpreted through guild training.

Example:

```text
Shadow Claw -> Butcher's Hook Technique
Physical damage
STR +1
CRT +1
Corruption +0%
Requires guild training or tool proficiency
```

This creates three paths:

- Infernal: strongest and most corrupting.
- Guild: practical, crafted, civic, non-corrupting.
- Church: holy, disciplined, spiritually protected.

## City Node Integration

Faction reputation can unlock, modify, or close nodes.

Examples:

- Innkeepers reveal a hidden room.
- Apothecaries sell anti-corruption tinctures only at Trusted.
- Church confessions reveal a secret node.
- Merchant guild hostility raises prices citywide.
- City watch suspicion creates risk events.
- Criminal favor opens black-market nodes.

The player should learn that a place exists before they can go there. Reputation and rumors are the keys.

## Design Rule

The city should not only react with enemies. It should react by changing comfort, access, recovery, prices, information, and trust.
