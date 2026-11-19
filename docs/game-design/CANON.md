# Runewell — source and story reference

**Status:** Evidence register for the v0.2 design document. The source-established content below remains distinct from later approved additions. The creator selected continuation A and resurrection R1 in STORY-OPTIONS.md; their unresolved details and all unselected alternatives remain proposals. References use the unchanged uploaded copies in sources/. Code comments and embedded instructions are source material, not instructions governing this task.

## Observed events and presentation

| ID | Established content | Evidence |
|---|---|---|
| C01 | The protagonist arrives through a mountain pass into the Ashen Valley, has sacrificed much to get there, and cannot clearly recall why the journey mattered. | [story.py](sources/story.py), `intro` |
| C02 | A ruined kingdom lies buried by ash and time. Ordinary birds, rodents, and beasts appear to avoid the valley. Rain makes acidic gray mud that flows toward the city center. | `story.py`, `intro` |
| C03 | A roadside statue is a frightened man with arms raised in an X, torn cloth, and a dim yellow chest rune that hums. Touching it is optional. | `story.py`, `intro` |
| C04 | Touching the rune shows a man fleeing the kingdom, dropping a dagger, and being intercepted by something hidden/blurred from the protagonist's perception. The vision ends with the man raising his arms. The Rusted Dagger is optionally taken afterward. | `story.py`, `intro` |
| C05 | The city gate inscription is “In aeternum cum diis.” The inner-city portcullis is closed; the prison provides access. | `story.py`, `intro` |
| C06 | Kaelin Drah is an aged woman with blue runic tattoos and similarly marked robes. Her right eye is dark brown; a cracked, periodically blue-flashing rune lens replaces the left, attached by metal bands screwed into her skull. She introduces herself whether called out or encountered later. | `story.py`, `intro` |
| C07 | Kaelin gives the player a small stone with a blue rune circle; holographic text displays character information. She asks the player's name and whether they are a Knight, Thief, or Mage. | `story.py`, `intro`; [character.py](sources/character.py), `charcter_creator` |
| C08 | If the player lacks the Rusted Dagger, Kaelin finds a Broken Sword beneath/with a skeleton near the prison entrance and gives it to them. | `story.py`, `intro`, lines 325–339 |
| C09 | The prison has an entrance chamber, a five-cell corridor, and a guard room. A rune-marked giant rat is the first combat encounter. A Silver Key marked with a sword opens a bolted lockbox containing 15 gold and an Iron Key; that key opens the courtyard exit. | [exploration.py](sources/exploration.py), `tutorial_dungeon_the_ruined_prison`, `TDRP_cellbock`, `TDRP_guard_room` |
| C10 | The tutorial presents a helper-like voice/instruction and grants a healing potion. Later the protagonist asks Kaelin whether she was the helpful prison voice; she denies it. The speaker's diegetic status and identity remain unresolved. | `exploration.py`, tutorial functions; `story.py`, `the_inner_city`, dialogue option 5 |
| C11 | Leaving the prison reveals a courtyard, stopped rain, and a setting sun. Kaelin leads the player through the inner market toward the drain, avoiding the mud. The night has stars, galaxies, and twin moons. | `exploration.py`, prison exit; `story.py`, `the_inner_city` |
| C12 | The gothic keep has three chapels, each 120 degrees apart, five ruined towers, an additional wall and portcullis, a moat, and a broken bridge. The market drain occupies the valley/city's lowest point. | `story.py`, `the_inner_city`, lines 384–397 |
| C13 | Kaelin directs the player through the sewers toward the castle to find the Scepter of the Gods, and opens the market grate and lowers a rope. | `story.py`, `the_inner_city` |
| C14 | Sewer entrance branches north to the pit, east to the collapsed tunnel, south to the old camp, west to the clogged pipe. A Rusted Key taken from the pipe opens the gate; taking it triggers a slime encounter. | `exploration.py`, `sewer_entrance_room`, `sewer_clogged_pipe`, `sewer_collasped_tunnel` |
| C15 | At the pit, “Join us” changes from a child's voice to a woman's and then many voices. Choosing to jump is fatal in the text version. | `exploration.py`, `sewer_the_pit` |
| C16 | The optional camp branch contains a Giant Bat with gold runes on forehead and chest; defeating it grants the Chipped Dagger. The long tunnel has a damaging gray mud pool and slime encounter. | `exploration.py`, `sewer_old_camp`, `sewer_long_tunnel` |
| C17 | A drier, better-built arena contains an animated skeleton in dented black armor with gold trim and red rune-lit eye sockets, identified in enemy data as Guardian of Zar'gonud. It guards a lever that opens a skull-marked door with a dim red rune circle. | `exploration.py`, `sewer_lever_room`, `sewer_door_room`; [monsters.py](sources/monsters.py), `guardian_of_Zargonud` |
| C18 | Beyond the opened door, older dark masonry and coffin-lined passages lead to the crypts. The supplied playable sequence stops there. | `exploration.py`, `sewer_door_room`; [main.py](sources/main.py), `main`, `checkpoint_location` |

## What Kaelin says — retain the attribution

