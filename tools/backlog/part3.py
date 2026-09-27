# -*- coding: utf-8 -*-
"""Backlog part 3: the ten nights and the progression, then the art.

Task 0066 is the end of the MVP as the design document defines it: ten nights,
a boss, and an answer to whether the loop is worth repeating. Phase 5 is what
makes it look like the reference sheet.
"""

P4 = "4 - Ten nights and progression"
P5 = "5 - Art and visual direction"

TASKS = [
    # =========================================== phase 4 - nights and progression
    dict(id=59, phase=P4, title="Waves as data", slug="wave-data",
         deps=[27, 50, 51, 52],
         files="src/core/waves.gd, src/core/game_data.gd",
         goal="Before authoring ten nights, make a night a table. Composition, "
              "timing and spawn points become numbers a designer edits, not code.",
         req=["A night is a list of waves; a wave is a list of (enemy, count, "
              "spawn point, delay)",
              "Wave gaps and the delay before the first wave are per night",
              "Spawn points may differ per wave, so a night can come from two "
              "sides",
              "A night definition is validated at load: an unknown enemy id fails "
              "loudly",
              "Total enemy count and total reward per night are computable "
              "without running it"],
         dod=["Editing a wave table changes the night with no code edit",
              "`validate()` catches a typo in an enemy id",
              "A summary of all ten nights can be printed headlessly"]),

    dict(id=60, phase=P4, title="The ten nights, authored", slug="ten-nights",
         deps=[59, 58],
         files="src/core/game_data.gd",
         goal="Section 10 of the design document, as a real difficulty curve: "
              "tutorial, more, the runner, the tank, the breaker, the boss.",
         req=["Ten nights following the design document exactly: 1 tutorial, 3 "
              "first runner, 5 first tank, 7 breakers, 8 large, 9 heavy mix, 10 "
              "the Giant",
              "Each night introduces at most one new thing, and night 2 of a new "
              "enemy is where it gets hard",
              "Enemy count and reward curve upward smoothly - plot it in the "
              "journal",
              "Night 1 is beatable with the tower the tutorial gives you and "
              "nothing else",
              "Night 10 is not beatable without upgrades from the tech tree"],
         dod=["All ten are playable start to finish",
              "The count and reward curves are in the journal as numbers",
              "A headless run plays all ten with a scripted build and reports "
              "which ones fell"]),

    dict(id=61, phase=P4, title="Night rewards", slug="rewards", deps=[59, 7],
         files="src/core/rewards.gd",
         goal="Section 12: surviving pays money, resources and technology, and "
              "the payout is the reason to go again.",
         req=["The payout is computed from the night's data, not hardcoded per "
              "night",
              "A bonus for structures that survived intact, so defending well "
              "pays more than barely holding",
              "The result screen itemises it the way the design document shows",
              "Rewards go through the ledger",
              "Every multiplier is a lever"],
         dod=["The same night defended two ways pays differently, in the right "
              "direction",
              "The itemised numbers add up to what the ledger received"]),

    dict(id=62, phase=P4, title="Technology points", slug="tech-points",
         deps=[61],
         files="src/core/tech.gd",
         goal="The currency of permanent improvement, and the thing that makes "
              "night 4 feel different from night 3.",
         req=["One point per night survived, plus bonus points for the conditions "
              "in data",
              "Points persist in the run save and are spent in the tech tree",
              "Points cannot be earned by replaying a night already survived",
              "The total available across ten nights is fixed and known - print "
              "it"],
         dod=["Ten nights yield exactly the number of points the journal claims",
              "Replaying a survived night yields none",
              "Points survive a save and a reload"]),

    dict(id=63, phase=P4, title="The tech tree", slug="tech-tree", deps=[62],
         files="src/core/tech.gd, src/ui/tech_screen.gd",
         goal="Somewhere to spend the points, small enough to read on one screen "
              "and real enough to change how a night goes.",
         req=["Around twelve nodes, no more: the design document forbids a giant "
              "tree in the MVP",
              "Three branches: production, defence, survival",
              "Prerequisites are data; a node shows what it needs and what it "
              "gives",
              "It opens from the day HUD and never during a wave",
              "Spending is confirmed and is not refundable - or is, for a fee, "
              "and the fee is a lever"],
         dod=["Every node is reachable inside ten nights, but not all of them",
              "The choice between branches is real: say in the journal which one "
              "you would take and why",
              "`input_check` buys a node"]),

    dict(id=64, phase=P4, title="Tower I, II, automatic", slug="tower-upgrades",
         deps=[63, 42],
         files="src/core/towers.gd, src/core/game_data.gd",
         goal="The upgrade chain the design document draws: a tower that grows "
              "with the run instead of being replaced by a different tower.",
         req=["Each tower has three levels, each an entry in data, not a "
              "subclass",
              "An upgrade costs resources on the spot and is gated by a tech node",
              "Level 3 changes behaviour, not only numbers - that is what earns "
              "the word 'automatic'",
              "The upgrade is visible on the sprite",
              "Upgrading in place keeps the tower's current hit points "
              "proportionally"],
         dod=["Upgrading a tower mid-preparation works and costs what it says",
              "A level 3 tower is clearly better and clearly not free"]),

    dict(id=65, phase=P4, title="Losing a night costs you", slug="defeat",
         deps=[61],
         files="src/core/rewards.gd, src/ui/result_screen.gd",
         goal="Section 3 of the loop diagram: defeat takes part of the stock. It "
              "has to hurt enough to matter and little enough to continue.",
         req=["A lever's fraction of resources lost, with money and technology "
              "untouched",
              "Structures destroyed in the night stay destroyed",
              "The night can be retried; the day in between is not skipped",
              "The result screen says exactly what was lost",
              "Losing never ends the run in the MVP - it costs a day"],
         dod=["Losing twice in a row leaves a farm that can still recover",
              "The itemised loss matches what the ledger actually lost"]),

    dict(id=66, phase=P4, title="Night 10 and the end of the run",
         slug="run-end", deps=[60, 58],
         files="src/core/phases.gd, src/ui/result_screen.gd",
         goal="**The MVP is complete here.** Beating the Giant ends the run with "
              "a summary that answers the design document's question.",
         req=["A run summary: days played, resources gathered, zombies killed, "
              "structures lost, the build that won",
              "The run is recorded to the profile and a new one can be started",
              "An option to continue past night 10 into 0070's endless mode",
              "It is a real ending, with a screen worth reaching"],
         dod=["A full run from day 1 to the Giant can be played in one sitting",
              "The journal answers, honestly: after surviving the first night, "
              "did you want to go back to the farm and improve? That is the "
              "success criterion of the entire MVP"]),

    dict(id=67, phase=P4, title="The autoplayer", slug="autoplayer", deps=[59, 55],
         files="src/tools/autoplayer.gd",
         goal="A robot that plays the ten nights, so balance is measured over "
              "hundreds of runs instead of guessed at over three.",
         req=["A scripted day policy - gather, craft, build - and a night that "
              "runs itself",
              "Several policies: all towers, all walls, economy first, balanced",
              "Runs headless, seeded, and reports per night: survived, house hit "
              "points left, resources spent",
              "It is a measuring instrument, not an AI: simple and readable beats "
              "clever",
              "A dominant strategy detector: flag when one policy wins every "
              "night by a wide margin"],
         dod=["100 seeded runs finish in under two minutes",
              "The report names which night kills each policy"]),

    dict(id=68, phase=P4, title="A balance sweep over the ten nights",
         slug="balance-sweep", deps=[67],
         files="tools/balance.py, implementation/BALANCE.md",
         goal="Use the autoplayer: find the nights that are trivial, the ones "
              "that are impossible, and the levers that are doing nothing.",
         req=["Sweep the important levers across a range and record the win rate "
              "per night",
              "A written report with the curve, the outliers and a recommendation "
              "per lever",
              "Apply the recommendations and re-run",
              "A lever that changes nothing across its whole range is reported as "
              "dead weight",
              "The determinism hash will move: record both numbers"],
         dod=["No night has a win rate of 100% or 0% across every policy",
              "The report is in the repository and the applied changes are in "
              "game_data"]),

    dict(id=69, phase=P4, title="Run statistics", slug="stats", deps=[66, 10],
         files="src/core/stats.gd, src/ui/stats_screen.gd",
         goal="What the player did, kept across runs, because a number going up "
              "is its own reason to play another night.",
         req=["Per run and lifetime: nights survived, zombies killed by type, "
              "resources gathered, structures built and lost, best night reached",
              "Recorded in core on the tick, read by the screen",
              "It survives a crash: written with the profile, not at the end of a "
              "run",
              "Reachable from the main menu"],
         dod=["Killing ten zombies increments by exactly ten",
              "Quitting mid-run and returning keeps the run's numbers"]),

    dict(id=70, phase=P4, title="Endless nights past ten", slug="endless",
         deps=[66, 59],
         files="src/core/endless.gd",
         goal="For the player who beat the Giant and wants to know how far the "
              "farm goes. Cheap to build, and it answers whether the loop holds "
              "past its authored content.",
         req=["Waves generated from a curve past night 10, seeded and "
              "reproducible",
              "The curve scales count and mix, never invents an enemy that does "
              "not exist",
              "A Giant every fifth night, scaling",
              "A best night reached, kept in the profile",
              "It is off the critical path: a menu option, not the default"],
         dod=["Night 25 is generated and playable",
              "The same seed generates the same night 25 twice"]),

    # ==================================== phase 5 - art and visual direction
    dict(id=71, phase=P5, title="The two palettes", slug="palettes", deps=[14, 22],
         files="tools/gen_sprites.py, src/ui/palette.gd",
         goal="Section 18: warm and cozy by day, blue and purple by night, from "
              "one set of sprites. The reference sheet is the target.",
         req=["One base palette, around 32 colours, sampled from "
              "`docs/reference-sheet.png`",
              "A day ramp and a night ramp, applied as a shader or a modulate, "
              "never as a second set of PNGs",
              "The night ramp keeps the farm recognisable: same shapes, "
              "different light",
              "Fire, lamps and the moon are the only warm things at night",
              "Both ramps are data and can be tuned without regenerating sprites"],
         dod=["Switching reality changes nothing but the light, and the farm is "
              "instantly recognisable - the whole point of the design document",
              "A screenshot of each sits next to the reference sheet and holds up"]),

    dict(id=72, phase=P5, title="The farm tileset", slug="tileset", deps=[71, 13],
         files="tools/gen_sprites.py, sprites/terrain/",
         goal="Grass, soil, water, rock, path, wooden floor and fence, with "
              "edges that meet each other properly.",
         req=["Autotiling for grass to soil, grass to water and path edges",
              "Water animates: two or three frames, slow",
              "Soil has a tilled and a watered variant",
              "Small scattered detail tiles so the field is not a flat colour",
              "All of it from the ASCII maps, all regenerable"],
         dod=["No visible seam anywhere on the farm",
              "Regenerating produces byte-identical files"]),

    dict(id=73, phase=P5, title="The player sprite", slug="player-art",
         deps=[71, 15],
         files="tools/gen_sprites.py, sprites/actors/",
         goal="Somebody worth watching walk around: four directions, walking, and "
              "the work verbs.",
         req=["Four facings, idle and walk, plus chop, mine, water, fish and "
              "craft",
              "16x24, on the same palette as everything else",
              "A shadow, because without one the character floats",
              "The animation is driven by the core state's action, not by the "
              "view guessing",
              "Frame counts and speeds are data"],
         dod=["Every verb in the game has an animation and none plays the wrong "
              "one",
              "Walking diagonally picks a facing and stays with it"]),

    dict(id=74, phase=P5, title="Zombie sprites", slug="zombie-art",
         deps=[71, 50, 51, 52],
         files="tools/gen_sprites.py, sprites/enemies/",
         goal="Four enemies that are told apart at a glance in a dark field at "
              "480x270, which is the only test that matters.",
         req=["Basic, runner, tank and breaker, distinct in silhouette before "
              "colour",
              "Walk, attack and death for each",
              "The Giant, larger, with its telegraph as a distinct pose",
              "A rim light so they read against the night ramp",
              "Silhouette test: all five in black at 100% zoom must still be "
              "distinguishable"],
         dod=["The silhouette test passes - put the image in the journal",
              "A screenshot of a mixed wave is readable at native resolution"]),

    dict(id=75, phase=P5, title="Buildings and towers", slug="building-art",
         deps=[71, 42],
         files="tools/gen_sprites.py, sprites/buildings/",
         goal="The house, the workshop, the press, the generator, the shop, and "
              "every tower at its three levels.",
         req=["Each tower reads as its function: the reference sheet's shapes are "
              "the brief",
              "Three visible levels per tower, recognisably the same tower",
              "Damaged and destroyed states for everything that can be hit",
              "Firing frames for the towers that fire",
              "The house is the landmark: the biggest, warmest thing on the farm, "
              "by day and by night"],
         dod=["A level 1 and a level 3 tower are told apart instantly",
              "A damaged wall reads as damaged without a health bar"]),

    dict(id=76, phase=P5, title="Night lighting", slug="lighting", deps=[71, 22],
         files="src/ui/lighting.gd",
         goal="The half of the reference sheet that sells the whole idea: the "
              "same farm, lit by the moon and by what is burning.",
         req=["A CanvasModulate for the night ramp and real 2D lights on top",
              "Lit: house windows, braziers, tower muzzle flashes, fires, the "
              "mortar's blast",
              "Light is cosmetic: it never changes a rule or the hash",
              "A quality setting, because lights are what will cost frames",
              "The moon gives a soft global fill so the farm is never unreadable"],
         dod=["The night screenshot sits next to the reference sheet and holds up",
              "Turning lighting off changes nothing about the outcome of a night",
              "Frame time on a full board stays inside the budget with lights on"]),

    dict(id=77, phase=P5, title="Particles", slug="particles", deps=[74, 75],
         files="src/ui/particles.gd",
         goal="Fire, smoke, sparks, dust and the small amount of blood the design "
              "document allows - the difference between a hit and a hit that felt "
              "like one.",
         req=["Muzzle flash, impact spark, explosion, burning, smoke from the "
              "chimney and from wreckage, dust when something falls",
              "Pixel particles on the shared palette, not soft gradients",
              "A hard cap on live particles, and the cap is a setting",
              "Particles are view only: never in the state, never in the hash",
              "Blood is restrained, as section 18 asks"],
         dod=["A busy wave stays inside the frame budget with particles on",
              "Turning them off does not change the outcome of a night"]),

    dict(id=78, phase=P5, title="The reality transition", slug="transition",
         deps=[76],
         files="src/ui/transition.gd",
         goal="The moment the game is named after. Two seconds that say: same "
              "farm, different world.",
         req=["The light drains from warm to cold across the whole farm at once",
              "Day actors leave and night structures wake during it",
              "It is skippable, and it never blocks the simulation",
              "It plays in both directions, and coming back to the farm in the "
              "morning is the reward half",
              "Length is a lever and a setting"],
         dod=["It is the clip you would put first in a trailer - say in the "
              "journal whether it is yet",
              "Skipping it lands in exactly the same state as watching it"]),

    dict(id=79, phase=P5, title="Resource icons and the UI kit",
         slug="ui-kit", deps=[71, 21],
         files="tools/gen_sprites.py, sprites/ui/",
         goal="The bottom half of the reference sheet: an icon per resource, and "
              "the panels, frames and buttons they sit in.",
         req=["One 16x16 icon per resource, in the reference sheet's style",
              "Nine-slice panel, button in its four states, tab, slider, "
              "checkbox, tooltip frame",
              "Icons are told apart at native resolution without their labels",
              "The same kit serves the day HUD, the night HUD, the shop and the "
              "tech tree",
              "All generated, all regenerable"],
         dod=["Every resource in game_data has an icon and no icon is orphaned",
              "The icon set laid out in a row is recognisable against the "
              "reference sheet"]),

    dict(id=80, phase=P5, title="A pixel font", slug="font", deps=[14],
         files="tools/gen_font.py, assets/fonts/",
         goal="Type that is crisp at 480x270 and does not fight the art.",
         req=["A bitmap font generated from the same kind of ASCII maps as the "
              "sprites",
              "Full Latin-1 coverage, so Portuguese accents work when 0097 "
              "arrives",
              "Two sizes: HUD and heading",
              "No filtering, no hinting, integer positions only",
              "Numbers are tabular so a counter does not jitter"],
         dod=["Every accented character in the Portuguese strings renders",
              "A changing number does not shift the text around it"]),

    dict(id=81, phase=P5, title="The UI theme", slug="theme", deps=[79, 80],
         files="assets/theme.tres, src/ui/",
         goal="One Theme resource every control uses, so a colour change is one "
              "edit and no screen is the odd one out.",
         req=["Every Control style in one Theme: no per-node style overrides "
              "anywhere",
              "Built from the palette and the UI kit, not from Godot's defaults",
              "Focus, hover and disabled states defined for everything "
              "interactive",
              "A UI scale factor that works at every integer window scale"],
         dod=["`grep` finds no `add_theme_*_override` left in `src/ui/`",
              "Every screen looks like the same game"]),

    dict(id=82, phase=P5, title="Screenshots, and actually looking at them",
         slug="screenshots", deps=[5, 78],
         files="src/tools/shot.gd, implementation/shots/",
         goal="A command that puts the game in a known state and takes the "
              "picture, so a visual change can be checked instead of hoped for.",
         req=["`shot.gd` takes named scenarios: farm at noon, farm at dusk, a "
              "wave mid-fight, the result screen, the tech tree",
              "It runs headless and writes PNGs under `implementation/shots/<id>/`",
              "The scenario is built from a seed and a scripted state, so two "
              "runs give the same picture",
              "The runner loop is updated to say: after a visual task, take the "
              "shots and look at them"],
         dod=["One command produces the whole set",
              "The set is recognisably the game on the reference sheet"]),
]
