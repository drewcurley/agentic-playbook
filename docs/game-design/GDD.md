# Runewell — Game Design Document

**Version:** 0.2, selected story direction · **Date:** November 18, 2026 (America/Denver)

**Status:** The creator selected continuation A (Contain the breach) and resurrection R1 (Checkpoint anchors). The remaining design is a proposal, not an implementation authorization or a fully approved story bible. This document is tracked with its source archive in `docs/game-design/`. The seven supplied Python files are preserved unchanged in [sources/](sources/); [CANON.md](CANON.md) records the evidence and unresolved story questions.

## 1. Spec sheet

| Field | Specification | Authority |
|---|---|---|
| Working title | Runewell | Adapted from the source title, Runewell RPG |
| Format | Short, single-player, third-person Souls-like action RPG | Genre requested; perspective and single-player proposed |
| First completion | 2–4 hours, including normal exploration and retries | Confirmed by creator |
| Visual direction | Low-poly, PS2-era-inspired environments and characters | Requested by creator |
| Gameplay feel | Responsive controls, deliberate attacks, readable threats, dependable camera | Requested direction; details proposed below |
| Setting | The Ashen Valley and ruined city of Tyrus | Source-established |
| Opening route | Mountain pass → outer city → ruined prison → inner city → sewers → crypt threshold | Source-established |
| Later route | Crypts → keep → retrieve Scepter → pass golem/protective door → contain the breach | Continuation A selected; detailed geography and encounters pending |
| Initial platform | Windows PC, controller and keyboard/mouse | Working proposal; confirm before choosing engine/export targets |
| Frame-rate goal | Stable 60 fps on a named reference PC, to be selected during the prototype | Proposed target, not measured performance |
| Engine | Undecided; evaluate after platform and combat prototype requirements are agreed | Open technical decision |
| Content envelope | One compact connected city, one principal NPC, 4–6 enemy archetypes, 2–3 major encounters | Proposed production ceiling |

**Pitch:** Enter an ash-buried kingdom that seems to remember you. Follow a cryptic guide through its prison and sewers, fight creatures marked by runes, and pursue the reason you were drawn to Tyrus.

**Player promise:** Learn a dangerous place through observation, overcome its inhabitants through timing and positioning, and uncover a personal mystery without losing the original story's identity.

Continuation A and resurrection R1 are creator-selected directions. Other design details below remain proposals unless explicitly identified as creator-confirmed or source-established. Numerical values are prototype starting points.

## 2. Design pillars

1. **Preserve the mystery.** Kaelin's knowledge, the player's nature, the missing god, and the voices remain deliberate questions until the creator approves their answers.
2. **Commitment with responsive handling.** Movement and camera react promptly; attacks have clear commitment and recovery. Difficulty comes from decisions the player can understand.
3. **A small place with depth.** Revisit recognizable spaces through shortcuts and changing understanding. Build density rather than an open world.
4. **PS2-inspired form, modern readability.** Simple geometry, painted texture detail, strong silhouettes, atmospheric lighting, clear combat animation, and scalable UI.
5. **Discovery rewards attention.** The statue, Kaelin's conversations, visible locked routes, and optional loot connect exploration to story and preparation.

## 3. Story authority and agent instructions

The creator retains authority over story questions and major changes. The creator has selected A + R1. Other continuation and resurrection alternatives remain unselected. Direction selection does not approve unresolved details or authorize game implementation.

Before story-related work, agents must read this document, CANON.md, and the relevant source passages. Distinguish direct observations, dialogue claims, approved additions, and unresolved questions in every proposal. Do not turn a character's claim into an omniscient fact.

Routine adaptation may propose room dimensions, camera clearance, combat timing, navigation cues, menu layouts, and encounter spacing. Ask the creator directly before implementing any change to identities, motives, relationships, divine history, chronology, death lore, major locations, artifact powers, endings, or an established choice's consequences. Also ask before removing or merging a significant story beat to save scope.

For a major change, present: original passage; concrete proposed change; why 3D or gameplay needs it; consequences; and a less disruptive alternative. Record the creator's exact decision and its scope. Delegation applies only to the decisions explicitly delegated. Silence does not approve a change.

