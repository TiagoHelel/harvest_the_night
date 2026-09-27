# Backlog - HARVEST THE NIGHT

`####....................`  **19 / 108 done**

0 doing / 89 todo / 0 blocked across 9 phases.

Run one task - `/next-task`, which reads
`implementation/prompts/00-RUNNER-LOOP.md` and does exactly one:

```
/next-task
```

Keep going until it is all ticked:

```
/loop /next-task
```

First up: **0020 - The shop: sell and buy**. The whole of what is left is
spelled out under *What is open* below, ready ones first.

The boxes below are **generated** from the `Status:` line inside each
prompt file. Do not tick them by hand: use `python tools/task.py done 0042`,
which rewrites this file for you.

## What is open

89 task(s) left, the ready ones first, then what they
unlock. Generated from `tools/backlog/part*.py` together
with the prompt files, so the two cannot disagree.

### 0020 - The shop: sell and buy

Ready to pick up.  Likely files: `src/core/shop.gd, src/ui/shop_panel.gd`.

Money, and the first reason to care about which resource you gathered.

- Sell any sellable resource at the price in game_data; the reference sheet's prices are the starting point
- Buy wheat seed and, later, whatever 0040 adds
- A panel that opens on interacting with the stall and closes on cancel, pausing nothing
- Buying and selling both go through the ledger
- The shop refuses a sale it cannot pay for rather than going negative

  - done when: Selling ten wood gives exactly the listed price times ten
  - done when: `input_check` opens the shop, sells something and closes it

### 0021 - The day HUD

Ready to pick up.  Likely files: `src/ui/day_hud.gd`.

The bar across the top of the reference sheet: what day it is, what you have, and the button that starts the night.

- Day counter, money, and the resources that matter, laid out like section 14 of the design document
- A resource that changes flashes briefly so a gain is visible without watching the number
- The night button sits bottom right and says what it will do
- The HUD reads state and holds none of its own
- It survives a window resize at every supported integer scale

  - done when: Gathering wood updates the HUD the same tick
  - done when: The night button is reachable by keyboard as well as mouse
  - done when: `input_check` presses it

### 0028 - Corn and carrot

Ready to pick up.  Likely files: `src/core/farming.gd, src/core/game_data.gd`.

Three crops with a real choice between them: fast and cheap, slow and valuable, and one that feeds the defence.

- Wheat, corn and carrot, differing in growth time, sale price and what they feed into
- A crop is a data entry; adding a fourth takes no code
- Seed cost and sale price are set so no crop strictly dominates - show the arithmetic in the journal
- Corn is the defence crop: it is what gunpowder and rations come from later
- The planting menu shows time to grow and price per tick of growth

  - done when: A fourth crop is one dictionary entry - check it and say so
  - done when: No crop is the right answer at every money level
  - done when: `headless_check` asserts each crop's yield and timing

### 0030 - Fishing

Ready to pick up.  Likely files: `src/core/fishing.gd`.

The pond earns its place: the highest value per action on the farm, paid for with attention rather than resources.

- Cast from a shore or jetty tile facing water, on the interact action
- A bite after a seeded random delay inside a lever range, then a window to react
- Common and rare fish, with the rare chance a lever
- Missing the window loses nothing but the time
- Fish sell high and feed cooking later

  - done when: The bite delay is drawn from the run RNG and replays identically
  - done when: Fishing with no reaction for a whole day yields nothing and crashes nothing
  - done when: `input_check` lands one fish

### 0031 - Iron from the rock face

Ready to pick up.  Likely files: `src/core/gathering.gd, src/core/game_data.gd`.

The resource that gates towers. Iron should feel like the thing you are always a little short of.

- Iron comes only from the rock face region, and only from ore nodes, not loose rocks
- Ore takes longer per hit than stone and yields less
- Ore respawn is slower than stone respawn and both are levers
- A day's mining should buy roughly one tower - state the arithmetic in the journal
- Iron is not sellable at a profit against what a tower costs

  - done when: Mining a full day yields iron inside the range the journal claims
  - done when: The rock face cannot be exhausted permanently

### 0032 - Oil

Ready to pick up.  Likely files: `src/core/crafting.gd, src/core/game_data.gd`.

Fire needs fuel. Oil is pressed rather than gathered, which makes it the first resource that costs a building.

- A press that turns corn or fish into oil over ticks
- Oil feeds the flamethrower tower and incendiary ammunition
- Oil is the most valuable thing to sell and the most useful to keep: that tension is the point
- Press throughput is a lever

  - done when: Oil can be produced and sold, and the sale is a real temptation against the flamethrower cost
  - done when: `headless_check` runs the press for a known number of ticks

### 0036 - The inventory

Ready to pick up.  Likely files: `src/core/inventory.gd, src/ui/inventory_panel.gd`.

Somewhere to see everything at once, which the HUD cannot do once there are twelve resources.

- A panel listing every resource with its amount and its sale price
- Grouped the way the reference sheet groups them
- Opens and closes on one key without pausing the day
- It is a view of the ledger, not a second store of truth

  - done when: Every resource in game_data appears without being listed twice
  - done when: Adding a resource to game_data makes it appear with no UI edit

### 0080 - A pixel font

Ready to pick up.  Likely files: `tools/gen_font.py, assets/fonts/`.

Type that is crisp at 480x270 and does not fight the art.

- A bitmap font generated from the same kind of ASCII maps as the sprites
- Full Latin-1 coverage, so Portuguese accents work when 0097 arrives
- Two sizes: HUD and heading
- No filtering, no hinting, integer positions only
- Numbers are tabular so a counter does not jitter

  - done when: Every accented character in the Portuguese strings renders
  - done when: A changing number does not shift the text around it

### 0083 - Audio buses and a sound manager

Ready to pick up.  Likely files: `src/app/audio.gd, default_bus_layout.tres`.

Master, SFX and Music buses plus a small `Audio.play(id)`, so the sound tasks after this only have to drop in files.

- Three buses in `default_bus_layout.tres`
- `Audio` autoload mapping a string id to a stream and a bus
- Volumes read from Settings on boot and on `changed`
- An unknown id warns once and stays silent
- A polyphony cap and a same-frame dedupe, so twenty towers firing on one tick cannot clip

  - done when: `Audio.play('missing')` warns exactly once and does not crash
  - done when: Master at zero silences everything including music
  - done when: Twenty simultaneous shots produce one clean sound, not clipping

### 0103 - Crash and error reporting

Ready to pick up.  Likely files: `src/app/crash.gd`.

When it breaks on someone else's machine, get enough to fix it without them.

- A handler that writes state, seed, tick, phase and the last log lines to `user://crash/`
- A dialogue offering the file's location rather than vanishing
- The run save is preserved, not overwritten by the crash
- No personal data in the report - say what is in it
- It never sends anything anywhere by itself

  - done when: A deliberate crash produces a report with the seed and the tick
  - done when: The run is still loadable afterwards

### 0022 - Switching reality

Waits on 0021.  Likely files: `src/ui/world_view.gd, src/core/phases.gd`.

The same farm, a different world. Press the button and the day farm becomes the night map: same tiles, same buildings, new rules and a new light.

- The switch is a phase transition, not a scene change: the grid object is the same object
- Day and night tint, and a short transition between them
- Day-only actors leave and night-only actors arrive as part of the transition
- The player recognises the farm instantly: nothing moves, only the light and what is on it
- Switching is allowed from DAY only, and lands in PREPARATION

  - done when: A building placed by day is in the same cell by night
  - done when: Switching twice returns to a day that is identical except for the day counter
  - done when: The transition is skippable and the game does not wait on it

### 0029 - Growth stages and watering

Waits on 0028.  Likely files: `src/core/farming.gd`.

A field you can read at a glance, and one small daily chore that rewards coming back.

- Four visible stages per crop, driven by the growth ticks already in data
- Watering a tile speeds growth by a lever percentage until the next night
- Unwatered is slower, never fatal - this is a cozy game, not a punishment
- Water comes from the pond and the well, with a range or a carry limit that is a lever
- Watering the whole field is one held input, not forty clicks

  - done when: A watered and an unwatered tile planted together finish a measurable distance apart
  - done when: Holding the water input across a row waters the row once each

