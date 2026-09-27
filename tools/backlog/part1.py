# -*- coding: utf-8 -*-
"""Backlog part 1: the foundation, then the first playable build.

Phase 1 ends at task 0027, which is the whole point of the MVP: produce,
build, defend, get paid, go back to the farm. Everything after it is growth.
"""

P0 = "0 - Foundation"
P1 = "1 - The first playable build"

TASKS = [
    # =================================================== phase 0 - foundation
    dict(id=1, phase=P0, title="Godot project scaffold", slug="project-scaffold",
         files="project.godot, scenes/Main.tscn, src/ui/main.gd, .gitignore",
         goal="The repository holds a design document and a reference image and "
              "nothing else. Turn it into a Godot 4.7 project that opens, boots "
              "and exports, with the directory layout every later task assumes.",
         req=["Godot 4.7 project at the repository root, renderer "
              "`gl_compatibility` so the Web export works",
              "Base viewport 480x270 at 16px tiles, stretch mode `viewport` with "
              "integer scaling: this is a pixel art game and half pixels are a "
              "bug, not a look",
              "Directories: `src/core/`, `src/ui/`, `src/tools/`, `scenes/`, "
              "`sprites/`, `assets/`, with a one-line README in each saying what "
              "belongs there",
              "`scenes/Main.tscn` boots to a plain screen showing the game name "
              "and the build version from `src/core/build_info.gd`",
              "`.gitignore` for Godot 4 (`.godot/`, `build/`, `*.tmp`, exports)",
              "`export_presets.cfg` with a Windows desktop and a Web preset, both "
              "writing into `build/`",
              "`git init` and one commit if this is not a repository yet"],
         dod=["Opening the project in the editor produces no error or warning",
              "`godot --headless --path . --import` exits 0",
              "Both exports produce a file in `build/`"]),

    dict(id=2, phase=P0, title="Fixed-timestep deterministic simulation",
         slug="sim-tick", deps=[1],
         files="src/core/sim.gd, src/core/rng.gd, src/core/state.gd",
         goal="One tick function that advances the whole world at a fixed rate. "
              "Crop growth, tower fire, zombie walking, the headless tests, the "
              "double speed button and skipping a night all become the same code "
              "run a different number of times.",
         req=["`TICK_HZ = 30` in game_data; `Sim.tick(state)` advances exactly "
              "one tick and returns nothing",
              "The UI accumulates `delta` and calls `tick()` a whole number of "
              "times. A partial tick never happens, and a slow frame catches up "
              "with a cap so it cannot spiral",
              "`src/core/rng.gd`: a seeded PCG the state carries. `randi()` and "
              "`randf()` are banned in `src/core/`, and so is `Time.*`",
              "`state` is plain data - Dictionary and Array of primitives - so it "
              "can be deep-copied, hashed, saved and diffed",
              "`state.tick` is the only clock the rules ever read"],
         dod=["10000 ticks from one seed, run twice, hash identical",
              "Nothing under `src/core/` says `extends Node`",
              "`grep -rE 'randf|randi|Time\\.' src/core/` finds only `rng.gd`"]),

    dict(id=3, phase=P0, title="game_data.gd, the one file of levers",
         slug="game-data", deps=[1],
         files="src/core/game_data.gd",
         goal="Every number a designer would want to turn, in one file, before "
              "there are numbers scattered across ten.",
         req=["Sections: time, crops, gathering, prices, recipes, buildings, "
              "towers, enemies, waves, rewards",
              "`# LEVER` on every balance dial, with the unit and a sane range in "
              "the comment",
              "Data only: no branching, no node references, no logic",
              "Ids are `StringName` constants, never bare strings at the call "
              "site",
              "A `validate()` that cross-checks every id a recipe, wave or "
              "building refers to"],
         dod=["Changing the wheat growth lever changes growth and nothing else",
              "`headless_check` calls `validate()` and it passes",
              "A recipe pointing at a resource that does not exist fails "
              "`validate()` with the offending id in the message"]),

    dict(id=4, phase=P0, title="Harden the headless check harness",
         slug="headless-check", deps=[2, 3],
         files="src/tools/headless_check.gd, tools/verify.py",
         goal="Task 0002 shipped `headless_check.gd` with its own asserts, "
              "because the house rule is that a rule ships with its test. It "
              "has one bad failure mode: **a script error before the final "
              "`quit()` leaves the SceneTree running forever**, so a broken "
              "check hangs the backlog loop instead of failing it. Fix that, "
              "and finish the harness.",
         req=["A script error must end the run non-zero, not idle. Guard "
              "`_initialize()` so anything that escapes still prints and quits",
              "`verify.py` already bounds it with a timeout; keep that as the "
              "belt to this task's braces, and make the timeout message stay "
              "accurate",
              "Add the `GameData.validate()` asserts that task 0003 made "
              "possible",
              "Asserts stay grouped by the task that introduced them, one "
              "function each, so a failure names the design that moved",
              "No dependency on anything in `src/ui/`"],
         dod=["Introducing a deliberate script error makes it exit non-zero "
              "within a second instead of hanging - test this, do not assume it",
              "It finishes in under 10 seconds",
              "It runs with no `.godot/` cache present"]),

    dict(id=5, phase=P0, title="verify.py and the determinism guard",
         slug="verify-and-hash", deps=[4],
         files="tools/verify.py, tools/determinism_hash.txt, "
               "src/tools/determinism.gd",
         goal="A bootstrap `tools/verify.py` already exists so that task 0001 "
              "had something to run. Finish it: write the determinism guard it "
              "is waiting for, and make the export check real.",
         req=["Read the bootstrap first - the check order and the SKIP behaviour "
              "are already there and are not up for redesign",
              "`determinism.gd` runs a fixed scripted scenario for a fixed number "
              "of ticks and prints one integer",
              "`--accept` records a moved hash and prints the old and the new "
              "number; `--fast` skips the exports",
              "The Godot executable comes from `$GODOT`, defaulting to "
              "`C:/Users/PC GAMER DA FAMILIA/Documents/Godot/"
              "Godot_v4.7.2-stable_win64_console.exe`",
              "Every row is timed and the total is printed"],
         dod=["`python tools/verify.py` prints PASS on the scaffold, with SKIPs "
              "for what does not exist yet",
              "Deleting the hash file then `--accept` records a first baseline",
              "Changing a lever makes the hash move and the run FAIL until "
              "`--accept`"]),

    dict(id=6, phase=P0, title="The phase machine: day, preparation, night, result",
         slug="phase-machine", deps=[2, 3],
         files="src/core/phases.gd, src/core/sim.gd",
         goal="The loop the whole game is: DAY to PREPARATION to NIGHT to RESULT "
              "and back to DAY, owned by the rules rather than by a screen.",
         req=["An enum in core plus `state.phase`, `state.day` and `state.night`",
              "Transitions are functions on the state, not signals: "
              "`Phases.begin_night(state)` and friends",
              "DAY and NIGHT both advance by the same `Sim.tick`; only what ticks "
              "inside them differs",
              "PREPARATION is the build step between pressing the night button "
              "and the first zombie: the clock does not run and nothing attacks",
              "RESULT computes the payout and is the only place the day counter "
              "moves"],
         dod=["A headless run walks DAY, PREPARATION, NIGHT, RESULT, DAY with no "
              "UI loaded",
              "The day counter increments exactly once per cycle",
              "Crops do not grow during NIGHT and zombies do not spawn during DAY"]),

    dict(id=7, phase=P0, title="The resource ledger", slug="resource-ledger",
         deps=[3],
         files="src/core/resources.gd",
         goal="One place that owns how much of everything the player has, so no "
              "later system invents its own counter.",
         req=["`add(state, id, n)`, `spend(state, id, n) -> bool`, "
              "`can_afford(state, cost) -> bool` where cost is a Dictionary",
              "`spend` is all-or-nothing: a cost of two things with only one "
              "affordable changes neither",
              "Negative balances are impossible; an attempt is a hard error in "
              "debug and a clamped no-op in release",
              "A running total of everything ever gathered, for the stats screen "
              "later",
              "Resources are the ones on the reference sheet: wood, stone, iron, "
              "food, fish, oil, wheat, corn, meat, gunpowder, money, energy"],
         dod=["Spending more than you have returns false and changes nothing",
              "An atomic multi-resource cost either takes all of it or none",
              "`headless_check` covers both"]),

    dict(id=8, phase=P0, title="The farm grid", slug="farm-grid", deps=[2, 3],
         files="src/core/grid.gd, src/core/farm.gd",
         goal="The farm is one grid and it is the entire world. Day and night are "
              "the same tiles with a different job, which is the whole idea of "
              "the game.",
         req=["40x18 tiles at 16px: about 1.3 screens wide and just over one "
              "tall, which is what the design document asks for",
              "A tile carries terrain (grass, soil, water, rock, path, floor) and "
              "at most one occupant id",
              "Regions marked out in data, not hardcoded coordinates: house, "
              "field, pond, wood, rock face, build space, shop",
              "Water and rock are not buildable; the house tile is never "
              "buildable",
              "`buildable(state, cell)` and `occupant(state, cell)` are the only "
              "way anything asks"],
         dod=["The same grid serves the day screen and the night screen with no "
              "second copy",
              "A headless test places and removes an occupant and the grid is "
              "byte-identical afterwards"]),

    dict(id=9, phase=P0, title="Settings singleton", slug="settings", deps=[1],
         files="src/app/settings.gd, project.godot",
         goal="One place that owns every user setting and writes it to "
              "`user://settings.cfg`, so the options menus later only read and "
              "write it.",
         req=["`Settings` autoload with typed getters grouped as video, audio, "
              "gameplay and controls",
              "Atomic save: temp file then rename, so a crash mid-write cannot "
              "corrupt the config",
              "A `version` field and a migration hook for when keys change",
              "Defaults in one dictionary; an unknown key on load is dropped with "
              "a warning and never crashes",
              "`signal changed(key)` so panels react instead of polling"],
         dod=["Change a value, quit, relaunch: it survived",
              "Delete the file: the game boots on defaults with no error",
              "Corrupt the file by hand: the game boots on defaults and says so "
              "in the log"]),

    dict(id=10, phase=P0, title="Save the profile and the run", slug="save",
         deps=[6, 7, 8],
         files="src/app/save.gd",
         goal="Quitting on day 4 and coming back to day 4. The state is already "
              "plain data, so this is serialisation and versioning, not a "
              "redesign.",
         req=["The run save is the core state plus a version and the RNG stream "
              "position - nothing from `src/ui/`",
              "The profile save holds what survives a run: unlocks, statistics, "
              "settings pointer",
              "Atomic write, and a `.bak` of the previous save kept",
              "Loading a save from an older version runs migrations in order or "
              "refuses with a readable message",
              "A save written mid-NIGHT reloads mid-NIGHT with the wave where it "
              "was"],
         dod=["Save on day 3, quit, load: same resources, same buildings, same "
              "grid",
              "Save mid-night, load, and the determinism hash of the rest of the "
              "night matches an uninterrupted run",
              "A truncated save file is refused, not crashed on"]),

    dict(id=11, phase=P0, title="input_check harness", slug="input-check",
         deps=[5],
         files="src/tools/input_check.gd",
         goal="The other half of the gate: drive real clicks and keys through the "
              "real UI with no human, so a refactor that breaks placing a tower "
              "is caught the same minute.",
         req=["Runs headless against the real scenes, synthesising "
              "`InputEventMouseButton` and `InputEventKey`",
              "A helper to click a world cell and one to click a named control",
              "Prints `N cases, M failed` and exits non-zero on failure",
              "Each case leaves the game in a known state for the next one",
              "It is wired into `verify.py` from this task on"],
         dod=["It drives at least one full interaction end to end",
              "It fails loudly when a control it names is missing, rather than "
              "silently passing"]),

    dict(id=12, phase=P0, title="Debug overlay", slug="debug-overlay",
         deps=[5, 6],
         files="src/ui/debug_overlay.gd",
         goal="The thing you actually want while tuning: what phase, what tick, "
              "what seed, how many entities and what the frame costs.",
         req=["Toggled by an input action, off by default, never in the release "
              "build path",
              "Shows phase, day, night, tick, seed, resource totals and live "
              "entity counts",
              "Shows ticks simulated per frame and the millisecond cost of the "
              "last tick batch",
              "Draws over everything and never steals mouse input"],
         dod=["Toggling it does not move the determinism hash",
              "It shows the tick cost climbing when a hundred zombies are alive"]),

    # ======================================== phase 1 - the first playable build
    dict(id=13, phase=P1, title="The world renders", slug="world-render",
         deps=[8],
         files="src/ui/world_view.gd, scenes/World.tscn",
         goal="Draw the grid the rules own, with a camera that shows the farm the "
              "way the reference sheet does.",
         req=["A TileMapLayer for terrain and a sorted layer for occupants and "
              "actors",
              "The camera is fixed vertically and pans only as far as the 40 tile "
              "width needs; no free zoom",
              "The view reads the core state and never writes to it",
              "Redraw is driven by a dirty flag, not rebuilt every frame",
              "Placeholder colour blocks are fine here - 0014 brings the sprites"],
         dod=["The farm regions are all visible and recognisable on screen",
              "Panning to both edges shows no gap or repeated column",
              "Moving the camera does not move the determinism hash"]),

    dict(id=14, phase=P1, title="Sprites generated from ASCII maps",
         slug="sprite-pipeline", deps=[1],
         files="tools/gen_sprites.py, sprites/",
         goal="Art that a script owns. One palette, one generator, one command - "
              "so the set stays consistent and a colour change is one edit rather "
              "than forty.",
         req=["`tools/gen_sprites.py` turns ASCII maps plus a named palette into "
              "PNGs under `sprites/`",
              "16x16 for tiles and props, 16x24 for actors, drawn on a "
              "transparent background",
              "One palette table shared by every sprite, with the day and night "
              "ramps named",
              "Running it twice produces byte-identical files",
              "Hand-authored PNGs are not allowed: the map is the source"],
         dod=["`python tools/gen_sprites.py` regenerates the whole set",
              "Editing one character in a map changes exactly one pixel",
              "The generated sheet imports with nearest-neighbour filtering and "
              "no mipmaps"]),

    dict(id=15, phase=P1, title="The player walks and interacts",
         slug="player", deps=[13],
         files="src/core/player.gd, src/ui/player_view.gd",
         goal="Somebody to be on the farm: eight-way movement on the grid and one "
              "interact key that does the right thing for whatever is in front of "
              "you.",
         req=["Position and facing live in core and move on the tick, not on the "
              "frame",
              "Movement is blocked by water, rock and occupied tiles",
              "One `interact` action; the target is the tile being faced, with "
              "the tile under the player as a fallback",
              "An `interactable` registry so later tasks add a verb without "
              "touching the player",
              "A highlight on the targeted tile so the player can see what they "
              "will hit"],
         dod=["Walking into the pond stops the player rather than teleporting "
              "them",
              "The same input sequence from the same seed ends at the same cell",
              "`input_check` drives a walk and an interact"]),

    dict(id=16, phase=P1, title="Trees and wood", slug="wood", deps=[15, 7],
         files="src/core/gathering.gd, src/core/game_data.gd",
         goal="The first resource in the world. Hit a tree, get wood, the tree "
              "goes away and comes back.",
         req=["A tree has hit points in ticks of chopping, not a single click",
              "Wood per tree and regrowth delay are levers",
              "A chopped tree leaves a stump that regrows on a timer so the farm "
              "never runs dry",
              "Chopping is interrupted cleanly if the player walks away",
              "The yield is added through the resource ledger, never directly"],
         dod=["Chopping every tree and waiting the regrowth delay restores them "
              "all",
              "A headless run gathers a known amount of wood from a known number "
              "of ticks"]),

    dict(id=17, phase=P1, title="Rocks and stone", slug="stone", deps=[16],
         files="src/core/gathering.gd",
         goal="The second resource, on the same machinery as wood, which is the "
              "test of whether that machinery was general enough.",
         req=["Rocks use the same gathering code with different data, not a "
              "second implementation",
              "Stone per rock and respawn delay are levers",
              "The rock face region respawns rocks; loose rocks on grass do not",
              "Adding stone takes a data entry and no new function"],
         dod=["Adding a third gatherable would be a data entry only - say so in "
              "the journal after checking",
              "`headless_check` covers stone yield the same way as wood"]),

    dict(id=18, phase=P1, title="Wheat: till, plant, grow, harvest",
         slug="wheat", deps=[15, 7, 6],
         files="src/core/farming.gd",
         goal="The crop cycle, which is the semi-idle heart of the day: do a "
              "thing, go away, come back to something better.",
         req=["Four verbs on a soil tile: till, plant, (wait), harvest",
              "Growth advances on the tick during DAY only, never during NIGHT",
              "Growth stages are data, so the sprite can follow them later",
              "A planted tile survives the night and keeps growing the next day",
              "Harvest yields wheat through the ledger and returns the tile to "
              "tilled soil"],
         dod=["Planting, ending the day, surviving a night and returning shows "
              "growth unchanged over the night and resumed after it",
              "The growth lever changes the number of ticks and nothing else"]),

    dict(id=19, phase=P1, title="The workshop and its first recipe",
         slug="workshop", deps=[7, 17],
         files="src/core/crafting.gd",
         goal="The bridge the whole game rests on: day resources become night "
              "structures. Wood plus stone becomes a barricade.",
         req=["Recipes are data: inputs, output, ticks to craft",
              "Crafting takes the inputs at the start, not at the end, so "
              "cancelling costs something",
              "One recipe at a time here; the queue arrives at 0037",
              "The workshop is a building on the grid the player walks to and "
              "interacts with",
              "A recipe whose inputs are short is shown as unaffordable rather "
              "than hidden"],
         dod=["Wood plus stone becomes a barricade in the crafting time and the "
              "resources are gone",
              "Cancelling mid-craft does not refund and does not duplicate"]),

    dict(id=20, phase=P1, title="The shop: sell and buy", slug="shop",
         deps=[7, 18],
         files="src/core/shop.gd, src/ui/shop_panel.gd",
         goal="Money, and the first reason to care about which resource you "
              "gathered.",
         req=["Sell any sellable resource at the price in game_data; the "
              "reference sheet's prices are the starting point",
              "Buy wheat seed and, later, whatever 0040 adds",
              "A panel that opens on interacting with the stall and closes on "
              "cancel, pausing nothing",
              "Buying and selling both go through the ledger",
              "The shop refuses a sale it cannot pay for rather than going "
              "negative"],
         dod=["Selling ten wood gives exactly the listed price times ten",
              "`input_check` opens the shop, sells something and closes it"]),

    dict(id=21, phase=P1, title="The day HUD", slug="day-hud", deps=[7, 6],
         files="src/ui/day_hud.gd",
         goal="The bar across the top of the reference sheet: what day it is, "
              "what you have, and the button that starts the night.",
         req=["Day counter, money, and the resources that matter, laid out like "
              "section 14 of the design document",
              "A resource that changes flashes briefly so a gain is visible "
              "without watching the number",
              "The night button sits bottom right and says what it will do",
              "The HUD reads state and holds none of its own",
              "It survives a window resize at every supported integer scale"],
         dod=["Gathering wood updates the HUD the same tick",
              "The night button is reachable by keyboard as well as mouse",
              "`input_check` presses it"]),

    dict(id=22, phase=P1, title="Switching reality", slug="reality-switch",
         deps=[6, 21],
         files="src/ui/world_view.gd, src/core/phases.gd",
         goal="The same farm, a different world. Press the button and the day "
              "farm becomes the night map: same tiles, same buildings, new rules "
              "and a new light.",
         req=["The switch is a phase transition, not a scene change: the grid "
              "object is the same object",
              "Day and night tint, and a short transition between them",
              "Day-only actors leave and night-only actors arrive as part of the "
              "transition",
              "The player recognises the farm instantly: nothing moves, only the "
              "light and what is on it",
              "Switching is allowed from DAY only, and lands in PREPARATION"],
         dod=["A building placed by day is in the same cell by night",
              "Switching twice returns to a day that is identical except for the "
              "day counter",
              "The transition is skippable and the game does not wait on it"]),

    dict(id=23, phase=P1, title="Build mode", slug="build-mode", deps=[8, 19, 22],
         files="src/ui/build_mode.gd, src/core/building.gd",
         goal="Placing things on the farm: pick a structure, see where it can go, "
              "pay for it, put it there.",
         req=["A build palette of what the player owns or can afford",
              "A ghost under the cursor, green where it fits and red where it "
              "does not, with the reason on hover",
              "Cost is checked and taken on placement, through the ledger",
              "Right click sells the structure under the cursor back for a "
              "fraction, and the fraction is a lever",
              "Build mode works in DAY and PREPARATION, and in NIGHT only for "
              "what 0053 later allows"],
         dod=["A structure cannot be placed on water, rock or another structure",
              "Placing and selling in a loop neither creates nor destroys "
              "resources beyond the sell fraction",
              "`input_check` places one and sells it"]),

    dict(id=24, phase=P1, title="The shooting tower", slug="tower-gun",
         deps=[23],
         files="src/core/towers.gd",
         goal="The first thing that fights for you: cheap, single target, medium "
              "range, fires by itself.",
         req=["Range, rate of fire, damage and cost are levers",
              "Targeting is deterministic: nearest to the house, ties broken by "
              "entity id, never by iteration order",
              "It fires on the tick, and reload is counted in ticks",
              "A projectile with travel time, not an instant hit - the night "
              "should be watchable",
              "It does nothing at all during DAY"],
         dod=["Two runs from the same seed fire at the same targets on the same "
              "ticks",
              "A tower with nothing in range costs no measurable time per tick",
              "Halving the rate of fire lever halves the shots in a fixed number "
              "of ticks"]),

    dict(id=25, phase=P1, title="Zombies walk to the house", slug="zombies-walk",
         deps=[22, 8],
         files="src/core/enemies.gd, src/core/pathing.gd",
         goal="Something to shoot at. Zombies come in from the edges and head for "
              "the farmhouse, and the house has hit points.",
         req=["A flow field computed once from the house over the walkable grid, "
              "not A* per zombie - it is cheap, it is deterministic and it will "
              "hold a hundred of them",
              "The field is recomputed only when the grid changes",
              "Spawn points are edge cells in data; spawn order and timing come "
              "from the seeded RNG",
              "Reaching the house deals damage and removes the zombie",
              "House hit points are a lever and hitting zero ends the night"],
         dod=["Fifty zombies pathing costs under a millisecond a tick",
              "Two runs from one seed produce the same zombie positions at tick "
              "1000",
              "A zombie with no path at all stands still rather than crashing"]),

    dict(id=26, phase=P1, title="The tower kills the zombie", slug="combat",
         deps=[24, 25],
         files="src/core/combat.gd",
         goal="Close the fight: projectiles land, damage is dealt, zombies die "
              "and drop what the night pays.",
         req=["Damage resolution in one place, so every later tower and enemy "
              "goes through it",
              "Overkill is not wasted on a second target; a dead target stops "
              "being shot at the same tick",
              "Death removes the entity cleanly with no dangling reference in the "
              "state",
              "Hit, death and the projectile are visible - a kill should read at "
              "a glance",
              "Entity ids are stable and ordered so the hash cannot depend on "
              "spawn order"],
         dod=["A tower clears a lane of ten zombies with the expected number of "
              "shots",
              "`headless_check` runs a scripted fight and asserts the survivor "
              "count"]),

    dict(id=27, phase=P1, title="Three waves, a result screen, and back to the farm",
         slug="first-loop", deps=[26, 21],
         files="src/core/waves.gd, src/ui/result_screen.gd",
         goal="**The MVP checkpoint.** Three waves of basic zombies, a night that "
              "ends, a payout, and a day 2 that is better than day 1. If this is "
              "not fun, nothing after it will be.",
         req=["Three waves with a gap between them, all from data",
              "The night ends when the last zombie of the last wave is gone, or "
              "when the house falls",
              "A result screen showing what survived, what was killed and what it "
              "paid",
              "Surviving pays money and resources; losing costs part of the "
              "stock, and both numbers are levers",
              "Confirming the result returns to DAY with the day counter moved on"],
         dod=["A human can play: gather, craft, build, fight, get paid, repeat - "
              "without the console open",
              "The whole first cycle takes about three minutes",
              "`headless_check` plays all three waves and asserts the payout",
              "Say in the journal whether it was fun, honestly, because that is "
              "the question this whole phase exists to answer"]),
]