**Protected points:** Touching the roadside rune stays optional. Refusing the dagger must still lead to a usable weapon. Kaelin's denial of being the prison voice stays intact. The Scepter must retain its established relationship to the protective door and golem. Neither the title nor the word “void” establishes additional cosmology by itself.

## 4. Player experience and core loop

Observe a space → choose a route → fight or withdraw → recover resources → acquire a key, tool, or clue → unlock a route → reach safety → improve a chosen resource → descend further.

The opening moves from rain and apparent emptiness to the first rune-marked creature. The prison teaches survival. The inner city provides relief and a clearer goal. The sewer turns navigation and resource use into a test, then introduces older architecture at the crypt threshold.

### Session flow

New game/load → optional presentation settings → mountain descent → statue choice → Kaelin introduction and character identity → prison tutorial → courtyard reunion → market conversation/shop → sewer exploration → Guardian encounter → crypt threshold → approved continuation → ending and return to menu.

Three manual save slots follow the original menu concept. Autosave meaningful progress; clearly warn before replacing a slot. Support suspend/resume outside transient combat events.

## 5. Opening adapted to 3D

| Area and preserved beat | Proposed playable treatment | Completion criterion |
|---|---|---|
| Mountain pass; ruined valley vista | A short controllable descent, with the city and keep visible for orientation | Player learns movement and camera before the first threat |
| Man-shaped statue; dim yellow chest rune | Optional interaction presents the original fleeing-man vision; the Rusted Dagger is discoverable on that branch | Taking or declining the rune and dagger never blocks progression |
| Outer city; shadowing figure | Glimpses of Kaelin through ruined storefronts; player can call out or meet her at the blocked inner gate | Both branches reach the same introduction with appropriate dialogue |
| Kaelin's blue rune stone; name and class | Brief identity menu grounded in the existing encounter | Name/class confirmed; stone displays character information |
| Ruined prison | Central entry with east cellblock, west guard room, north locked exit | Silver Key → lockbox → Iron Key → courtyard |
| Courtyard and inner market | Short traversal with optional Kaelin conversation; avoid a prolonged forced escort | Player understands that the route to the keep runs underground |
| Sewers | Four-way entrance, optional branches, rusted gate, mud crossing, lever and door | Rusted Key and Guardian/lever route lead to the crypt entrance |

Preserve the keep's three chapels set 120 degrees apart and five ruined towers as a recognizable vista. The city remains an authored set of playable districts; distant buildings supply scale. Do not turn every building or chapel into a required dungeon.

### Prison teaching sequence

Use the first rat to teach attack range and recovery. Add a clear dodge opportunity, then optional magic and healing prompts. These are interactive instructions, not forced critical damage or unexplained free items. The original tutorial explicitly teaches attacks, Magic Missile, and a healing potion; preserve that teaching purpose. Any replacement dialogue for the mysterious helper needs story review.

Keep five recognizable cells, the sword emblem on the Silver Key, the bolted lockbox, its 15 gold reward, and the heavy Iron Key. Interaction prompts automatically select the correct carried key. Keys cannot be sold or discarded while needed.

### Sewer layout

```text
                            Pit: voices; lethal fall
                                      |
Clogged Pipe: Rusted Key — Entrance — Collapsed Tunnel: rat + locked gate
                                      |                       |
                           Old Camp: bat + dagger       Long Tunnel: mud pool
                                                              |
                                          Door Room — junction — Lever Room
                                              |                  Guardian
                                      Crypts, once lever opens door
```

This is a connectivity sketch, not a scale plan. The upper tunnel connections must preserve the source's navigation logic. Show the locked gate before or soon after the key branch; use masonry, flow direction, and silhouettes to distinguish exits.

The Old Camp's Chipped Dagger remains an optional reward behind the bat. The pit keeps “Join us” and a genuinely lethal drop, with readable footing and no automatic movement into it. Do not identify these voices or equate them with the prison helper.

The mud remains dangerous. Use clear shallow/deep boundaries, prompt feedback on first contact, and short exposure lengths. Tune the crossing so a healthy player can complete it without buying supplies. Any added bypass or shortcut is a topology proposal, not an already established route.