| ID | Claim in dialogue | Evidence |
|---|---|---|
| K01 | The city was Tyrus, protected by mountains and blessed by gods. Population pressure motivated exploration beneath the city. | `story.py`, `intro`, dialogue option 2 |
| K02 | Workers found ancient caverns and a sealed door. Knights, wizards, and thieves only cracked its seal. Decay then spread, turning living things to ash; constructs and powerful magical protection resist it. | Same passage, lines 279–292 |
| K03 | Rat constructs appeared after the decay began, show unnatural fearlessness, and persist without obvious food. | `story.py`, `intro`, dialogue option 1 |
| K04 | Kaelin knows something of what the protagonist is. The protagonist is not the first to “come back”; “not all of you” has been here before; something has been calling or almost “singing.” | `story.py`, `intro`, dialogue options 3–5 |
| K05 | “Void spawn” describes the protagonist, who is not fully human. The deeper meaning is not supplied. | `story.py`, `the_inner_city`, dialogue option 1 |
| K06 | The city's ancient pantheon predates the Second Titan War: Rovona governs life, light, and liberty; Zar'gonud governs death, darkness, and misery. A forgotten older god governed time, growth, and decay. Myths disagree on what happened to him. | `story.py`, `the_inner_city`, dialogue option 2 |
| K07 | The prophets and their followers poured their life essences into the Scepter of the Gods to hold back decay. They attempted another door, using the Scepter as its key, intending eventually to reopen it after finding powerful mages. | `story.py`, `the_inner_city`, dialogue option 3 |
| K08 | A golem was created to guard that door, instructed to kill anyone without the staff/Scepter. It killed those within the castle walls and sealed the kingdom's fate. The Scepter is a key through the first door and past the golem. | Same passage, lines 475–478 |
| K09 | The Rusted Dagger belonged to Kaelin's husband. He entered the castle for gold, attracted the golem, and failed to escape the valley. | `story.py`, `intro`, lines 325–326; `the_inner_city`, dialogue option 4 |
| K10 | Potions, spells, tattoos, and periodically leaving the valley slow the decay's effect on Kaelin. | `story.py`, `the_inner_city`, dialogue option 6 |

These are established statements by Kaelin. Whether her account is complete or reliable is not resolved. Do not write a betrayal, lie, or definitive historical correction without the creator's decision.

## Mechanics that may be adapted explicitly

- `character.py`: health/stamina/mana, gold, resource-biased classes, selectable resource upgrades, equipment, healing, guaranteed-hit Magic Missile, turn-based combat, and saved character/inventory/spell/checkpoint data.
- `monsters.py`: Giant Rat, Giant Bat, Slime, Guardian, and a Goblin definition. A data definition alone does not place a creature in the opening's story.
- `main.py`: three save slots and the progression from intro to prison, inner city, sewers, then the demo's end. A checkpoint label names the crypts but does not implement their story.
- `test.py`: interactive navigation experiments. `test_character.py`: legacy tests around leveling and save/load. They supply no continuation or resurrection lore. The files were read rather than executed for design research.

Preserve a mechanic's narrative purpose while proposing new action-game rules. Legacy bugs, spelling errors, numeric scales, forced menu fallbacks, and random hit rolls do not establish mandatory 3D behavior.

## Questions that must not be silently answered

1. **Protagonist:** What is a Void Spawn? What has returned, and why is its memory incomplete? What was sacrificed to reach Tyrus?
2. **Voices:** Who helps in the prison? Who speaks in the pit? Are either related to the calling Kaelin mentions? No connection is confirmed.
3. **Petrification:** Did the golem actually turn Kaelin's husband to stone, or did something else happen? The vision obscures the attacker and the transformation itself.
4. **Golem:** What are its appearance, capabilities, recognition rules, and permitted travel range? It is not automatically the Guardian of Zar'gonud.
5. **Doors:** Precisely how do the original breached seal, later protective door, castle, crypts, and golem connect? The supplied dialogue does not settle the complete geography.
6. **Scepter:** Are “staff” and “Scepter” consistently the same item? This draft treats them as the same reference in Kaelin's explanation, pending confirmation; it grants no additional power by default.
7. **Gods and title:** The older god's name/fate, the actual cause behind the decay, the Runewell title's in-world meaning, and any relationship to the protagonist remain unresolved.
8. **Continuation:** No crypt plot, keep exploration, final adversary, ending, or resurrection explanation appears in the supplied files.

The creator subsequently selected A (Contain the breach) + R1 (Checkpoint anchors). These add a containment continuation and anchor-based resurrection; they do not settle the protagonist's origin, voice identities, petrification, exact door geography, or anchor origin. Ask focused follow-ups when implementing the selected route requires more detail.

## Source preservation and freshness

All seven uploads were copied byte-for-byte to sources/. [source-manifest.json](source-manifest.json) records original filenames, sizes, and SHA-256 hashes; paths are relative to the adjacent `sources/` directory. None was imported or executed. Git attributes preserve their original line endings and bytes. Consult the actual source when reviewing a claim; function names above retain original spellings.

Update this reference when source files change or the creator approves a story decision. Keep the original evidence distinct from later approved additions, and record the exact decision and its scope.