### 0033 - The generator and energy

Waits on 0031.  Likely files: `src/core/power.gd`.

Energy, the resource on the reference sheet that gates the advanced structures and makes placement matter.

- A generator burns a fuel over ticks and produces energy
- Energy is a rate, not a stockpile: structures draw it while they run
- A structure with no power runs at a reduced rate rather than switching off - degraded, not dead
- The HUD shows supply against draw
- Generator output, fuel burn and each structure's draw are levers

  - done when: Building one structure too many visibly slows everything rather than stopping it
  - done when: Running out of fuel mid-night degrades the defence and the night still resolves

### 0034 - Cooking: food and meat

Waits on 0030, 0028.  Likely files: `src/core/crafting.gd`.

The kitchen from the reference sheet: raw crops and fish become food, which is what repairs and heals during the night.

- Recipes turning crops, fish and meat into food
- Food is the night's repair and heal currency, per the design document's resource table
- Cooked food is worth more than its inputs sold separately, or the kitchen has no reason to exist
- Meat comes from the farm animals on the reference sheet; keep it to a passive trickle, not an animal husbandry system

  - done when: A cooked dish sells for more than its inputs - state the margin
  - done when: Food spent on repair during a night is taken through the ledger

### 0037 - The workshop queue

Waits on 0036.  Likely files: `src/core/crafting.gd, src/ui/workshop_panel.gd`.

Semi-idle in one feature: queue five things, walk away, come back to five things.

- A queue per production building with a length that is a lever
- Inputs are taken when an item starts, not when it is queued
- Cancelling a queued item that has not started refunds it in full
- The queue advances on the tick whether or not the player is looking
- The panel shows time remaining on the current item

  - done when: Queue three barricades, walk to the pond and back, and three exist
  - done when: Cancelling the second of three leaves the first and the third intact

### 0039 - The day clock and dusk

Waits on 0021.  Likely files: `src/core/phases.gd, src/ui/day_hud.gd`.

Time passing, without taking away the design document's promise that the player switches reality when they want to.

- A day is a lever's worth of ticks and the HUD shows it as a clock or a sun
- The light warms and then cools across the day
- At dusk the night button starts asking to be pressed; it does not press itself
- Past dusk the day keeps running, with a gentle nudge rather than a penalty
- Time does not pass in menus

  - done when: A player who ignores the clock entirely is not punished for it
  - done when: The clock stops in the shop panel and resumes on close

### 0040 - The shop grows

Waits on 0020, 0028.  Likely files: `src/core/shop.gd, src/ui/shop_panel.gd`.

Somewhere for money to go: all three seeds, materials when you are short, and the first upgrades.

- Seeds for all three crops, and materials at a markup over their sale price
- Buying materials is always worse than gathering them, so money cannot replace playing
- A small daily stock that refreshes, so the shop cannot be drained into an exploit
- Prices in game_data, every one a lever
- Buy and sell are two tabs, not two shops

  - done when: Buy-then-sell on the same item loses money at every price
  - done when: Stock refreshes once per day and not once per visit

### 0084 - The sounds of the day

Waits on 0083.  Likely files: `tools/gen_sfx.py, assets/sfx/`.

Chop, mine, till, plant, water, the fishing splash and the bite, the craft, the sale - generated, not licensed.

- `tools/gen_sfx.py` synthesises every effect to WAV and is deterministic
- Every day verb has a sound and a small random pitch so repetition does not grate
- Cozy, soft, short: the day is the calm half
- The bite is the most attention-grabbing sound of the day, because it is the only one with a window

  - done when: Chopping a tree for a full minute does not become annoying - go and check
  - done when: Regenerating produces byte-identical files

### 0023 - Build mode

Waits on 0022.  Likely files: `src/ui/build_mode.gd, src/core/building.gd`.

Placing things on the farm: pick a structure, see where it can go, pay for it, put it there.

- A build palette of what the player owns or can afford
- A ghost under the cursor, green where it fits and red where it does not, with the reason on hover
- Cost is checked and taken on placement, through the ledger
- Right click sells the structure under the cursor back for a fraction, and the fraction is a lever
- Build mode works in DAY and PREPARATION, and in NIGHT only for what 0053 later allows

  - done when: A structure cannot be placed on water, rock or another structure
  - done when: Placing and selling in a loop neither creates nor destroys resources beyond the sell fraction
  - done when: `input_check` places one and sells it

### 0025 - Zombies walk to the house

Waits on 0022.  Likely files: `src/core/enemies.gd, src/core/pathing.gd`.

Something to shoot at. Zombies come in from the edges and head for the farmhouse, and the house has hit points.

- A flow field computed once from the house over the walkable grid, not A* per zombie - it is cheap, it is deterministic and it will hold a hundred of them
- The field is recomputed only when the grid changes
- Spawn points are edge cells in data; spawn order and timing come from the seeded RNG
- Reaching the house deals damage and removes the zombie
- House hit points are a lever and hitting zero ends the night

  - done when: Fifty zombies pathing costs under a millisecond a tick
  - done when: Two runs from one seed produce the same zombie positions at tick 1000
  - done when: A zombie with no path at all stands still rather than crashing

### 0035 - Gunpowder and ammunition

Waits on 0032, 0033.  Likely files: `src/core/crafting.gd, src/core/towers.gd`.

Towers that consume something. The clearest possible version of 'what you made today decides what tonight can do'.

- Gunpowder from corn and oil; incendiary rounds from oil and wood
- A tower draws from a shared ammunition pool at a rate that is a lever
- Out of ammunition means a much slower basic shot, never a silent dead tower
- The night HUD shows the pool draining
- Ammunition left over carries into the next night

  - done when: A night fought with no gunpowder is survivable but clearly worse
  - done when: The pool drains at the rate the levers claim over a scripted night

### 0038 - Production runs while you are elsewhere

Waits on 0037, 0029.  Likely files: `src/core/sim.gd`.

The feeling the design document asks for: 'I built a machine and now I want to find out whether it works'.

- Crops, presses, generators and queues all advance on the same tick regardless of camera or player position
- No system may depend on being on screen - find and remove any that does
- Returning to a building shows what happened while away, not a silent jump
- A day spent entirely fishing still produces from everything else

  - done when: A scripted day where the player never leaves the pond still finishes the crafting queue
  - done when: The tick cost of a fully built farm stays inside the budget

### 0041 - The first day teaches itself

Waits on 0039, 0040.  Likely files: `src/core/tutorial.gd`.

Day 1 should teach chop, plant, craft, build and the night button without a wall of text or a cage.

- Prompts appear on the thing they describe and disappear when it is done
- Nothing is locked: a player who already knows can ignore all of it
- Night 1 stays the tutorial night the design document asks for - a handful of basic zombies
- Seven lines of text at most in the whole first day
- A profile flag so it never shows twice

  - done when: Someone who has not seen the game reaches the first night without being told anything out loud
  - done when: Skipping every prompt still leaves a winnable night 1

### 0071 - The two palettes

Waits on 0022.  Likely files: `tools/gen_sprites.py, src/ui/palette.gd`.

Section 18: warm and cozy by day, blue and purple by night, from one set of sprites. The reference sheet is the target.

- One base palette, around 32 colours, sampled from `docs/reference-sheet.png`
- A day ramp and a night ramp, applied as a shader or a modulate, never as a second set of PNGs
- The night ramp keeps the farm recognisable: same shapes, different light
- Fire, lamps and the moon are the only warm things at night
- Both ramps are data and can be tuned without regenerating sprites

  - done when: Switching reality changes nothing but the light, and the farm is instantly recognisable - the whole point of the design document
  - done when: A screenshot of each sits next to the reference sheet and holds up

### 0086 - Two pieces of music

Waits on 0083, 0022.  Likely files: `tools/gen_music.py, assets/music/`.

One warm loop for the farm, one cold one for the night, and a crossfade on the reality switch.

- Generated, looping cleanly, a couple of minutes each
- The two share a motif, so the night is recognisably the same farm
- A crossfade tied to the transition length
- An intensity layer that comes in on the last wave of a night
- Music is off in menus by default, and that is a setting

  - done when: The loop point is inaudible
  - done when: The crossfade lands with the transition, not before or after it

