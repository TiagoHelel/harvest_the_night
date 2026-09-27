# -*- coding: utf-8 -*-
"""Backlog part 2: the full day, then the full night.

Everything here assumes the three-minute loop of 0027 already works and was
worth repeating. If it was not, stop and fix that instead of adding to it.
"""

P2 = "2 - The full day"
P3 = "3 - The full night"

TASKS = [
    # ==================================================== phase 2 - the full day
    dict(id=28, phase=P2, title="Corn and carrot", slug="three-crops", deps=[18],
         files="src/core/farming.gd, src/core/game_data.gd",
         goal="Three crops with a real choice between them: fast and cheap, slow "
              "and valuable, and one that feeds the defence.",
         req=["Wheat, corn and carrot, differing in growth time, sale price and "
              "what they feed into",
              "A crop is a data entry; adding a fourth takes no code",
              "Seed cost and sale price are set so no crop strictly dominates - "
              "show the arithmetic in the journal",
              "Corn is the defence crop: it is what gunpowder and rations come "
              "from later",
              "The planting menu shows time to grow and price per tick of growth"],
         dod=["A fourth crop is one dictionary entry - check it and say so",
              "No crop is the right answer at every money level",
              "`headless_check` asserts each crop's yield and timing"]),

    dict(id=29, phase=P2, title="Growth stages and watering", slug="growth-stages",
         deps=[28],
         files="src/core/farming.gd",
         goal="A field you can read at a glance, and one small daily chore that "
              "rewards coming back.",
         req=["Four visible stages per crop, driven by the growth ticks already "
              "in data",
              "Watering a tile speeds growth by a lever percentage until the next "
              "night",
              "Unwatered is slower, never fatal - this is a cozy game, not a "
              "punishment",
              "Water comes from the pond and the well, with a range or a carry "
              "limit that is a lever",
              "Watering the whole field is one held input, not forty clicks"],
         dod=["A watered and an unwatered tile planted together finish a "
              "measurable distance apart",
              "Holding the water input across a row waters the row once each"]),

    dict(id=30, phase=P2, title="Fishing", slug="fishing", deps=[15, 7],
         files="src/core/fishing.gd",
         goal="The pond earns its place: the highest value per action on the "
              "farm, paid for with attention rather than resources.",
         req=["Cast from a shore or jetty tile facing water, on the interact "
              "action",
              "A bite after a seeded random delay inside a lever range, then a "
              "window to react",
              "Common and rare fish, with the rare chance a lever",
              "Missing the window loses nothing but the time",
              "Fish sell high and feed cooking later"],
         dod=["The bite delay is drawn from the run RNG and replays identically",
              "Fishing with no reaction for a whole day yields nothing and "
              "crashes nothing",
              "`input_check` lands one fish"]),

    dict(id=31, phase=P2, title="Iron from the rock face", slug="iron", deps=[17],
         files="src/core/gathering.gd, src/core/game_data.gd",
         goal="The resource that gates towers. Iron should feel like the thing "
              "you are always a little short of.",
         req=["Iron comes only from the rock face region, and only from ore "
              "nodes, not loose rocks",
              "Ore takes longer per hit than stone and yields less",
              "Ore respawn is slower than stone respawn and both are levers",
              "A day's mining should buy roughly one tower - state the arithmetic "
              "in the journal",
              "Iron is not sellable at a profit against what a tower costs"],
         dod=["Mining a full day yields iron inside the range the journal claims",
              "The rock face cannot be exhausted permanently"]),

    dict(id=32, phase=P2, title="Oil", slug="oil", deps=[19],
         files="src/core/crafting.gd, src/core/game_data.gd",
         goal="Fire needs fuel. Oil is pressed rather than gathered, which makes "
              "it the first resource that costs a building.",
         req=["A press that turns corn or fish into oil over ticks",
              "Oil feeds the flamethrower tower and incendiary ammunition",
              "Oil is the most valuable thing to sell and the most useful to "
              "keep: that tension is the point",
              "Press throughput is a lever"],
         dod=["Oil can be produced and sold, and the sale is a real temptation "
              "against the flamethrower cost",
              "`headless_check` runs the press for a known number of ticks"]),

    dict(id=33, phase=P2, title="The generator and energy", slug="generator",
         deps=[31, 19],
         files="src/core/power.gd",
         goal="Energy, the resource on the reference sheet that gates the "
              "advanced structures and makes placement matter.",
         req=["A generator burns a fuel over ticks and produces energy",
              "Energy is a rate, not a stockpile: structures draw it while they "
              "run",
              "A structure with no power runs at a reduced rate rather than "
              "switching off - degraded, not dead",
              "The HUD shows supply against draw",
              "Generator output, fuel burn and each structure's draw are levers"],
         dod=["Building one structure too many visibly slows everything rather "
              "than stopping it",
              "Running out of fuel mid-night degrades the defence and the night "
              "still resolves"]),

    dict(id=34, phase=P2, title="Cooking: food and meat", slug="cooking",
         deps=[30, 28],
         files="src/core/crafting.gd",
         goal="The kitchen from the reference sheet: raw crops and fish become "
              "food, which is what repairs and heals during the night.",
         req=["Recipes turning crops, fish and meat into food",
              "Food is the night's repair and heal currency, per the design "
              "document's resource table",
              "Cooked food is worth more than its inputs sold separately, or the "
              "kitchen has no reason to exist",
              "Meat comes from the farm animals on the reference sheet; keep it "
              "to a passive trickle, not an animal husbandry system"],
         dod=["A cooked dish sells for more than its inputs - state the margin",
              "Food spent on repair during a night is taken through the ledger"]),

    dict(id=35, phase=P2, title="Gunpowder and ammunition", slug="ammunition",
         deps=[32, 33],
         files="src/core/crafting.gd, src/core/towers.gd",
         goal="Towers that consume something. The clearest possible version of "
              "'what you made today decides what tonight can do'.",
         req=["Gunpowder from corn and oil; incendiary rounds from oil and wood",
              "A tower draws from a shared ammunition pool at a rate that is a "
              "lever",
              "Out of ammunition means a much slower basic shot, never a silent "
              "dead tower",
              "The night HUD shows the pool draining",
              "Ammunition left over carries into the next night"],
         dod=["A night fought with no gunpowder is survivable but clearly worse",
              "The pool drains at the rate the levers claim over a scripted night"]),

    dict(id=36, phase=P2, title="The inventory", slug="inventory", deps=[7],
         files="src/core/inventory.gd, src/ui/inventory_panel.gd",
         goal="Somewhere to see everything at once, which the HUD cannot do once "
              "there are twelve resources.",
         req=["A panel listing every resource with its amount and its sale price",
              "Grouped the way the reference sheet groups them",
              "Opens and closes on one key without pausing the day",
              "It is a view of the ledger, not a second store of truth"],
         dod=["Every resource in game_data appears without being listed twice",
              "Adding a resource to game_data makes it appear with no UI edit"]),

    dict(id=37, phase=P2, title="The workshop queue", slug="craft-queue",
         deps=[19, 36],
         files="src/core/crafting.gd, src/ui/workshop_panel.gd",
         goal="Semi-idle in one feature: queue five things, walk away, come back "
              "to five things.",
         req=["A queue per production building with a length that is a lever",
              "Inputs are taken when an item starts, not when it is queued",
              "Cancelling a queued item that has not started refunds it in full",
              "The queue advances on the tick whether or not the player is "
              "looking",
              "The panel shows time remaining on the current item"],
         dod=["Queue three barricades, walk to the pond and back, and three exist",
              "Cancelling the second of three leaves the first and the third "
              "intact"]),

    dict(id=38, phase=P2, title="Production runs while you are elsewhere",
         slug="idle-production", deps=[37, 29],
         files="src/core/sim.gd",
         goal="The feeling the design document asks for: 'I built a machine and "
              "now I want to find out whether it works'.",
         req=["Crops, presses, generators and queues all advance on the same tick "
              "regardless of camera or player position",
              "No system may depend on being on screen - find and remove any that "
              "does",
              "Returning to a building shows what happened while away, not a "
              "silent jump",
              "A day spent entirely fishing still produces from everything else"],
         dod=["A scripted day where the player never leaves the pond still "
              "finishes the crafting queue",
              "The tick cost of a fully built farm stays inside the budget"]),

    dict(id=39, phase=P2, title="The day clock and dusk", slug="day-clock",
         deps=[6, 21],
         files="src/core/phases.gd, src/ui/day_hud.gd",
         goal="Time passing, without taking away the design document's promise "
              "that the player switches reality when they want to.",
         req=["A day is a lever's worth of ticks and the HUD shows it as a clock "
              "or a sun",
              "The light warms and then cools across the day",
              "At dusk the night button starts asking to be pressed; it does not "
              "press itself",
              "Past dusk the day keeps running, with a gentle nudge rather than a "
              "penalty",
              "Time does not pass in menus"],
         dod=["A player who ignores the clock entirely is not punished for it",
              "The clock stops in the shop panel and resumes on close"]),

    dict(id=40, phase=P2, title="The shop grows", slug="shop-full", deps=[20, 28],
         files="src/core/shop.gd, src/ui/shop_panel.gd",
         goal="Somewhere for money to go: all three seeds, materials when you are "
              "short, and the first upgrades.",
         req=["Seeds for all three crops, and materials at a markup over their "
              "sale price",
              "Buying materials is always worse than gathering them, so money "
              "cannot replace playing",
              "A small daily stock that refreshes, so the shop cannot be drained "
              "into an exploit",
              "Prices in game_data, every one a lever",
              "Buy and sell are two tabs, not two shops"],
         dod=["Buy-then-sell on the same item loses money at every price",
              "Stock refreshes once per day and not once per visit"]),

    dict(id=41, phase=P2, title="The first day teaches itself", slug="tutorial-day",
         deps=[39, 40],
         files="src/core/tutorial.gd",
         goal="Day 1 should teach chop, plant, craft, build and the night button "
              "without a wall of text or a cage.",
         req=["Prompts appear on the thing they describe and disappear when it is "
              "done",
              "Nothing is locked: a player who already knows can ignore all of it",
              "Night 1 stays the tutorial night the design document asks for - a "
              "handful of basic zombies",
              "Seven lines of text at most in the whole first day",
              "A profile flag so it never shows twice"],
         dod=["Someone who has not seen the game reaches the first night without "
              "being told anything out loud",
              "Skipping every prompt still leaves a winnable night 1"]),

    # ================================================== phase 3 - the full night
    dict(id=42, phase=P3, title="Data-driven defences", slug="defence-data",
         deps=[24],
         files="src/core/towers.gd, src/core/game_data.gd",
         goal="Before adding five more towers, make a tower a data entry, so the "
              "combat code stops growing a branch per structure.",
         req=["A structure declares: targeting, damage type, shape, rate, range, "
              "cost, energy draw, ammunition use",
              "The combat code reads the declaration instead of comparing ids",
              "The shooting tower is ported with no behaviour change at all",
              "Damage types: impact, fire, explosive - named in one place",
              "A new tower that deals 3 fire in a radius is one entry and no "
              "combat edit"],
         dod=["The determinism hash is unchanged after the port - that is what "
              "makes it a port",
              "Adding a test tower takes a data entry only; delete it afterwards "
              "and say so"]),

    dict(id=43, phase=P3, title="The flamethrower tower", slug="tower-flame",
         deps=[42],
         files="src/core/game_data.gd",
         goal="The reference sheet's second tower: expensive, short range, "
              "continuous area damage, and it burns oil.",
         req=["A cone in front of it rather than a single target",
              "Damage over time that keeps burning after the zombie leaves the "
              "cone",
              "Burn does not stack into absurdity: refresh the duration, do not "
              "add a second instance",
              "It consumes oil while firing and is much weaker without it",
              "Cost, range, cone angle, damage and burn duration are levers"],
         dod=["A crowd walking through the cone takes the damage the levers claim",
              "Two flamethrowers on one zombie do not double the burn"]),

    dict(id=44, phase=P3, title="The mortar", slug="tower-mortar", deps=[42],
         files="src/core/game_data.gd",
         goal="The long shot: slow, expensive, splash damage, and it cannot hit "
              "what is next to it.",
         req=["A minimum range as well as a maximum - this is what makes "
              "placement a decision",
              "A shell with real flight time that lands where the target was "
              "aimed, not where it ended up",
              "Splash with falloff from the centre",
              "It consumes gunpowder per shot",
              "Minimum range, flight time, radius and falloff are levers"],
         dod=["A zombie that walks out of the blast between firing and landing "
              "survives - and that reads as fair",
              "Splash damage at the edge is the falloff the lever claims"]),

    dict(id=45, phase=P3, title="The auto-crossbow", slug="tower-crossbow",
         deps=[42],
         files="src/core/game_data.gd",
         goal="The reference sheet's last tower: cheap, fast, low damage each, "
              "and it hits everything in a line.",
         req=["A bolt that pierces, losing a lever's fraction of its damage per "
              "target",
              "It fires along a line the player can see while placing it",
              "Cheap in iron, hungry for energy - the reason to build the "
              "generator",
              "Strong against the runner, weak against the tank, by construction"],
         dod=["A line of five zombies takes the falloff the lever claims",
              "It is clearly the wrong answer against a tank and clearly the "
              "right one against a rush"]),

    dict(id=46, phase=P3, title="Fences and walls", slug="walls", deps=[23],
         files="src/core/building.gd, src/core/pathing.gd",
         goal="The other half of a tower defence: making the zombies walk where "
              "you want them to.",
         req=["A fence is cheap wood with low hit points; a wall is stone and "
              "slow to break",
              "Walls change the flow field, and the field is rebuilt when one is "
              "placed or destroyed",
              "A wall cannot fully seal the house: if every path is blocked, "
              "zombies attack the nearest wall instead of standing still",
              "Placing shows the path the zombies will take afterwards",
              "Hit points and cost are levers"],
         dod=["Walling a lane visibly reroutes the next wave",
              "Sealing the farm completely makes them break in rather than freeze",
              "The field rebuild cost stays inside the budget with fifty walls"]),

    dict(id=47, phase=P3, title="Barricades", slug="barricades", deps=[46],
         files="src/core/game_data.gd",
         goal="The emergency answer: almost free, almost paper, and placeable "
              "while the night is running.",
         req=["Cheapest structure in the game, from the workshop's first recipe",
              "It may be placed during NIGHT, which no other structure may",
              "It has a short lifetime as well as hit points, so it cannot become "
              "a permanent wall",
              "A limit on how many may be placed per night, and it is a lever"],
         dod=["Placing one mid-wave buys the measurable seconds the lever claims",
              "It expires on its own if it survives the night"]),

    dict(id=48, phase=P3, title="Mines and traps", slug="traps", deps=[42],
         files="src/core/towers.gd, src/core/game_data.gd",
         goal="The reference sheet's mine: no targeting, no upkeep, high damage, "
              "and then it is gone.",
         req=["Triggers on an enemy entering its cell, not on a timer",
              "High damage in a small radius, then it removes itself",
              "It is invisible to the player as a firing thing: no range circle, "
              "no target line",
              "A limited number armed per night, replenished by crafting",
              "Damage, radius and cost are levers"],
         dod=["A mine under the choke point kills what the levers say it kills",
              "Two mines in adjacent cells do not chain into a fifty damage "
              "cascade - or they do, deliberately, and the journal says so"]),

    dict(id=49, phase=P3, title="Zombies path around walls", slug="pathing-walls",
         deps=[25, 46],
         files="src/core/pathing.gd",
         goal="Make the flow field earn its keep: cost, not just blocked, so "
              "zombies prefer the open lane and break through when they must.",
         req=["Path cost per terrain and per structure, so a wall is expensive "
              "rather than impossible",
              "A zombie whose cheapest path is still expensive attacks the "
              "structure instead of walking around the world",
              "Recompute is incremental or cached: it must not cost a frame when "
              "a wall falls mid-wave",
              "Deterministic tie-breaking everywhere in the field",
              "No zombie ever oscillates between two cells"],
         dod=["A hundred zombies and a maze stay inside the tick budget",
              "The same seed and the same maze give the same arrival order",
              "A headless test asserts no zombie is in the same pair of cells for "
              "20 ticks"]),

    dict(id=50, phase=P3, title="The runner", slug="enemy-runner", deps=[49],
         files="src/core/game_data.gd",
         goal="The first enemy that changes what you build: fast, fragile, and it "
              "arrives before the mortar can reload.",
         req=["Roughly twice the basic speed and half the hit points - state the "
              "real numbers",
              "It ignores structures and runs straight for the house",
              "It punishes a defence made only of slow, expensive towers",
              "Speed, hit points and reward are levers"],
         dod=["A crossbow line stops a rush and a mortar alone does not",
              "It arrives first when mixed into a wave with basics"]),

    dict(id=51, phase=P3, title="The tank", slug="enemy-tank", deps=[49],
         files="src/core/game_data.gd",
         goal="The enemy that needs concentrated damage: slow, heavy, and it "
              "shrugs off chip damage.",
         req=["High hit points and a flat reduction against each hit, so many "
              "small hits are worse than few big ones",
              "Slow enough that the player watches it come",
              "It is the reason the mortar exists",
              "Hit points, reduction and speed are levers"],
         dod=["A crossbow wall barely scratches it and a mortar drops it - "
              "measure both",
              "The reduction cannot take a hit below zero damage"]),

    dict(id=52, phase=P3, title="The breaker", slug="enemy-breaker",
         deps=[49, 46],
         files="src/core/enemies.gd, src/core/game_data.gd",
         goal="The enemy that goes after what you built: it targets structures "
              "first and the house second.",
         req=["It picks the nearest structure on its path, not the house",
              "Extra damage against structures and little against the house",
              "It makes an undefended tower line a liability, which is the point",
              "Target selection is deterministic and ordered"],
         dod=["A wave of breakers dismantles an unprotected tower line",
              "With the towers covered, they die before they reach one"]),

    dict(id=53, phase=P3, title="Repair during the night", slug="repair",
         deps=[46, 27],
         files="src/core/building.gd, src/ui/night_hud.gd",
         goal="A reason to be present at night: spend food and wood to put a wall "
              "back up while the wave is still coming.",
         req=["Repair costs food or wood per hit point restored, and the rate is "
              "a lever",
              "It takes time and the player must be near the structure",
              "A destroyed structure cannot be repaired, only rebuilt",
              "The house itself can be repaired, at a worse rate",
              "Repairing is interruptible"],
         dod=["Repairing a wall mid-wave measurably changes whether it holds",
              "`input_check` repairs something"]),

    dict(id=54, phase=P3, title="The player's ability", slug="ability", deps=[27],
         files="src/core/ability.gd, src/ui/night_hud.gd",
         goal="One button that lets the player change a night they are losing, "
              "without turning the game into an action game.",
         req=["One ability with a cooldown in ticks: a flare that slows and "
              "damages everything in an area",
              "The cooldown is long enough that using it is a decision",
              "It is resolved on the tick like everything else and is in the "
              "determinism hash",
              "It reads clearly on screen: the player should see it working",
              "Damage, radius, slow and cooldown are levers"],
         dod=["It turns one losing wave per night, not every wave",
              "Two uses in the same second are impossible"]),

    dict(id=55, phase=P3, title="Double speed and skipping the night",
         slug="speed-controls", deps=[2, 27],
         files="src/ui/night_hud.gd, src/core/sim.gd",
         goal="The semi-idle promise: if the defence is clearly going to hold, "
              "let the player say so and move on.",
         req=["1x, 2x and 4x, implemented as ticks per frame - never as a "
              "changed tick rate",
              "Skip to the end simulates the rest of the night as fast as it can "
              "and shows the result",
              "A skipped night and a watched night give an identical outcome from "
              "the same state - this is the test of the whole tick design",
              "Speed is remembered across nights",
              "Skipping is refused while the house is under a lever's worth of "
              "hit points, because that night is worth watching"],
         dod=["Watched and skipped nights from one seed produce the same hash",
              "4x does not drop frames on a full board",
              "`headless_check` runs a night both ways and compares"]),

    dict(id=56, phase=P3, title="The night HUD", slug="night-hud", deps=[27],
         files="src/ui/night_hud.gd",
         goal="Section 14 of the design document: which night, which wave, how "
              "the house is doing, and the three buttons.",
         req=["Night number, wave counter, house hit point bar, ammunition and "
              "energy",
              "Repair, ability and speed as the three controls, exactly as the "
              "design document lays them out",
              "An incoming wave is announced before it arrives",
              "The house bar turning dangerous is impossible to miss",
              "It replaces the day HUD on the phase change, sharing no state"],
         dod=["Every number on it is readable at 480x270 scaled up",
              "`input_check` presses all three controls"]),

    dict(id=57, phase=P3, title="Structures take damage and die",
         slug="structure-damage", deps=[46, 52],
         files="src/core/combat.gd, src/core/building.gd",
         goal="Losing things. A structure that breaks should be a small disaster "
              "the player watched happen.",
         req=["Every structure has hit points and a visible damage state",
              "Destruction frees the cell, rebuilds the flow field and leaves "
              "rubble that clears by morning",
              "Damaged structures survive into the next day at their current hit "
              "points",
              "A repair cost that is cheaper than rebuilding, so repairing is the "
              "right move",
              "Nothing in the state dangles after a structure dies"],
         dod=["Destroying a wall mid-wave reroutes the zombies the same tick",
              "A structure at 1 hit point is still working, and looks wounded",
              "A night of heavy losses leaves a morning that is still playable"]),

    dict(id=58, phase=P3, title="The Giant", slug="boss-giant",
         deps=[51, 52, 57],
         files="src/core/enemies.gd, src/core/game_data.gd",
         goal="The single boss of the MVP: the test of the build you made over "
              "nine nights.",
         req=["Very high hit points, slow, and it smashes structures on its way "
              "through",
              "It arrives with ordinary zombies, so the player cannot aim "
              "everything at it",
              "It forces concentrated damage: a defence of only cheap towers "
              "cannot kill it in time",
              "One readable telegraph before its heavy attack",
              "Beating it is the end of the MVP run"],
         dod=["A well-built night 9 defence beats it with something to spare",
              "A defence of nothing but crossbows loses to it",
              "It never softlocks the night by becoming unreachable"]),
]
