# Recruitable NPC Job System

## Core Idea

Recruitable NPCs follow a more standard FFT-style job structure than the main character.

The main character grows by absorbing abilities from creatures. Recruitable NPCs grow through grounded human professions. Their jobs should feel like real roles in 1200s-1300s Italian city life, then branch into specialized tactical identities as they level.

This keeps party members tied to the world:

- Bakers create food.
- Smiths repair, forge, and improve gear.
- Priests bless, heal, and protect.
- Squires train into martial paths.
- Scholars study, identify, and manipulate knowledge.
- Guild workers bring civic, craft, and trade abilities.

## Design Split

### Main Character

- Learns from monsters and enemies.
- Absorbs normal, uncommon, and rare abilities.
- Progression feels supernatural, dangerous, and tied to the circles of Hell.

### Recruitable NPCs

- Learn through jobs, tools, trade, training, and lived experience.
- Job trees are grounded in real city roles.
- Progression feels social, historical, and human.
- Branches reflect specialization, not generic fantasy class labels.

## Baker Example

The baker is a recruitable support character.

Base job: **Baker**

Role:

- Creates food items.
- Restores HP through prepared food.
- Generates skill points or resource points for the party through meals, bread, or provisions.
- Supports the party before and during battles.

Battle identity:

- Low direct damage.
- Strong preparation economy.
- Item-focused healing.
- Party sustain.
- Possibly morale support.

## Baker Job Branches

### Baker

Base profession.

Abilities:

- Bake simple bread.
- Prepare travel rations.
- Restore a small amount of HP.
- Generate a small amount of skill points for the party.
- Improve camp/rest recovery.

Design purpose:

- Early support job.
- Helps the party survive without becoming a pure priest/healer.
- Teaches that non-combat professions matter tactically.

### Pastry Baker

Specialized branch focused on buffs and morale.

Abilities:

- Create pastries that grant short-term buffs.
- Improve morale or presence-based effects.
- Grant temporary SPD, PRS, or FTH boosts.
- Prepare celebratory food that strengthens the party before difficult fights.

Design purpose:

- Turns food into tactical enhancement.
- Makes the baker useful even when healing is not needed.
- Creates pre-battle preparation choices.

### Chocolatier

Specialized branch focused on healing potency and item efficiency.

Abilities:

- Increase healing amount from food items.
- Increase the number of uses or servings produced by crafted food.
- Add secondary recovery effects to food.
- Improve rare or high-value restorative recipes.

Design purpose:

- Turns the baker into a powerful sustain specialist.
- Rewards investment in crafting and supplies.
- Makes item economy part of party building.

## Job Branch Philosophy

Branches should not become abstract fantasy classes too quickly. They should remain recognizable as real professions, with tactical effects emerging from the job's real-world purpose.

Good branch names:

- Pastry Baker.
- Chocolatier.
- Apothecary.
- Farrier.
- Armorer.
- Illuminator.
- Notary.
- Confessor.
- Cantor.
- Mason.

Avoid generic branch names when a historical profession can carry the fantasy:

- Avoid "Food Mage" when "Pastry Baker" is stronger.
- Avoid "Buff Master" when "Chocolatier" or "Cantor" is more grounded.
- Avoid "White Mage" when "Priest", "Confessor", or "Hospitaller" fits the world.

## Data Model Implications

NPC sheets should eventually support recruitable-job fields:

- `can_be_recruited`
- `base_job`
- `current_job`
- `job_level`
- `job_experience`
- `unlocked_jobs`
- `job_abilities`
- `support_abilities`
- `crafting_recipes`
- `party_services`

Current `NpcSheet.services` and `NpcSheet.abilities` can stay simple for now. Job fields should be added when the party and job systems are scaffolded.

## Battle And City Integration

Recruitable jobs should matter in both combat and city exploration.

Examples:

- A baker can create food before a mission.
- A smith can improve gear or repair damaged equipment.
- A notary can unlock legal/civic node options.
- A priest can access church rumors or sacred locations.
- An illuminator can read or restore manuscript clues.
- A mason can identify hidden structural passages.

This makes recruitment part of the city-node system, not only battle roster management.

## Design Rules

- Recruitable NPCs should come from real grounded professions.
- Their job trees should branch from believable specializations.
- Each job should offer both battle value and city/exploration value when possible.
- Food, craft, legal, religious, and guild work should all become tactical systems.
- NPC job growth should feel human and historical, while the main character's absorption system feels supernatural.

## Open Questions

- Can NPCs permanently die or leave the party?
- Are job branches chosen manually or unlocked through story/actions?
- Can a recruitable NPC learn jobs outside their profession?
- Does the main character's monster absorption influence NPC job growth?
- Can city reputation unlock better profession branches?
- Are crafted food items consumed instantly, stored in inventory, or prepared as pre-battle meals?