### 0024 - The shooting tower

Waits on 0023.  Likely files: `src/core/towers.gd`.

The first thing that fights for you: cheap, single target, medium range, fires by itself.

- Range, rate of fire, damage and cost are levers
- Targeting is deterministic: nearest to the house, ties broken by entity id, never by iteration order
- It fires on the tick, and reload is counted in ticks
- A projectile with travel time, not an instant hit - the night should be watchable
- It does nothing at all during DAY

  - done when: Two runs from the same seed fire at the same targets on the same ticks
  - done when: A tower with nothing in range costs no measurable time per tick
  - done when: Halving the rate of fire lever halves the shots in a fixed number of ticks

### 0046 - Fences and walls

Waits on 0023.  Likely files: `src/core/building.gd, src/core/pathing.gd`.

The other half of a tower defence: making the zombies walk where you want them to.

- A fence is cheap wood with low hit points; a wall is stone and slow to break
- Walls change the flow field, and the field is rebuilt when one is placed or destroyed
- A wall cannot fully seal the house: if every path is blocked, zombies attack the nearest wall instead of standing still
- Placing shows the path the zombies will take afterwards
- Hit points and cost are levers

  - done when: Walling a lane visibly reroutes the next wave
  - done when: Sealing the farm completely makes them break in rather than freeze
  - done when: The field rebuild cost stays inside the budget with fifty walls

### 0072 - The farm tileset

Waits on 0071.  Likely files: `tools/gen_sprites.py, sprites/terrain/`.

Grass, soil, water, rock, path, wooden floor and fence, with edges that meet each other properly.

- Autotiling for grass to soil, grass to water and path edges
- Water animates: two or three frames, slow
- Soil has a tilled and a watered variant
- Small scattered detail tiles so the field is not a flat colour
- All of it from the ASCII maps, all regenerable

  - done when: No visible seam anywhere on the farm
  - done when: Regenerating produces byte-identical files

### 0073 - The player sprite

Waits on 0071.  Likely files: `tools/gen_sprites.py, sprites/actors/`.

Somebody worth watching walk around: four directions, walking, and the work verbs.

- Four facings, idle and walk, plus chop, mine, water, fish and craft
- 16x24, on the same palette as everything else
- A shadow, because without one the character floats
- The animation is driven by the core state's action, not by the view guessing
- Frame counts and speeds are data

  - done when: Every verb in the game has an animation and none plays the wrong one
  - done when: Walking diagonally picks a facing and stays with it

### 0076 - Night lighting

Waits on 0071, 0022.  Likely files: `src/ui/lighting.gd`.

The half of the reference sheet that sells the whole idea: the same farm, lit by the moon and by what is burning.

- A CanvasModulate for the night ramp and real 2D lights on top
- Lit: house windows, braziers, tower muzzle flashes, fires, the mortar's blast
- Light is cosmetic: it never changes a rule or the hash
- A quality setting, because lights are what will cost frames
- The moon gives a soft global fill so the farm is never unreadable

  - done when: The night screenshot sits next to the reference sheet and holds up
  - done when: Turning lighting off changes nothing about the outcome of a night
  - done when: Frame time on a full board stays inside the budget with lights on

### 0079 - Resource icons and the UI kit

Waits on 0071, 0021.  Likely files: `tools/gen_sprites.py, sprites/ui/`.

The bottom half of the reference sheet: an icon per resource, and the panels, frames and buttons they sit in.

- One 16x16 icon per resource, in the reference sheet's style
- Nine-slice panel, button in its four states, tab, slider, checkbox, tooltip frame
- Icons are told apart at native resolution without their labels
- The same kit serves the day HUD, the night HUD, the shop and the tech tree
- All generated, all regenerable

  - done when: Every resource in game_data has an icon and no icon is orphaned
  - done when: The icon set laid out in a row is recognisable against the reference sheet

### 0026 - The tower kills the zombie

Waits on 0024, 0025.  Likely files: `src/core/combat.gd`.

Close the fight: projectiles land, damage is dealt, zombies die and drop what the night pays.

- Damage resolution in one place, so every later tower and enemy goes through it
- Overkill is not wasted on a second target; a dead target stops being shot at the same tick
- Death removes the entity cleanly with no dangling reference in the state
- Hit, death and the projectile are visible - a kill should read at a glance
- Entity ids are stable and ordered so the hash cannot depend on spawn order

  - done when: A tower clears a lane of ten zombies with the expected number of shots
  - done when: `headless_check` runs a scripted fight and asserts the survivor count

### 0042 - Data-driven defences

Waits on 0024.  Likely files: `src/core/towers.gd, src/core/game_data.gd`.

Before adding five more towers, make a tower a data entry, so the combat code stops growing a branch per structure.

- A structure declares: targeting, damage type, shape, rate, range, cost, energy draw, ammunition use
- The combat code reads the declaration instead of comparing ids
- The shooting tower is ported with no behaviour change at all
- Damage types: impact, fire, explosive - named in one place
- A new tower that deals 3 fire in a radius is one entry and no combat edit

  - done when: The determinism hash is unchanged after the port - that is what makes it a port
  - done when: Adding a test tower takes a data entry only; delete it afterwards and say so

### 0047 - Barricades

Waits on 0046.  Likely files: `src/core/game_data.gd`.

The emergency answer: almost free, almost paper, and placeable while the night is running.

- Cheapest structure in the game, from the workshop's first recipe
- It may be placed during NIGHT, which no other structure may
- It has a short lifetime as well as hit points, so it cannot become a permanent wall
- A limit on how many may be placed per night, and it is a lever

  - done when: Placing one mid-wave buys the measurable seconds the lever claims
  - done when: It expires on its own if it survives the night

### 0049 - Zombies path around walls

Waits on 0025, 0046.  Likely files: `src/core/pathing.gd`.

Make the flow field earn its keep: cost, not just blocked, so zombies prefer the open lane and break through when they must.

- Path cost per terrain and per structure, so a wall is expensive rather than impossible
- A zombie whose cheapest path is still expensive attacks the structure instead of walking around the world
- Recompute is incremental or cached: it must not cost a frame when a wall falls mid-wave
- Deterministic tie-breaking everywhere in the field
- No zombie ever oscillates between two cells

  - done when: A hundred zombies and a maze stay inside the tick budget
  - done when: The same seed and the same maze give the same arrival order
  - done when: A headless test asserts no zombie is in the same pair of cells for 20 ticks

### 0078 - The reality transition

Waits on 0076.  Likely files: `src/ui/transition.gd`.

The moment the game is named after. Two seconds that say: same farm, different world.

- The light drains from warm to cold across the whole farm at once
- Day actors leave and night structures wake during it
- It is skippable, and it never blocks the simulation
- It plays in both directions, and coming back to the farm in the morning is the reward half
- Length is a lever and a setting

  - done when: It is the clip you would put first in a trailer - say in the journal whether it is yet
  - done when: Skipping it lands in exactly the same state as watching it

### 0081 - The UI theme

Waits on 0079, 0080.  Likely files: `assets/theme.tres, src/ui/`.

One Theme resource every control uses, so a colour change is one edit and no screen is the odd one out.

- Every Control style in one Theme: no per-node style overrides anywhere
- Built from the palette and the UI kit, not from Godot's defaults
- Focus, hover and disabled states defined for everything interactive
- A UI scale factor that works at every integer window scale

  - done when: `grep` finds no `add_theme_*_override` left in `src/ui/`
  - done when: Every screen looks like the same game

### 0027 - Three waves, a result screen, and back to the farm

Waits on 0026, 0021.  Likely files: `src/core/waves.gd, src/ui/result_screen.gd`.

**The MVP checkpoint.** Three waves of basic zombies, a night that ends, a payout, and a day 2 that is better than day 1. If this is not fun, nothing after it will be.

- Three waves with a gap between them, all from data
- The night ends when the last zombie of the last wave is gone, or when the house falls
- A result screen showing what survived, what was killed and what it paid
- Surviving pays money and resources; losing costs part of the stock, and both numbers are levers
- Confirming the result returns to DAY with the day counter moved on

  - done when: A human can play: gather, craft, build, fight, get paid, repeat - without the console open
  - done when: The whole first cycle takes about three minutes
  - done when: `headless_check` plays all three waves and asserts the payout
  - done when: Say in the journal whether it was fun, honestly, because that is the question this whole phase exists to answer