## 6. Combat and controls

### Combat model

Free movement with optional lock-on. Light attack, heavy attack, directional dodge, sprint, contextual interaction, quick-use consumable, and two selectable spells form the initial action set. Prototype weapon guarding; defer parries, backstabs, jumping attacks, and elaborate combo systems until the basic loop works.

Replace chance-to-hit and random critical rolls with spatial hit detection, visible attack timing, and explicit stagger openings. Armor reduces incoming damage instead of making visibly connected attacks randomly miss. Enemies follow readable, situation-dependent behavior with bounded variation.

Attacks have startup, active contact, and recovery. A weapon can damage a given target only once per intended swing. Permit directional steering early in an attack; limit late tracking. A dodge cannot cancel every mistake. Knockback, recovery, and enemy spacing must prevent unavoidable stun loops.

### Initial tuning sheet

| Parameter | Starting point | Validation intent |
|---|---|---|
| Baseline health/stamina/mana | 100 / 100 / 100 normalized for prototyping | Replace legacy magnitudes without changing the three-resource identity |
| Light attack | 20 stamina; roughly 0.6–0.8 seconds total | A short sequence leaves room to dodge |
| Heavy attack | 35 stamina; roughly 1.0–1.3 seconds total | Clear risk and stagger reward |
| Dodge | 25 stamina; roughly 0.65 seconds total, with 0.20–0.25 seconds of invulnerability | Reliable escape when timed correctly |
| Stamina recovery | Begins about 0.7 seconds after spending; about 25/second | Brief disengagement restores options |
| Input buffer | About 100 ms; one pending action | Accept intentional input near recovery without queueing accidental chains |
| Basic enemy defeat | About 3–5 clean starting light hits | Keep ordinary fights concise |
| Guardian attempt | About 90–180 seconds when played competently | Test several patterns without inflating health |
| Critical retry route | Target under 30 seconds after opening its shortcut | Learning time dominates repeated traversal |

Measure these in the prototype before treating them as requirements. Animation, hitboxes, and stamina costs must be tuned together. Do not slow input or cap gameplay at a retro frame rate for aesthetic reasons.

### Camera and input requirements

Third-person camera with collision avoidance, adjustable sensitivity, invert options, and lock-on switching. Keep the player and attacking target visible in narrow cells; widen spaces before combat animation is finalized. Avoid target switching to an enemy behind a wall. Support unlocked combat and readable bat attacks without requiring rapid overhead camera movement.

Prototype controller mapping: left stick move, right stick camera, right-stick click lock-on, right shoulder light attack, right trigger heavy attack, left shoulder guard, left trigger cast, face buttons dodge/interact/use item, directional pad select spell/item. Sprint uses a configurable stick click initially. Keyboard/mouse bindings must be fully rebindable; final defaults follow playtesting.

## 7. Character, equipment, and progression

Preserve Knight, Thief, and Mage as starting resource emphases rather than three separate campaigns. The original Knight favors stamina, Thief shares stamina and mana bonuses, and Mage favors mana. All begin knowing Basic Magic Missile and Basic Healing; do not silently remove either spell from a class.

Keep the original resource-focused leveling choice: health, stamina, or mana. Use a small number of authored milestones for this short game, beginning with the courtyard reunion and the original sewer progression point. Tune the placement of safe upgrade interaction without inventing its lore. Avoid a compulsory grinding economy.

Initial weapons: Rusted Dagger or Broken Sword; optional Chipped Dagger upgrade. Give dagger and sword distinct reach and animation while keeping both starts viable. Ripped Cloth and Kaelin's Padded Armor establish the initial armor progression. Extra weapon types are a later scope decision; cap the initial release proposal at four functional weapon variants.

Magic Missile preserves its reliable ranged role. Proposed translation: a guided projectile for a valid visible target, blocked by solid cover; replacing its literal “never misses” rule is an explicit mechanical adaptation. Basic Healing remains mana-based and vulnerable during its cast. No casting through walls or healing above maximum health.

## 8. Recovery, death, economy, and persistence

**Mechanical proposal, pending story approval for its presentation:** neutral checkpoint placeholders support rest and retry. Do not label them shrines of an existing god or attach resurrection to Kaelin's stone yet.

At rest, restore health and mana, refill three baseline healing uses, and reset ordinary encounters. Baseline healing uses are a new system inspired by the source potions; their final item name and explanation remain open. Kaelin's finite healing, stamina, and mana potions provide optional reserves. Milestone guardians remain defeated. A player with zero gold must always have a viable route forward.

On death, retain equipment, key items, opened locks, lever states, collected unique items, approved dialogue flags, and milestone upgrades. Restore spent baseline healing uses on retry. Initial proposal retains gold and avoids corpse retrieval; add a loss/recovery mechanic only if testing shows it improves this short game. Souls-like identity does not depend on a currency run.

Save committed progression atomically. Do not repeat first-time item rewards, grant duplicate keys, reverse an opened route, or replay first-meeting dialogue after a reload. Retrying must not advance narrative time, resurrect named story characters, or repeat a unique vision as if new unless approved.

Resurrection R1 (Checkpoint anchors) is selected: prepared anchors restore the protagonist after death, without a global time rewind. Their origin, visual identity, activation, and any connection to Kaelin or her stone remain unresolved. See STORY-OPTIONS.md for the decision record and unselected alternatives.

## 9. Enemy and encounter roster

| Source enemy | Proposed role and behavior | Production limit |
|---|---|---|
| Giant Rat construct | Low lunging threat; clear windup, bite, recovery; fearless behavior | One base rig and a small set of attacks |
| Giant Bat construct | Audible anticipation, descending sweep, grounded recovery | Avoid extended airborne waiting |
| Slime | Gray mud rises into an attack; teaches spacing and hazard boundaries | Silhouette must separate from the floor before damage |
| Guardian of Zar’gonud | Black armor with gold trim, red rune-lit sockets; elite guarding the lever | First major encounter, expanded from an existing enemy |
| Goblin | Defined in monster data; no placed story encounter in supplied opening | Excluded from the opening until its setting role is approved |
| Golem | Threat described by Kaelin; guards a door and recognizes the Scepter | Encounter type and appearance depend on approved continuation |

Start most encounters with one enemy. Carefully authored pairs can follow once spacing is taught. The Guardian should test windup recognition, stamina management, and a punish window. No new named boss, mandatory golem kill, additional god, or unsupported enemy origin enters production through this roster.

## 10. Art and audio direction

Build the PS2 impression through low-poly silhouettes, hand-painted wear, compact textures, deliberate color palettes, and restrained effects. Suggested first budgets: 1,500–4,000 triangles for ordinary characters, up to 8,000 for a major encounter, and 128–512 px texture sets with selective 1,024 px hero assets. These are style starting points, not historical hardware claims or measured performance budgets.

Ash gray stone, rain-darkened timber, iron, faded cloth, and ruined gothic forms dominate. Preserve observed rune colors: dim yellow on the statue; gold on rat/bat markings; blue on Kaelin and her stone; red in the Guardian's sockets and crypt-door circle. These associations do not establish a universal rune taxonomy.

Use modern skeletal blending, reliable collision, soft atmospheric lighting, and restrained screen effects. Optional low-resolution rendering or dithering may support the look; keep UI resolution independent. Vertex wobble, texture distortion, heavy bloom, and film grain are optional experiments, not visual requirements.

Audio priorities: spatial footsteps, incoming attacks, weapon contact, rat movement, bat screech, mud activity, wind/rain transitions, the statue's hum, and layered pit voices. Preserve the contrast between a valley avoided by ordinary animals and the unnatural creatures inside. Do not fill the valley with normal birdsong. Use limited music to support discovery and encounter escalation. All spoken or whispered narrative information needs subtitles.

## 11. UI, accessibility, and technical expectations

HUD: health/stamina/mana, selected spell, quick item and quantity, compact interaction prompt, boss/elite health only when relevant. The rune stone can frame the character sheet using its existing holographic-text description; additional functions require review.

Support scalable text, readable contrast, remapping, controller glyphs, independent audio sliders, sensitivity settings, and toggles/sliders for camera shake, motion blur, and flashes. Telegraph hazards using shape, animation, and sound as well as color. Pause single-player gameplay in menus. Repeat tutorial instructions through an optional help page.