### 0043 - The flamethrower tower

Waits on 0042.  Likely files: `src/core/game_data.gd`.

The reference sheet's second tower: expensive, short range, continuous area damage, and it burns oil.

- A cone in front of it rather than a single target
- Damage over time that keeps burning after the zombie leaves the cone
- Burn does not stack into absurdity: refresh the duration, do not add a second instance
- It consumes oil while firing and is much weaker without it
- Cost, range, cone angle, damage and burn duration are levers

  - done when: A crowd walking through the cone takes the damage the levers claim
  - done when: Two flamethrowers on one zombie do not double the burn

### 0044 - The mortar

Waits on 0042.  Likely files: `src/core/game_data.gd`.

The long shot: slow, expensive, splash damage, and it cannot hit what is next to it.

- A minimum range as well as a maximum - this is what makes placement a decision
- A shell with real flight time that lands where the target was aimed, not where it ended up
- Splash with falloff from the centre
- It consumes gunpowder per shot
- Minimum range, flight time, radius and falloff are levers

  - done when: A zombie that walks out of the blast between firing and landing survives - and that reads as fair
  - done when: Splash damage at the edge is the falloff the lever claims

### 0045 - The auto-crossbow

Waits on 0042.  Likely files: `src/core/game_data.gd`.

The reference sheet's last tower: cheap, fast, low damage each, and it hits everything in a line.

- A bolt that pierces, losing a lever's fraction of its damage per target
- It fires along a line the player can see while placing it
- Cheap in iron, hungry for energy - the reason to build the generator
- Strong against the runner, weak against the tank, by construction

  - done when: A line of five zombies takes the falloff the lever claims
  - done when: It is clearly the wrong answer against a tank and clearly the right one against a rush

### 0048 - Mines and traps

Waits on 0042.  Likely files: `src/core/towers.gd, src/core/game_data.gd`.

The reference sheet's mine: no targeting, no upkeep, high damage, and then it is gone.

- Triggers on an enemy entering its cell, not on a timer
- High damage in a small radius, then it removes itself
- It is invisible to the player as a firing thing: no range circle, no target line
- A limited number armed per night, replenished by crafting
- Damage, radius and cost are levers

  - done when: A mine under the choke point kills what the levers say it kills
  - done when: Two mines in adjacent cells do not chain into a fifty damage cascade - or they do, deliberately, and the journal says so

### 0050 - The runner

Waits on 0049.  Likely files: `src/core/game_data.gd`.

The first enemy that changes what you build: fast, fragile, and it arrives before the mortar can reload.

- Roughly twice the basic speed and half the hit points - state the real numbers
- It ignores structures and runs straight for the house
- It punishes a defence made only of slow, expensive towers
- Speed, hit points and reward are levers

  - done when: A crossbow line stops a rush and a mortar alone does not
  - done when: It arrives first when mixed into a wave with basics

### 0051 - The tank

Waits on 0049.  Likely files: `src/core/game_data.gd`.

The enemy that needs concentrated damage: slow, heavy, and it shrugs off chip damage.

- High hit points and a flat reduction against each hit, so many small hits are worse than few big ones
- Slow enough that the player watches it come
- It is the reason the mortar exists
- Hit points, reduction and speed are levers

  - done when: A crossbow wall barely scratches it and a mortar drops it - measure both
  - done when: The reduction cannot take a hit below zero damage

### 0052 - The breaker

Waits on 0049, 0046.  Likely files: `src/core/enemies.gd, src/core/game_data.gd`.

The enemy that goes after what you built: it targets structures first and the house second.

- It picks the nearest structure on its path, not the house
- Extra damage against structures and little against the house
- It makes an undefended tower line a liability, which is the point
- Target selection is deterministic and ordered

  - done when: A wave of breakers dismantles an unprotected tower line
  - done when: With the towers covered, they die before they reach one

### 0075 - Buildings and towers

Waits on 0071, 0042.  Likely files: `tools/gen_sprites.py, sprites/buildings/`.

The house, the workshop, the press, the generator, the shop, and every tower at its three levels.

- Each tower reads as its function: the reference sheet's shapes are the brief
- Three visible levels per tower, recognisably the same tower
- Damaged and destroyed states for everything that can be hit
- Firing frames for the towers that fire
- The house is the landmark: the biggest, warmest thing on the farm, by day and by night

  - done when: A level 1 and a level 3 tower are told apart instantly
  - done when: A damaged wall reads as damaged without a health bar

### 0082 - Screenshots, and actually looking at them

Waits on 0078.  Likely files: `src/tools/shot.gd, implementation/shots/`.

A command that puts the game in a known state and takes the picture, so a visual change can be checked instead of hoped for.

- `shot.gd` takes named scenarios: farm at noon, farm at dusk, a wave mid-fight, the result screen, the tech tree
- It runs headless and writes PNGs under `implementation/shots/<id>/`
- The scenario is built from a seed and a scripted state, so two runs give the same picture
- The runner loop is updated to say: after a visual task, take the shots and look at them

  - done when: One command produces the whole set
  - done when: The set is recognisably the game on the reference sheet

### 0085 - The sounds of the night

Waits on 0083, 0026.  Likely files: `tools/gen_sfx.py, assets/sfx/`.

The other half: shots, the flamethrower, the mortar, impacts, the groan, the death, the wall breaking, the house being hit.

- Every tower and every enemy has its own sound
- The house taking damage is the most alarming sound in the game
- A distance falloff, so the far side of the farm is quieter
- The Giant is audible before it is visible
- The same generator as 0084

  - done when: With eyes closed, a night's audio says roughly what is happening
  - done when: Fifty zombies do not turn into noise

### 0089 - Tooltips

Waits on 0081.  Likely files: `src/ui/tooltip.gd`.

Every cost, stat and icon explains itself, so the game does not need a manual.

- A hover tooltip on resources, structures, recipes, tech nodes and enemies
- It shows the numbers from game_data, never a copy of them
- A short delay before it appears and none before it moves to the next
- It never leaves the screen edge
- Keyboard focus shows the same tooltip as hover

  - done when: Every interactive element has one
  - done when: Changing a lever changes the tooltip with no other edit

### 0091 - The title screen

Waits on 0081.  Likely files: `src/ui/title_screen.gd, scenes/Title.tscn`.

The game currently boots into a farm. Make it boot into a game.

- The farm at dusk behind the title, with the night creeping in - the premise, in one image
- The logo, generated with the same tools as everything else
- Continue, New run, Statistics, Options, Quit
- Continue is absent, not greyed, when there is no save
- Any key or click moves past the ident into the menu

  - done when: Booting lands here and not in a run
  - done when: The screen says what kind of game this is before a word is read

### 0097 - English and Portuguese

Waits on 0081.  Likely files: `src/app/i18n.gd, assets/locale/`.

Every string through a translation table, with pt-BR alongside English - the reference sheet is in Portuguese and so is the audience.

- No literal player-facing string left in code: keys only
- English and pt-BR CSVs, English as the fallback
- A checker that finds missing keys, unused keys and strings that overflow their control
- Language is a setting and applies without a restart
- Plurals and number formatting handled, not concatenated

  - done when: The checker reports zero missing keys in both languages
  - done when: Switching language mid-game updates every visible screen
  - done when: No pt-BR string overflows its control - the checker proves it

### 0053 - Repair during the night

Waits on 0046, 0027.  Likely files: `src/core/building.gd, src/ui/night_hud.gd`.

A reason to be present at night: spend food and wood to put a wall back up while the wave is still coming.

- Repair costs food or wood per hit point restored, and the rate is a lever
- It takes time and the player must be near the structure
- A destroyed structure cannot be repaired, only rebuilt
- The house itself can be repaired, at a worse rate
- Repairing is interruptible

  - done when: Repairing a wall mid-wave measurably changes whether it holds
  - done when: `input_check` repairs something

### 0054 - The player's ability

Waits on 0027.  Likely files: `src/core/ability.gd, src/ui/night_hud.gd`.

One button that lets the player change a night they are losing, without turning the game into an action game.

- One ability with a cooldown in ticks: a flare that slows and damages everything in an area
- The cooldown is long enough that using it is a decision
- It is resolved on the tick like everything else and is in the determinism hash
- It reads clearly on screen: the player should see it working
- Damage, radius, slow and cooldown are levers

  - done when: It turns one losing wave per night, not every wave
  - done when: Two uses in the same second are impossible

### 0055 - Double speed and skipping the night

Waits on 0027.  Likely files: `src/ui/night_hud.gd, src/core/sim.gd`.

The semi-idle promise: if the defence is clearly going to hold, let the player say so and move on.

- 1x, 2x and 4x, implemented as ticks per frame - never as a changed tick rate
- Skip to the end simulates the rest of the night as fast as it can and shows the result
- A skipped night and a watched night give an identical outcome from the same state - this is the test of the whole tick design
- Speed is remembered across nights
- Skipping is refused while the house is under a lever's worth of hit points, because that night is worth watching

  - done when: Watched and skipped nights from one seed produce the same hash
  - done when: 4x does not drop frames on a full board
  - done when: `headless_check` runs a night both ways and compares

### 0056 - The night HUD

Waits on 0027.  Likely files: `src/ui/night_hud.gd`.

Section 14 of the design document: which night, which wave, how the house is doing, and the three buttons.

- Night number, wave counter, house hit point bar, ammunition and energy
- Repair, ability and speed as the three controls, exactly as the design document lays them out
- An incoming wave is announced before it arrives
- The house bar turning dangerous is impossible to miss
- It replaces the day HUD on the phase change, sharing no state

  - done when: Every number on it is readable at 480x270 scaled up
  - done when: `input_check` presses all three controls

### 0057 - Structures take damage and die

Waits on 0046, 0052.  Likely files: `src/core/combat.gd, src/core/building.gd`.

Losing things. A structure that breaks should be a small disaster the player watched happen.

- Every structure has hit points and a visible damage state
- Destruction frees the cell, rebuilds the flow field and leaves rubble that clears by morning
- Damaged structures survive into the next day at their current hit points
- A repair cost that is cheaper than rebuilding, so repairing is the right move
- Nothing in the state dangles after a structure dies

  - done when: Destroying a wall mid-wave reroutes the zombies the same tick
  - done when: A structure at 1 hit point is still working, and looks wounded
  - done when: A night of heavy losses leaves a morning that is still playable

### 0059 - Waves as data

Waits on 0027, 0050, 0051, 0052.  Likely files: `src/core/waves.gd, src/core/game_data.gd`.

Before authoring ten nights, make a night a table. Composition, timing and spawn points become numbers a designer edits, not code.

- A night is a list of waves; a wave is a list of (enemy, count, spawn point, delay)
- Wave gaps and the delay before the first wave are per night
- Spawn points may differ per wave, so a night can come from two sides
- A night definition is validated at load: an unknown enemy id fails loudly
- Total enemy count and total reward per night are computable without running it

  - done when: Editing a wave table changes the night with no code edit
  - done when: `validate()` catches a typo in an enemy id
  - done when: A summary of all ten nights can be printed headlessly

### 0074 - Zombie sprites

Waits on 0071, 0050, 0051, 0052.  Likely files: `tools/gen_sprites.py, sprites/enemies/`.

Four enemies that are told apart at a glance in a dark field at 480x270, which is the only test that matters.

- Basic, runner, tank and breaker, distinct in silhouette before colour
- Walk, attack and death for each
- The Giant, larger, with its telegraph as a distinct pose
- A rim light so they read against the night ramp
- Silhouette test: all five in black at 100% zoom must still be distinguishable

  - done when: The silhouette test passes - put the image in the journal
  - done when: A screenshot of a mixed wave is readable at native resolution

### 0087 - Ambience

Waits on 0084, 0085.  Likely files: `src/app/ambience.gd`.

The bed under everything: birds and water by day, wind and distant groaning by night.

- A day bed and a night bed, cross-fading with the transition
- Positional touches: the pond is louder near the pond
- It ducks under an important sound rather than fighting it
- It is on its own bus so it can be turned down alone

  - done when: Standing still on the farm for a minute is pleasant, not empty
  - done when: The ambience never masks the house-damage sound

### 0092 - The main menu and the router

Waits on 0091.  Likely files: `src/app/app.gd, src/ui/main_menu.gd`.

One router that owns which screen is up, so screens stop knowing about each other.

- An `App` autoload with `goto(state)` and a `state_changed` signal
- States: BOOT, TITLE, MENU, RUN, TECH, STATS, OPTIONS, SUMMARY
- A back stack, so Options returns to whoever opened it
- No `get_node('/root/...')` reaching across screens
- The run becomes one state rather than the root scene

  - done when: Options from the title and from the pause menu both return correctly
  - done when: `input_check` still drives a full night after the refactor

### 0099 - An icon and a boot ident

Waits on 0091.  Likely files: `tools/gen_icon.py, assets/icon.png`.

Something recognisable in a taskbar and on an itch page, and two seconds before the title that are not the Godot logo.

- An icon generated at every size a platform asks for, readable at 16x16
- It says farm and night in one image
- The boot splash is replaced; no default Godot branding anywhere
- A short ident, skippable on any input

  - done when: The 16x16 icon is still recognisable
  - done when: No Godot logo appears anywhere in a release build

### 0101 - Onboarding in seven lines

Waits on 0041, 0097.  Likely files: `src/core/tutorial.gd`.

A stranger reaches night 1 and understands the loop, with no more text than the design document allows.

- Seven lines, total, across the whole first day
- Each appears on the thing it describes
- The reality switch is explained by showing it, not by describing it
- Every line is translated
- Watch someone play it and write down where they stopped

  - done when: A first-time player reaches the end of night 1 without being told anything out loud
  - done when: The journal names where they hesitated, because that is the finding

### 0058 - The Giant

Waits on 0051, 0052, 0057.  Likely files: `src/core/enemies.gd, src/core/game_data.gd`.

The single boss of the MVP: the test of the build you made over nine nights.

- Very high hit points, slow, and it smashes structures on its way through
- It arrives with ordinary zombies, so the player cannot aim everything at it
- It forces concentrated damage: a defence of only cheap towers cannot kill it in time
- One readable telegraph before its heavy attack
- Beating it is the end of the MVP run

  - done when: A well-built night 9 defence beats it with something to spare
  - done when: A defence of nothing but crossbows loses to it
  - done when: It never softlocks the night by becoming unreachable

### 0061 - Night rewards

Waits on 0059.  Likely files: `src/core/rewards.gd`.

Section 12: surviving pays money, resources and technology, and the payout is the reason to go again.

- The payout is computed from the night's data, not hardcoded per night
- A bonus for structures that survived intact, so defending well pays more than barely holding
- The result screen itemises it the way the design document shows
- Rewards go through the ledger
- Every multiplier is a lever

  - done when: The same night defended two ways pays differently, in the right direction
  - done when: The itemised numbers add up to what the ledger received

### 0067 - The autoplayer

Waits on 0059, 0055.  Likely files: `src/tools/autoplayer.gd`.

A robot that plays the ten nights, so balance is measured over hundreds of runs instead of guessed at over three.

- A scripted day policy - gather, craft, build - and a night that runs itself
- Several policies: all towers, all walls, economy first, balanced
- Runs headless, seeded, and reports per night: survived, house hit points left, resources spent
- It is a measuring instrument, not an AI: simple and readable beats clever
- A dominant strategy detector: flag when one policy wins every night by a wide margin

  - done when: 100 seeded runs finish in under two minutes
  - done when: The report names which night kills each policy

### 0077 - Particles

Waits on 0074, 0075.  Likely files: `src/ui/particles.gd`.

Fire, smoke, sparks, dust and the small amount of blood the design document allows - the difference between a hit and a hit that felt like one.

- Muzzle flash, impact spark, explosion, burning, smoke from the chimney and from wreckage, dust when something falls
- Pixel particles on the shared palette, not soft gradients
- A hard cap on live particles, and the cap is a setting
- Particles are view only: never in the state, never in the hash
- Blood is restrained, as section 18 asks

  - done when: A busy wave stays inside the frame budget with particles on
  - done when: Turning them off does not change the outcome of a night