Use stable frame pacing and frame-rate-independent movement. Choose a reference PC and test resolution before claiming 60 fps. Validate camera behavior in the prison and bat fight before building the full world. Keep art, dialogue, enemy values, and persistent state editable without rewriting unrelated systems. The old Python files supply source material; they are not a requirement to use Python as the 3D runtime.

## 12. Scope and delivery gates

### Proposed 2–4 hour pacing budget

| Segment | Target including ordinary exploration/retries | Story status |
|---|---|---|
| Pass, outer city, prison | 20–35 minutes | Existing opening adapted |
| Inner market and sewers | 30–50 minutes | Existing opening adapted |
| Crypts and keep | 40–80 minutes | New plot and layout need approval |
| Climax and ending | 20–40 minutes | New plot needs approval |
| Optional exploration/retry margin | 10–35 minutes | Tune against playtests |

Total budget: 120–240 minutes. Experienced repeat runs will be shorter. Do not pad this with long boss runs, repetitive enemies, oversized corridors, or compulsory resource farming.

### Milestones

1. **Design decisions:** Develop the selected A + R1 direction; confirm unresolved anchor/door details, platform, combat emphasis, engine evaluation criteria, and content ceiling. Then obtain the repository's required plan/design reviews before implementation.
2. **Combat prototype:** One graybox space, player controller/camera, rat, dagger/sword, stamina, spell, healing, death and retry placeholders. Gate: movement and combat feel coherent before decorative production.
3. **Opening vertical slice:** Approximately 15–25 minutes through Kaelin and the prison, with one representative finished scene. Gate: both statue branches, fallback weapon, key chain, and save/reload work.
4. **Existing opening complete:** Inner market, sewer branches, Guardian, crypt threshold. Gate: route and story fidelity review; all starts can finish without purchases.
5. **Approved continuation:** Add only the selected crypt/keep/climax design. Gate: creator reviews new lore and ending in context.
6. **Release candidate:** Full playthrough, reference-hardware performance, save migration/recovery, accessibility, audio, and content checks.

**Excluded from the initial scope proposal:** multiplayer, open world, procedural dungeons, crafting, hunger/survival meters, mounts, randomized gear affixes, extensive character sculpting, large quest chains, and a second campaign. Optional advanced combat features must fit the same schedule and asset ceiling.

### Acceptance criteria

- A new player can state the next practical objective without reading every optional dialogue branch.
- Both accepted/refused statue and dagger paths reach the prison with a usable weapon; optional lore remains optional.
- Prison and sewer keys, the lockbox, lever, rewards, and unique encounter states survive death and reload without duplication or softlock.
- Each attack's visible contact matches damage; dodge invulnerability, stamina costs, cast commitments, and input buffering behave consistently.
- The camera keeps threats readable in all required fights, including near walls and against the bat.
- All three classes can complete mandatory encounters without a mandatory purchase or grind.
- Playtests support the 2–4 hour first-completion goal and show that deaths usually have understandable causes.
- The final story review finds no unapproved answer to a protected mystery or change to an established beat.

## 13. Decisions recorded and pending

**Confirmed in this conversation:** 2–4 hour first-playthrough target; short Souls-like game; PS2-inspired low-poly visuals with modern feel; stay close to the supplied story; ask the creator directly about story questions/major changes; continuation A (Contain the breach) and resurrection R1 (Checkpoint anchors), selected in-session with “right now, let's go for A +R1”.

**Still pending:** detailed ending execution within A, anchor origin/activation/presentation within R1, platform, engine, precise difficulty/defense emphasis, door geography, and golem/petrification rules. Mechanical values and production ceilings remain proposals. See [STORY-OPTIONS.md](STORY-OPTIONS.md) for concrete story alternatives.

**Maintain this draft when:** the creator resolves an open decision; source story changes; an approved adaptation changes a story beat; prototype measurements change combat targets; playtests change the runtime budget; platform/engine selection constrains scope. Approved decisions must be dated and attributed before entering the canonical project documentation.