### 0093 - Options: video

Waits on 0092.  Likely files: `src/ui/options_video.gd`.

Resolution, window mode and scaling, done properly for a pixel art game.

- A resolution list built from the monitor, marking the integer multiples of 480x270
- Windowed, borderless and exclusive fullscreen
- Integer scaling on by default, with a toggle and a warning about what turning it off does
- VSync and an FPS cap
- Applied immediately with a revert countdown, so a bad mode cannot strand the player

  - done when: Every listed mode applies and survives a restart
  - done when: Picking an impossible mode reverts on its own within ten seconds

### 0094 - Options: audio

Waits on 0083, 0092.  Likely files: `src/ui/options_audio.gd`.

Master, music, effects and ambience, with a test sound on each.

- Four sliders, each writing to its bus through Settings
- A test sound on release, on the bus being adjusted
- A mute toggle that is separate from a zero slider
- Values persist and apply on boot

  - done when: Each slider affects only its own bus
  - done when: Muting and unmuting restores the previous levels

### 0095 - Options: controls

Waits on 0092.  Likely files: `src/ui/options_controls.gd, src/app/input_actions.gd`.

Named actions instead of hardcoded keys, and a screen to rebind them.

- Every key the game reads is a named action: move, interact, build, cancel, inventory, ability, speed, night, pause
- A rebind screen that detects a conflict and refuses it with the clash named
- Reset to defaults, per binding and for all
- Bindings persist through Settings
- Mouse bindings are included, not a special case

  - done when: `grep` finds no raw keycode left in `src/ui/`
  - done when: A rebound key works immediately and after a restart

### 0096 - The pause menu

Waits on 0092.  Likely files: `src/ui/pause_menu.gd`.

Escape stops the world, and pausing mid-night is safe.

- Pause stops the tick accumulator: no ticks run and none are banked to run later
- Resume, Options, Save and quit, Abandon run
- Pausing mid-night and resuming produces an identical night
- Abandon asks twice and says what will be lost

  - done when: A paused night resumed gives the same hash as an unpaused one
  - done when: Pausing for five minutes does not fast-forward on resume

### 0100 - Exports: Windows and Web

Waits on 0092.  Likely files: `export_presets.cfg, tools/release.py`.

Two builds anyone can run, from one command, with the Web one small enough that a stranger will wait for it.

- `python tools/release.py` builds both and writes them into `build/`
- The Web build excludes `implementation/`, `tools/`, `docs/` and previous builds from the pack - check, because this is where that goes wrong
- A wire-size budget for the Web build, gzipped, and the build fails when it is exceeded
- The Web build takes focus and audio correctly on first click
- The version and the build date are baked in and shown on the title screen

  - done when: Both builds run a full night on a machine without Godot installed
  - done when: The Web build is inside its budget and the number is printed
  - done when: The two builds produce the same determinism hash

### 0107 - Store assets

Waits on 0082, 0099.  Likely files: `tools/gen_marketing.py, build/store/`.

The page it goes on: capsule images, screenshots, the pitch, generated from the game rather than mocked up.

- Capsules at the usual sizes, from the real game and the real palette
- Five screenshots from `shot.gd`, picked to show the loop, not five of the farm
- The elevator pitch from section 20 of the design document, edited to fit a store page
- An animated GIF of the reality switch
- English and Portuguese copy

  - done when: One command regenerates the whole set
  - done when: The screenshots show a day, a night, the switch, a busy wave and the tech tree

### 0060 - The ten nights, authored

Waits on 0059, 0058.  Likely files: `src/core/game_data.gd`.

Section 10 of the design document, as a real difficulty curve: tutorial, more, the runner, the tank, the breaker, the boss.

- Ten nights following the design document exactly: 1 tutorial, 3 first runner, 5 first tank, 7 breakers, 8 large, 9 heavy mix, 10 the Giant
- Each night introduces at most one new thing, and night 2 of a new enemy is where it gets hard
- Enemy count and reward curve upward smoothly - plot it in the journal
- Night 1 is beatable with the tower the tutorial gives you and nothing else
- Night 10 is not beatable without upgrades from the tech tree

  - done when: All ten are playable start to finish
  - done when: The count and reward curves are in the journal as numbers
  - done when: A headless run plays all ten with a scripted build and reports which ones fell

### 0062 - Technology points

Waits on 0061.  Likely files: `src/core/tech.gd`.

The currency of permanent improvement, and the thing that makes night 4 feel different from night 3.

- One point per night survived, plus bonus points for the conditions in data
- Points persist in the run save and are spent in the tech tree
- Points cannot be earned by replaying a night already survived
- The total available across ten nights is fixed and known - print it

  - done when: Ten nights yield exactly the number of points the journal claims
  - done when: Replaying a survived night yields none
  - done when: Points survive a save and a reload

### 0065 - Losing a night costs you

Waits on 0061.  Likely files: `src/core/rewards.gd, src/ui/result_screen.gd`.

Section 3 of the loop diagram: defeat takes part of the stock. It has to hurt enough to matter and little enough to continue.

- A lever's fraction of resources lost, with money and technology untouched
- Structures destroyed in the night stay destroyed
- The night can be retried; the day in between is not skipped
- The result screen says exactly what was lost
- Losing never ends the run in the MVP - it costs a day

  - done when: Losing twice in a row leaves a farm that can still recover
  - done when: The itemised loss matches what the ledger actually lost

### 0068 - A balance sweep over the ten nights

Waits on 0067.  Likely files: `tools/balance.py, implementation/BALANCE.md`.

Use the autoplayer: find the nights that are trivial, the ones that are impossible, and the levers that are doing nothing.

- Sweep the important levers across a range and record the win rate per night
- A written report with the curve, the outliers and a recommendation per lever
- Apply the recommendations and re-run
- A lever that changes nothing across its whole range is reported as dead weight
- The determinism hash will move: record both numbers

  - done when: No night has a win rate of 100% or 0% across every policy
  - done when: The report is in the repository and the applied changes are in game_data

### 0088 - Juice: shake, hit stop, damage numbers

Waits on 0026, 0077.  Likely files: `src/ui/juice.gd`.

Make a kill feel like a kill. Small, cheap, and entirely in the view layer.

- Screen shake scaled to the event, with a cap and a setting to disable it
- A few frames of hit stop on a big hit, implemented without touching the tick rate
- Floating damage numbers, colour-coded by damage type, batched when many land at once
- A flash on a hit entity and a squash on death
- None of it is in core and none of it touches the hash

  - done when: Hit stop does not desynchronise the simulation - prove it with the hash
  - done when: Everything here can be turned off and the game still reads
  - done when: A crowded wave does not spawn a thousand number labels

### 0090 - The log panel

Waits on 0081, 0061.  Likely files: `src/ui/log_panel.gd`.

A short running account of what just happened, because at 4x speed the player will miss things.

- The last few events: a wave arriving, a structure lost, a crop ready, a craft finished
- Colour-coded by severity, with the alarming ones held longer
- It fades when nothing is happening and never covers the farm
- Events are emitted by core as data and formatted by the view
- A key expands it into a scrollable history for the night

  - done when: A night at 4x is followable from the log alone
  - done when: It holds a bounded number of entries and cannot grow without limit

### 0098 - Accessibility

Waits on 0093, 0097.  Likely files: `src/app/a11y.gd, src/ui/options_a11y.gd`.

The cheap things that decide whether a lot of people can play it at all.

- Screen shake, flashing and particle density each separately reducible
- A larger UI scale and a high-contrast HUD option
- Colour-blind safe damage types: shape and icon, never colour alone
- Hold-to-act as an alternative to repeated pressing
- A slower game speed option that scales the tick budget, not the rules

  - done when: Every damage type is identifiable in greyscale
  - done when: The slow speed option does not change the determinism hash
  - done when: The game is playable start to finish with shake and flashing off

### 0105 - A playtest build

Waits on 0100, 0103.  Likely files: `tools/playtest.py`.

A build to put in front of someone, with the instrumentation to learn something from it.

- A build flag that turns on local session logging: nights reached, time per day, what was built, where the run ended
- The log is a local file the player can read and send, never an upload
- A one-page note for the tester: what to try, what to ignore, what to report
- An in-game feedback key that timestamps a note into the log
- It is obvious it is a playtest build

  - done when: A session produces a readable log
  - done when: `tools/playtest.py` summarises a folder of logs into the questions that matter

### 0108 - The devlog and a trailer clip

Waits on 0082, 0107.  Likely files: `tools/devlog.py, docs/devlog/`.

The thing that gets people to look: thirty seconds that show the farm, the switch and the horde.

- A scripted capture: a day of farming, the transition, a night holding, a wall falling
- It is captured from a seeded run, so it can be captured again
- A devlog page from the journal: what the loop was meant to be and what it turned out to be
- Honest about what is not in the MVP
- Both in English and Portuguese

  - done when: The clip is thirty seconds and needs no explanation
  - done when: The devlog is generated from `implementation/PROGRESS.md` rather than written twice

### 0063 - The tech tree

Waits on 0062.  Likely files: `src/core/tech.gd, src/ui/tech_screen.gd`.

Somewhere to spend the points, small enough to read on one screen and real enough to change how a night goes.

- Around twelve nodes, no more: the design document forbids a giant tree in the MVP
- Three branches: production, defence, survival
- Prerequisites are data; a node shows what it needs and what it gives
- It opens from the day HUD and never during a wave
- Spending is confirmed and is not refundable - or is, for a fee, and the fee is a lever

  - done when: Every node is reachable inside ten nights, but not all of them
  - done when: The choice between branches is real: say in the journal which one you would take and why
  - done when: `input_check` buys a node

### 0066 - Night 10 and the end of the run

Waits on 0060, 0058.  Likely files: `src/core/phases.gd, src/ui/result_screen.gd`.

**The MVP is complete here.** Beating the Giant ends the run with a summary that answers the design document's question.

- A run summary: days played, resources gathered, zombies killed, structures lost, the build that won
- The run is recorded to the profile and a new one can be started
- An option to continue past night 10 into 0070's endless mode
- It is a real ending, with a screen worth reaching

  - done when: A full run from day 1 to the Giant can be played in one sitting
  - done when: The journal answers, honestly: after surviving the first night, did you want to go back to the farm and improve? That is the success criterion of the entire MVP

### 0102 - A performance budget

Waits on 0060.  Likely files: `tools/perf.py, src/tools/perf_check.gd`.

A number, checked automatically, instead of a feeling about whether it runs well.

- A budget in milliseconds per frame for the worst case: night 10, everything built, lights and particles on
- A headless benchmark that reports tick cost, path cost and entity count
- Wired into `verify.py`, failing when the budget is exceeded
- A baseline file, moved deliberately the way the hash is
- The report names the most expensive system, so a regression points at itself

  - done when: The worst case is inside the budget on this machine
  - done when: Adding a deliberately slow loop makes verify fail and name it

### 0104 - Saves survive an update

Waits on 0062.  Likely files: `src/app/save.gd`.

Adding a lever or a tech node must not delete somebody's run.

- A save version and a migration per bump, applied in order
- A missing key takes the default; an unknown key is dropped with a warning
- Golden saves in the repository, one per version, loaded by `verify.py`
- A save that cannot be migrated says so, keeps the file, and offers a new run

  - done when: Every golden save loads and plays
  - done when: Adding a resource to game_data does not break a save that predates it

### 0106 - The release checklist

Waits on 0105, 0099.  Likely files: `implementation/RELEASE.md`.

The list you run before publishing, written once, so nothing is remembered at the wrong moment.

- Every check with its command: verify, exports, save compatibility, the i18n checker, the perf budget, both builds smoke-tested
- Version bump, changelog, and a tag
- A known-issues section that is honest
- A rollback plan in one paragraph
- Run it once, end to end, and fix what it finds

  - done when: Running the list top to bottom produces a publishable build
  - done when: The journal records what the first run of it found, because it will find something

### 0064 - Tower I, II, automatic

Waits on 0063, 0042.  Likely files: `src/core/towers.gd, src/core/game_data.gd`.

The upgrade chain the design document draws: a tower that grows with the run instead of being replaced by a different tower.

- Each tower has three levels, each an entry in data, not a subclass
- An upgrade costs resources on the spot and is gated by a tech node
- Level 3 changes behaviour, not only numbers - that is what earns the word 'automatic'
- The upgrade is visible on the sprite
- Upgrading in place keeps the tower's current hit points proportionally

  - done when: Upgrading a tower mid-preparation works and costs what it says
  - done when: A level 3 tower is clearly better and clearly not free

### 0069 - Run statistics

Waits on 0066.  Likely files: `src/core/stats.gd, src/ui/stats_screen.gd`.

What the player did, kept across runs, because a number going up is its own reason to play another night.

- Per run and lifetime: nights survived, zombies killed by type, resources gathered, structures built and lost, best night reached
- Recorded in core on the tick, read by the screen
- It survives a crash: written with the profile, not at the end of a run
- Reachable from the main menu

  - done when: Killing ten zombies increments by exactly ten
  - done when: Quitting mid-run and returning keeps the run's numbers

### 0070 - Endless nights past ten

Waits on 0066, 0059.  Likely files: `src/core/endless.gd`.

For the player who beat the Giant and wants to know how far the farm goes. Cheap to build, and it answers whether the loop holds past its authored content.

- Waves generated from a curve past night 10, seeded and reproducible
- The curve scales count and mix, never invents an enemy that does not exist
- A Giant every fifth night, scaling
- A best night reached, kept in the profile
- It is off the critical path: a menu option, not the default

  - done when: Night 25 is generated and playable
  - done when: The same seed generates the same night 25 twice

## 0 - Foundation  (12/12)

- [x] **0001** [Godot project scaffold](prompts/0001-project-scaffold.md)
- [x] **0002** [Fixed-timestep deterministic simulation](prompts/0002-sim-tick.md)
- [x] **0003** [game_data.gd, the one file of levers](prompts/0003-game-data.md)
- [x] **0004** [Harden the headless check harness](prompts/0004-headless-check.md)
- [x] **0005** [verify.py and the determinism guard](prompts/0005-verify-and-hash.md)
- [x] **0006** [The phase machine: day, preparation, night, result](prompts/0006-phase-machine.md)
- [x] **0007** [The resource ledger](prompts/0007-resource-ledger.md)
- [x] **0008** [The farm grid](prompts/0008-farm-grid.md)
- [x] **0009** [Settings singleton](prompts/0009-settings.md)
- [x] **0010** [Save the profile and the run](prompts/0010-save.md)
- [x] **0011** [input_check harness](prompts/0011-input-check.md)
- [x] **0012** [Debug overlay](prompts/0012-debug-overlay.md)

## 1 - The first playable build  (7/15)

- [x] **0013** [The world renders](prompts/0013-world-render.md)
- [x] **0014** [Sprites generated from ASCII maps](prompts/0014-sprite-pipeline.md)
- [x] **0015** [The player walks and interacts](prompts/0015-player.md)
- [x] **0016** [Trees and wood](prompts/0016-wood.md)
- [x] **0017** [Rocks and stone](prompts/0017-stone.md)
- [x] **0018** [Wheat: till, plant, grow, harvest](prompts/0018-wheat.md)
- [x] **0019** [The workshop and its first recipe](prompts/0019-workshop.md)
- [ ] **0020** [The shop: sell and buy](prompts/0020-shop.md)
- [ ] **0021** [The day HUD](prompts/0021-day-hud.md)
- [ ] **0022** [Switching reality](prompts/0022-reality-switch.md) - needs 0021
- [ ] **0023** [Build mode](prompts/0023-build-mode.md) - needs 0022
- [ ] **0024** [The shooting tower](prompts/0024-tower-gun.md) - needs 0023
- [ ] **0025** [Zombies walk to the house](prompts/0025-zombies-walk.md) - needs 0022
- [ ] **0026** [The tower kills the zombie](prompts/0026-combat.md) - needs 0024, 0025
- [ ] **0027** [Three waves, a result screen, and back to the farm](prompts/0027-first-loop.md) - needs 0026, 0021

## 2 - The full day  (0/14)

- [ ] **0028** [Corn and carrot](prompts/0028-three-crops.md)
- [ ] **0029** [Growth stages and watering](prompts/0029-growth-stages.md) - needs 0028
- [ ] **0030** [Fishing](prompts/0030-fishing.md)
- [ ] **0031** [Iron from the rock face](prompts/0031-iron.md)
- [ ] **0032** [Oil](prompts/0032-oil.md)
- [ ] **0033** [The generator and energy](prompts/0033-generator.md) - needs 0031
- [ ] **0034** [Cooking: food and meat](prompts/0034-cooking.md) - needs 0030, 0028
- [ ] **0035** [Gunpowder and ammunition](prompts/0035-ammunition.md) - needs 0032, 0033
- [ ] **0036** [The inventory](prompts/0036-inventory.md)
- [ ] **0037** [The workshop queue](prompts/0037-craft-queue.md) - needs 0036
- [ ] **0038** [Production runs while you are elsewhere](prompts/0038-idle-production.md) - needs 0037, 0029
- [ ] **0039** [The day clock and dusk](prompts/0039-day-clock.md) - needs 0021
- [ ] **0040** [The shop grows](prompts/0040-shop-full.md) - needs 0020, 0028
- [ ] **0041** [The first day teaches itself](prompts/0041-tutorial-day.md) - needs 0039, 0040

## 3 - The full night  (0/17)

- [ ] **0042** [Data-driven defences](prompts/0042-defence-data.md) - needs 0024
- [ ] **0043** [The flamethrower tower](prompts/0043-tower-flame.md) - needs 0042
- [ ] **0044** [The mortar](prompts/0044-tower-mortar.md) - needs 0042
- [ ] **0045** [The auto-crossbow](prompts/0045-tower-crossbow.md) - needs 0042
- [ ] **0046** [Fences and walls](prompts/0046-walls.md) - needs 0023
- [ ] **0047** [Barricades](prompts/0047-barricades.md) - needs 0046
- [ ] **0048** [Mines and traps](prompts/0048-traps.md) - needs 0042
- [ ] **0049** [Zombies path around walls](prompts/0049-pathing-walls.md) - needs 0025, 0046
- [ ] **0050** [The runner](prompts/0050-enemy-runner.md) - needs 0049
- [ ] **0051** [The tank](prompts/0051-enemy-tank.md) - needs 0049
- [ ] **0052** [The breaker](prompts/0052-enemy-breaker.md) - needs 0049, 0046
- [ ] **0053** [Repair during the night](prompts/0053-repair.md) - needs 0046, 0027
- [ ] **0054** [The player's ability](prompts/0054-ability.md) - needs 0027
- [ ] **0055** [Double speed and skipping the night](prompts/0055-speed-controls.md) - needs 0027
- [ ] **0056** [The night HUD](prompts/0056-night-hud.md) - needs 0027
- [ ] **0057** [Structures take damage and die](prompts/0057-structure-damage.md) - needs 0046, 0052
- [ ] **0058** [The Giant](prompts/0058-boss-giant.md) - needs 0051, 0052, 0057

## 4 - Ten nights and progression  (0/12)

- [ ] **0059** [Waves as data](prompts/0059-wave-data.md) - needs 0027, 0050, 0051, 0052
- [ ] **0060** [The ten nights, authored](prompts/0060-ten-nights.md) - needs 0059, 0058
- [ ] **0061** [Night rewards](prompts/0061-rewards.md) - needs 0059
- [ ] **0062** [Technology points](prompts/0062-tech-points.md) - needs 0061
- [ ] **0063** [The tech tree](prompts/0063-tech-tree.md) - needs 0062
- [ ] **0064** [Tower I, II, automatic](prompts/0064-tower-upgrades.md) - needs 0063, 0042
- [ ] **0065** [Losing a night costs you](prompts/0065-defeat.md) - needs 0061
- [ ] **0066** [Night 10 and the end of the run](prompts/0066-run-end.md) - needs 0060, 0058
- [ ] **0067** [The autoplayer](prompts/0067-autoplayer.md) - needs 0059, 0055
- [ ] **0068** [A balance sweep over the ten nights](prompts/0068-balance-sweep.md) - needs 0067
- [ ] **0069** [Run statistics](prompts/0069-stats.md) - needs 0066
- [ ] **0070** [Endless nights past ten](prompts/0070-endless.md) - needs 0066, 0059

## 5 - Art and visual direction  (0/12)

- [ ] **0071** [The two palettes](prompts/0071-palettes.md) - needs 0022
- [ ] **0072** [The farm tileset](prompts/0072-tileset.md) - needs 0071
- [ ] **0073** [The player sprite](prompts/0073-player-art.md) - needs 0071
- [ ] **0074** [Zombie sprites](prompts/0074-zombie-art.md) - needs 0071, 0050, 0051, 0052
- [ ] **0075** [Buildings and towers](prompts/0075-building-art.md) - needs 0071, 0042
- [ ] **0076** [Night lighting](prompts/0076-lighting.md) - needs 0071, 0022
- [ ] **0077** [Particles](prompts/0077-particles.md) - needs 0074, 0075
- [ ] **0078** [The reality transition](prompts/0078-transition.md) - needs 0076
- [ ] **0079** [Resource icons and the UI kit](prompts/0079-ui-kit.md) - needs 0071, 0021
- [ ] **0080** [A pixel font](prompts/0080-font.md)
- [ ] **0081** [The UI theme](prompts/0081-theme.md) - needs 0079, 0080
- [ ] **0082** [Screenshots, and actually looking at them](prompts/0082-screenshots.md) - needs 0078

## 6 - Sound and juice  (0/8)

- [ ] **0083** [Audio buses and a sound manager](prompts/0083-audio-buses.md)
- [ ] **0084** [The sounds of the day](prompts/0084-sfx-day.md) - needs 0083
- [ ] **0085** [The sounds of the night](prompts/0085-sfx-night.md) - needs 0083, 0026
- [ ] **0086** [Two pieces of music](prompts/0086-music.md) - needs 0083, 0022
- [ ] **0087** [Ambience](prompts/0087-ambience.md) - needs 0084, 0085
- [ ] **0088** [Juice: shake, hit stop, damage numbers](prompts/0088-juice.md) - needs 0026, 0077
- [ ] **0089** [Tooltips](prompts/0089-tooltips.md) - needs 0081
- [ ] **0090** [The log panel](prompts/0090-log-panel.md) - needs 0081, 0061

## 7 - Shell and product  (0/10)

- [ ] **0091** [The title screen](prompts/0091-title-screen.md) - needs 0081
- [ ] **0092** [The main menu and the router](prompts/0092-main-menu.md) - needs 0091
- [ ] **0093** [Options: video](prompts/0093-options-video.md) - needs 0092
- [ ] **0094** [Options: audio](prompts/0094-options-audio.md) - needs 0083, 0092
- [ ] **0095** [Options: controls](prompts/0095-options-controls.md) - needs 0092
- [ ] **0096** [The pause menu](prompts/0096-pause-menu.md) - needs 0092
- [ ] **0097** [English and Portuguese](prompts/0097-i18n.md) - needs 0081
- [ ] **0098** [Accessibility](prompts/0098-accessibility.md) - needs 0093, 0097
- [ ] **0099** [An icon and a boot ident](prompts/0099-icon-ident.md) - needs 0091
- [ ] **0100** [Exports: Windows and Web](prompts/0100-exports.md) - needs 0092

## 8 - Ship the MVP  (0/8)

- [ ] **0101** [Onboarding in seven lines](prompts/0101-onboarding.md) - needs 0041, 0097
- [ ] **0102** [A performance budget](prompts/0102-perf-budget.md) - needs 0060
- [ ] **0103** [Crash and error reporting](prompts/0103-error-report.md)
- [ ] **0104** [Saves survive an update](prompts/0104-save-compat.md) - needs 0062
- [ ] **0105** [A playtest build](prompts/0105-playtest-build.md) - needs 0100, 0103
- [ ] **0106** [The release checklist](prompts/0106-release-checklist.md) - needs 0105, 0099
- [ ] **0107** [Store assets](prompts/0107-store-assets.md) - needs 0082, 0099
- [ ] **0108** [The devlog and a trailer clip](prompts/0108-devlog.md) - needs 0082, 0107
