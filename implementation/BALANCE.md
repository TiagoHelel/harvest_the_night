# The balance sweep - task 0068

Measured with `python tools/balance.py`, which turns one lever at a time,
plays eight runs of the ten nights at each value with `tools/autoplay.py`, and
puts `game_data.gd` back. Around 440 full runs went into the tables below.

**Read the headline first, because it changes how to read everything else.**

---

## The headline: most of what looked like difficulty was the instrument

The first sweep said nights 8, 9 and 10 were unwinnable by every policy. That
was true and it was not a fact about the game. Five separate faults in the
autoplayer, each found by asking a losing run what it had actually been doing:

| What the robot did | What it cost |
| --- | --- |
| Built the first thing it could **afford**, not the first thing its plan named | `walls` laid 89 fences in three days, never cut the wood for the tower at the top of its own list, and died on night 1 on every seed |
| Piled every defence in one column beside the house | Fixed by reading `GameData.SPAWNS`. A ring around the house was *worse* - this map has two ways in, so an even ring guards the west, where nobody walks |
| Blocked for ever on a mortar, because a mortar wants gunpowder and gunpowder is crafted | Went into night 9 with three towers and **78 unspent iron** |
| Never ran a press or a workshop | Never made oil, so a generator had nothing to burn, so supply stayed at `BASE_ENERGY` for ten nights |
| Put the press and the kitchen on the best ground of the east approach | `economy` had two towers at full power on night 2 and killed five of twenty |

After those five fixes, and before any lever moved, the same game went from
"nothing survives night 8" to `towers` reaching night 10. **No game lever was
touched to achieve that.** Tuning the ten nights down to suit a robot that
could not run a press would have been tuning the game to the instrument.

The numbers below were all taken after those fixes.

---

## The curve

Win rate per night - the share of runs still alive at the end of night N,
pooled across all four policies, at the shipped values:

```
  night     1    2    3    4    5    6    7    8    9   10
  win %   100   83   75   75   75   75   75   58    0    0
```

Before this task's changes the same measurement read
`100 75 75 75 75 75 62 0 0 0`: night 8 was a wall and nothing beyond it
existed. Nights 2 to 8 are now a curve that descends. The two ends are not,
and both are discussed under "What is still wrong" below.

### A warning about these percentages

`tools/autoplay.py` plays several seeds of each policy and this report calls
that eighty runs, but **the seeds agree far more than they look like they
should.** Seeds 6700, 6701, 6702, 6710, 6800, 9000 and 9007 played over three
nights returned 1509 gathered and 47 killed, every one, to the unit.

That is not a broken seed. `FARM_MAP` authors the trees and the seams and
`NIGHTS` authors the waves, so neither asks the run's RNG anything. What the
seed touches is small - which cell of a spawn region, which strike of a seam
pays - and it takes until the back half for that to add up to a different
night. It does get there: `walls` reaches 8, 9 and 8 on three seeds, and
`economy` 2, 2 and 3.

So the early columns above are close to a single sample repeated, and a
difference of one run in the first few nights should not be read as a trend.
The late columns are real.

---

## The levers, one at a time

Each row is the win rate per night, 1..10, at that value. The shipped value is
in **bold**.

### gun tower damage - *saturated above 6, left alone*

```
    4      100  50  50  50  50  50  38  25   0   0
  **6**    100  75  75  75  75  75  75  25   0   0
    9      100  75  75  75  75  75  75  25   0   0
```

4 is too low and 9 is identical to 6 in every one of eighty runs. The lever
has a floor and then a ceiling, and 6 is already past the ceiling. **Turning
it up is not how to open the back half** - which was worth knowing, because it
is the first dial anyone reaches for.

### house hit points - *a cliff at the tutorial night, left alone*

```
   80        0   0   0   0   0   0   0   0   0   0
  **100**  100  75  75  75  75  75  75  25   0   0
   140     100  75  75  75  75  75  75  38   0   0
```

**At 80 every policy dies on night 1.** That is not a gentle curve, it is a
cliff between 80 and 100, and it is the sharpest single fact this sweep found
about the early game. See "Night one has a ten-point margin" below. At 140 the
only night that moves is the eighth, from 25% to 38% - so the house is not the
back half's problem either.

### base energy - *measured, tried, reverted*

```
  **4**    100  75  75  75  75  75  62   0   0   0
    6      100  75  75  75  75  75  75  50   0   0
    8      100  75  75  75  75  75  75  75  12   0
```

The strongest lever in the game, and nothing else is close. Four energy a tick
is *exactly* a gun tower (1) and an auto-crossbow (3), so **the third thing a
player builds browns the whole farm out.** Six carries a second gun tower,
which is what night two's own note in `GameData.NIGHTS` says a player needs:
"the same again from two sides, so one tower is not enough". Past that you
still want a generator, so the decision the lever exists to pose survives.

**It was applied at 6, and then taken back out, and the test suite is why.**
`headless_check` has carried an assert since the defences were authored that
the hungriest defence draws more than half the base supply - "hungry enough
that two of them want a generator". An auto-crossbow draws 3. At a base of 4
that holds; at 6 two crossbows run free and the assert goes red.

That assert is a design rule, not a coincidence: the farm-feeds-the-guns chain
`design.md` is built on only matters if a modest defence already needs a
generator. Six energy pushes the first generator out to somewhere around night
6, and eight removes it from the early game entirely.

So the floor below does the same work - it measures slightly *better*, in
fact - without moving the point at which the farm starts to matter. **The
suite caught a balance change that was quietly undoing a design promise**,
which is the best argument for this task's rule that a new number ships with
an assert.

### brownout floor - *25 -> 50, applied: the one game change this task made*

```
  **25**   100  75  75  75  75  75  62   0   0   0
    50     100  75  75  75  75  75  75  75  12   0
```

The same size of effect as base energy 8, and better aimed. `UNPOWERED_PERCENT`
is how slowly a farm runs when it has outbuilt its supply, and because
`Power.scaled_ticks` slows **every** tower, the fifth tower makes the first
four worse. The player's natural move - build another one - is the wrong move,
and nothing on screen says so.

Measured directly, from two runs with *identical* builds and nothing different
but the supply:

| | two gun towers, night 2 |
| --- | --- |
| at 100% power | **17 killed, house 70** |
| at 80% power | **4 killed, house 0** |

A fifth of the power, three quarters of the defence. Raising the floor to 50
leaves the gate exactly where it was - below full supply you are still slower,
a generator is still the answer - but a player who walks into it is at half
speed rather than a quarter, and can dig their way out.

### walker speed - *measured, rejected*

```
  **20**   100  75  75  75  75  75  62   0   0   0
    26     100  75  75  75  75  75  12  12   0   0
    30     100  75  75  75  75  75  50  12   0   0
```

Swept because the arithmetic of night one points straight at it (below), and
**rejected because it makes nights 7 and 8 much worse**: slower walkers are on
the map longer, so they are still there when the next wave lands, and a crowd
that overlaps is a bigger crowd. It does not improve night one's win rate
either, since that is already 100%. A lever that fixes the flavour of night 1
by wrecking night 7 is not a fix.

### money a night - *flat, but not called dead*

```
  10       100  75  75  75  75  75  75  25   0   0
  **15**   100  75  75  75  75  75  75  25   0   0
  25       100  75  75  75  75  75  75  25   0   0
```

Identical across its whole range. **This is reported as "not shown to matter"
rather than as dead weight**, because the difference is the instrument again:
money buys seeds (`Farming`) and shop goods (`Shop`), and the autoplayer sows
but has never once opened the shop. A lever this robot cannot spend is a lever
this robot cannot measure. It wants a sweep after the autoplayer learns to
buy, and until then the flat row means nothing either way.

### wave gap - *dead weight, and now fixed*

```
   8       100  75  75  75  75  75  75  25   0   0
  30       100  75  75  75  75  75  75  25   0   0
```

Eight seconds against thirty - close to a fourfold change in the pace of every
night - and **not one run of eighty changed.** Confirmed by grep: since task
0059 moved the gap onto each night's own record, and all ten nights were
written out longhand, `WAVE_GAP_TICKS` had no reader in `src/core/` at all.
Only `digest()` and one assert mentioned it.

Fixed rather than deleted. `Waves.delay_before()` now falls back to it, and
nights 1 and 2 - which were written at exactly the default - no longer restate
it. The lever means "the pace of an ordinary night" and now does.

---

## What is still wrong

### Night one has a ten-point margin

A gun tower's range is 5 tiles and a walker crosses a tile in 20 ticks, so a
walker is in range for 100 ticks. The tower deals 6 damage a second, and 100
ticks is 3.3 seconds, and 3.3 x 6 is **20 - exactly one walker's hit points.**

So one tower kills one walker per wave however many are in the wave. Nine of
night one's twelve reach the house, at 10 damage each, which is 90 of the
house's 100. Measured: 3 killed, 9 breaches, house on 10.

The night's own note says "the tutorial night: one tower, one side, and time
to watch", and the walker's table comment says "one tower holds it with room".
Neither is true. **Nothing was applied**, because the two obvious candidates
both failed: walker speed wrecks nights 7-8 (above), and house hit points only
shift which side of the cliff night one lands on. The honest fix is probably
the tower's `range` or `reload_ticks`, neither of which was swept here, and it
should be its own pass.

### Nights 9 and 10 are still at 0%

`towers` reached night 10 during the sweep and no policy has ever beaten it.
Night 10 is the Giant at 900 hit points with 84 others for company.

This is **not** reported as "night 10 is too hard", because the one strategy
built to answer it - the farm-to-oil-to-generator chain that lets a player run
more than a handful of towers at full power - is the thing the autoplayer is
weakest at. It can now run a press, but no policy's plan is built around
fuelling generators, and `economy`, the policy that should be, is the one that
dies earliest. **Night 10 needs a policy that plays the game's actual answer
before its difficulty can be judged.**

---

## The done-when, honestly

> No night has a win rate of 100% or 0% across every policy

**Not met, and two thirds of it should not be met as written.**

- **Nights 1 and 2 sit at 100%.** They should. Night one is the tutorial night
  and night two is the one that teaches that a single tower is not enough;
  a tutorial night that kills a quarter of players is a worse game, not a
  better-balanced one. The requirement is right about the middle of the run
  and wrong about its opening.
- **Nights 9 and 10 sit at 0%**, and that is a real failure - but it is the
  instrument's, not the game's, until an autoplayer policy exists that fuels
  generators. Lowering night 10 to make this line go green would be the exact
  mistake the rest of this document is about.

What the sweep did achieve: nights 3 to 8 now form a genuine curve, two dead
or unmeasurable levers are named, the single most powerful lever in the game
is identified and bounded, and the back half moved from "no policy survives
night 8" to "three policies reach night 9 and one reaches night 10" with two
lever changes.

---

## The new loop - task 0142

The autoplayer now plays the game as it is:
- out of bed (0138), and the day's work;
- to bed through the `sleep` intent at its policy's `bed_minute` (01:30 for
  all four);
- the defence put down in the build step through the intent road;
- START;
- the night to its own end, and the morning report confirmed.

**A run no longer stops at its first loss**: it plays its ten nights, the
same night coming back after a loss.

The same 100 runs as before - `python tools/autoplay.py`, 25 seeds
(`9000 + 7i`) of each policy - before the change and after it. **Survival per
night** is the share of runs still unbeaten at the end of night N (the first
loss, which is what `tools/balance.py` reads); night 10 is the `won` column.

| policy | loop | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| balanced | before | 84% | 84% | 84% | 84% | 84% | 84% | 84% | 0% | 0% | 0% |
|  | after | 84% | 84% | 84% | 84% | 84% | 84% | 52% | 0% | 0% | 0% |
| economy | before | 84% | 76% | 0% | 0% | 0% | 0% | 0% | 0% | 0% | 0% |
|  | after | 84% | 76% | 0% | 0% | 0% | 0% | 0% | 0% | 0% | 0% |
| towers | before | 84% | 84% | 84% | 84% | 84% | 84% | 68% | 0% | 0% | 0% |
|  | after | 84% | 84% | 84% | 84% | 84% | 84% | 68% | 0% | 0% | 0% |
| walls | before | 100% | 100% | 100% | 100% | 100% | 100% | 100% | 16% | 0% | 0% |
|  | after | 100% | 100% | 100% | 100% | 100% | 100% | 100% | 16% | 0% | 0% |

**What changed:**
- **Three of the four curves are identical, seed for seed.** Bed by intent,
  defences through the intent road, START and the morning report are the
  same game as the shortcuts they replaced, and that is the check that they
  are.
- **`balanced` loses night 7 on eight more seeds, and its bedtime is why.**
  The old robot worked until one tick before 02:00; this one goes to bed at
  01:30. Seed 9000 was played both ways with nothing else changed:
  - with a 01:30 bedtime it loses night 7, and loses it again the next day;
  - with a 01:59 bedtime it clears night 7 on 85 house.

  **The last half hour of every day is worth a night to `balanced`**, which
  makes night 7 a knife edge for it rather than a wall. It is a finding about
  the game, not the instrument, and the bed hour is now a policy lever to
  turn when that is the question.
- **What the new loop adds to the picture**:
  - **No night ended at dawn in a thousand.** Every night held was held by
    killing everything first: the robot's towers finish each night long
    before 06:00. Dawn (0137) is a backstop the current curve never reaches.
  - Over ten nights the policies win 6.7 (`economy`) to 7.2 (`walls`) nights
    a run on average, and how they get there differs:
    - **`economy` recovers.** Its first loss is on night 3, yet it wins 6.7
      nights: the days after a loss pay for what night 3 asked.
    - **The other three stall where they first fell.** Their mean first loss
      and their nights won are within one night of each other. Night 7 or 8,
      once lost, is lost again.
  - Between 1.5 and 4.1 zombies a night walk off at the morning: the ones
    still standing when a lost night ended.
- **Gathered** went up (5,671 to 8,018 for `balanced`) only because every
  run now plays all ten days instead of stopping at its first loss.

The time: 100 runs in 2,366 s, against 1,411 s before - every run now plays
ten nights.


## 0166 - a 560-second day (2026-10-09)

The clock now has 14 ticks per game minute: 16,800 ticks from 06:00 to
02:00, with dusk at tick 10,080 (18:00). Producer periods scale by
16,800 / 7,200 = 7/3; physical swings and the fishing reaction window do not.
This preserves production capacity while leaving more time to cross the farm.

| Producer | New period | Capacity in one nominal day |
|---|---|---|
| Barricade / fence / mine / wall kit | 420 / 350 / 560 / 700 ticks | 40 / 48 / 30 / 24 kits |
| Corn / fish oil | 1,400 / 1,750 ticks | 12 / 9 oil |
| Incendiary / gunpowder | 700 / 1,050 ticks | 96 / 32 rounds |
| Meal / fish meal / roast | 840 / 1,050 / 1,260 ticks | 40 / 48 / 52 food |
| Cow / chicken | 5,600 / 3,500 ticks | 2 / 4 meat before pass-out, if collected promptly |
| Tree / ore | 8,400 ticks to regrow | Two harvests, including the initial node |
| Stone seam | 6,300 ticks to regrow | Three harvests, including the initial node |
| Fishing | 140-700 ticks to bite | 40 mean waits; reaction and travel lower the catch count |
| Loaded generator | 4,200 ticks per oil | Four oil before pass-out |

Recipe capacities assume continuous queues, enough inputs and full power,
without tech bonuses. Pass-out handles the final tick before production, so
a fresh morning can deliver one batch fewer for exact divisors. Waiting
until the next day retains the unfinished batch. Animals retain their caps
(two cow products, one chicken product); neglecting collection reduces yield.
A tight route over the eight ore nodes produces 16 iron; a deliberately slow
route taking 1/18 day between nodes produces 13. Both still buy one
thirteen-iron gun tower. Loose boulders still do not regrow.

The shop still restocks wood 15, stone 12, iron 8, wheat 10, corn 8 and
carrot 12 once per day. These are daily quantities, so scaling them would
increase supply accidentally. Crops still grow by watered mornings (0165).
Generator fuel also lasts 140 seconds at night, up from 60: the longer
fuel period is global, while the night duration remains unchanged.

`tools/autoplay.py 4 --nights=1` provides a short full-day measurement;
the default remains ten nights for the balance sweep. Each short-run row
reports actual day ticks and net money before the night reward. It does not
count the sale value of unsold materials as cash income. Suite policies use
20:00 bedtime; the standalone policies retain 01:30.

Measured with seed 9000: all four policies worked 16,381 day ticks (01:30
plus the sleep-intent tick), earned $0 cash and spent $24, then cleared the
first night with 10 house HP remaining. They gather and consume materials;
they do not sell those materials, so this is not a claim that daytime work
has zero sale value. Four runs took 17.6 seconds. The old 900-action guard
would have cut these longer days short; it now scales with the tick budget.
The balance reader parsed all four results, and each of its seven lever
patterns matched exactly once. Its stale brownout pattern now accepts the
current value of 50 rather than silently skipping the lever.

## 0194 - the day's money (2026-10-10)

**The rule** (plan section 5): at the start of each season, what a
well-worked day earns should buy about one new defence.

**The bands** (`GameData.DAY_TARGETS`, levers): spring $180-400, summer
$205-460, autumn $235-530, winter $270-610.
- They are centred on a gun tower's ten wood and twelve iron at the stall's
  prices in spring: $246 now that wood is $1, $266 before.
- Each season asks about a seventh more, because the towers rise a level
  and the nights grow.

**A well-worked day** runs from 06:00 to dusk, and the animals' to 01:30.
- Its money is what the day makes, at what the stall pays, less what it
  buys there.
- An input the season makes for itself costs nothing that day. It is the
  farm's own (`Economy.input_cost`, from 0193's `seasonal_supply` with the
  stall's shelves empty).

**The farm under it** (`GameData.DAY_FARM`, levers) is what a player who
spent the previous season on that way of earning has at the season's start.

| | Spring | Summer | Autumn | Winter |
|---|---|---|---|---|
| Tool tier | 0 (basic, bamboo rod) | 1 (iron, fibre rod) | 1 | 2 (gold, iron rod) |
| Field | 60 plots | 80 | 80 | - (nothing grows) |
| Herd | - (a new game has no homes) | 8 hens, a cow, 2 sheep, a pig | 8 hens, 2 cows, 3 sheep, 3 pigs | the same |
| Machines | - (and nothing to fill them) | 4 jars of jelly, 1 of pickles, a keg of juice, a dairy's cheese | 4 kegs of wine, 4 jars of jelly, pickles, cheese | 6 kegs of wine and the rest |

**The five ways of earning** (`Economy`, computed from the tables, never
played):
- **Crops:** the season's best money crop on its plots, a season's harvests
  less its packets, by the day.
- **Fishing:** casts at the season's best water. Each cast is the wait for a
  bite on the season's rod, with the throw inside it, plus the landing; each
  catch is worth the mean of what bites there over the day's hours.
- **The cliff and the woods** (plan section 3.3, "mine and cut"): whatever
  pays more for the time. The cliff's nodes that beat a tree a tick, as
  often as they come back, and the trees for the rest.
- **Animals:** the herd collected from its morning feed to bedtime, less its
  hay.
- **Artisan goods:** the machines kept busy on the farm's own goods, less
  what the stall alone sells (sugar before the autumn's beets).

<!-- tools/balance.py days writes from here to its end mark -->

| Season | Band | Crops | Fishing | The cliff and the woods | Animals | Artisan goods | Most |
|---|---|---|---|---|---|---|---|
| spring | $180-400 | $308 (played $308) | $238 (played $247) | $294 (played $294) | - | - | crops |
| summer | $205-460 | $280 (played $280) | $262 (played $281) | $393 (played $393) | $247 (played $231) | $231 (played $231) | the cliff and the woods |
| autumn | $235-530 | $451 | $308 | $393 | $401 | $317 | crops |
| winter | $270-610 | - | $354 | $474 | $401 | $369 | the cliff and the woods |

Computed: `Economy.day`. Played: `src/tools/day_economy.gd`, the crops over their season, the machines until their batches come round together, the pond over three days and the animals over four, by the day. A dash: the season has no means for it.

<!-- tools/balance.py days: end -->

**Every lever moved:**

| Lever | Was | Now | Why |
|---|---|---|---|
| wood, sell | $2 | $1 | Felling trees all day paid about $540 in spring and $750 in summer, more than any other way of earning in every season. Wood is for building. |
| perch, bream, sunfish, catfish | $8, $9, $8, $10 | $10, $12, $11, $13 | A day at the pond was under every band. |
| trout, pike, eel | $13, $14, $15 | $17, $18, $19 | The same. Still under oil. |
| carp, tilapia | $7 | $7, kept | Fish bait (four at $2) and fish oil (three under a drop's $26) are priced against the cheapest fish. |
| egg, milk | $4, $9 | $6, $11 | A day of animals was under summer's band. |
| wool, truffle | $10, $20 | $14, $24 | The same. The truffle stays under oil. |
| butter | $22 | $25 | It stays over its two pails of milk, and under oil. |
| cloth | $15 | $18 | It stays over its fleece; the sandbag still pays. |
| `DAY_TARGETS`, `DAY_FARM` | - | new | The bands, and the farm they assume. |

**What the numbers say:**
- **No one way wins every season.** Crops win spring and autumn, and the
  cliff and the woods win summer and winter. Fishing, the animals and the
  machines all sit inside every band they have.
- **Computed and played agree:**
  - the crops, the cliff and the woods and the machines to the dollar;
  - the animals within 7%, four played days against the steady state;
  - the pond within 8%, because its bites are drawn.
- **On the cliff, only the seams beat the trees for money**, even with wood
  at $1. Iron, copper, coal and gold are worth more as towers than as
  coins, which is what the iron is for.
- **The bands are wide on purpose** (low to high is about 2.2 times). The
  rule is "about one defence", and a band a whole season's ways of earning
  fit inside says that rather than ranking them.

## 0219 - the night's purse (2026-10-10)

**The rule** (plan section 4.6): the day earns the money and the night
spends it. The night pays essence for the tree, what it leaves lying about,
and a smaller purse. And "holding to the sunrise is worth as much as killing
everything".

**A night held well**, as `src/tools/night_pay.gd` prices it through the
rules (`Rewards._money_from`, `Rewards.preview`, `Tech.would_pay`):
- everything the night sent is killed;
- the house is untouched, nothing is lost and nobody gets through;
- eight defences stand without a scratch.

Materials are counted at what the stall pays for them, as a day is counted.

**A spring day** (0194):
- **the band:** $180-400 for a well-worked day, $290 in the middle;
- **one earner all day:** $308 from the field, $294 from the cliff and the
  woods, $238 from the pond;
- **0196's played Spring 9:** $1346, on a strawberry morning.

**A spring night held well, before and after:**

| Night | Money before | Money now | Materials before | Materials now | Essence before | Essence now |
|---|---|---|---|---|---|---|
| 1 | $138 | $38 | $62 | $21 | 4 | 4 |
| 2 | $177 | $41 | $89 | $22 | 4 | 4 |
| 3 | $210 | $42 | $116 | $23 | 4 | 4 |
| 4 | $285 | $46 | $143 | $24 | 4 | 4 |
| 5 | $326 | $49 | $170 | $25 | 4 | 4 |
| 6 | $391 | $52 | $197 | $26 | 4 | 4 |
| 7, Full Moon | $1146 | $124 | $448 | $54 | 4 | 8 |
| 8 | $549 | $61 | $251 | $28 | 4 | 4 |
| 9 | $638 | $65 | $278 | $29 | 4 | 4 |
| 10 | $657 | $67 | $305 | $30 | 4 | 4 |
| 11 | $763 | $72 | $332 | $31 | 4 | 4 |
| 12 | $853 | $77 | $359 | $32 | 4 | 4 |
| 13 | $942 | $82 | $386 | $33 | 4 | 4 |
| 14, Full Moon | $3042 | $222 | $826 | $68 | 4 | 8 |
| **Spring's average** | **$722** | **$74** | **$283** | **$31** | **4.0** | **4.6** |

**A spring night now pays about a quarter of a spring day.**
- Its $74 is 26% of the band's middle. Its materials are worth another $31.
- Before, a night held well paid two and a half days' money, and a day's
  materials besides.
- **The plan's own spring day** has night 8 paying "+2 essence, $40". Night
  8 held well pays $61 and 4 essence. The plan's night lost a fence, which
  costs the "nothing lost" point and the intact money.

**Holding and killing pay about the same, in spring.**
- A spring night's fee averages $17, and the bounty for killing everything
  $18 (5% of the kills' worth).
- Before, the bounty was $373 against a fee of $142.

**The seasons:**

| Season | A day's band | A night's money before | Now | Now, against the band's middle | Materials now | Essence now |
|---|---|---|---|---|---|---|
| spring | $180-400 | $722 | $74 | 26% | $31 | 4.6 |
| summer | $205-460 | $2265 | $152 | 46% | $59 | 4.3 |
| autumn | $235-530 | $3926 | $239 | 63% | $74 | 4.3 |
| winter | $270-610 | $5452 | $319 | 72% | $89 | 4.3 |

- **Later seasons still pay more than a quarter.** The bounty grows with
  the horde, ten times over the year, while the day's band grows half again.
- Holding every season near spring's share is 0278's: it now asks for it.
- The calm night of each season after the first pays its gift and no
  essence, which is why their averages are 4.3.

**Every lever moved** (`GameData.REWARDS`):

| Lever | Was | Now | Why |
|---|---|---|---|
| `base_money` | 30 | 10 | The fee for holding: spring's $17 average against $142 |
| `money_per_night` | 15 | 1 | It grew the fee to $870 by night 56 |
| `bounty_percent` | - (all of it) | 5 | New. Killing everything paid five times holding to dawn in spring, and the plan says the two are worth the same |
| `intact_structure_bonus` | 4 | 2 | Eight untouched defences paid $32 |
| `house_untouched_bonus` | 25 | 10 | With the rest, $26 of bonuses on a night held well, against $57 |
| `resources` | wood 10, stone 8, iron 4 | wood 5, stone 3, iron 1 | A spring night handed over $283 of materials, a day's worth |
| `resources_per_night` | wood 4, stone 3, iron 2 | wood 1 | Iron grew to 20 a night by night 9: almost two gun towers |
| `full_moon_essence_percent` | - | 200 | New. A Full Moon pays its essence twice, as it pays its money twice |

`standing_structure_bonus` (1) and `tech_points` (1) are unchanged. So are
the three essence bonuses and the Full Moon's money percent.

**What a kill shows.** The cursor's tooltip used to say what an enemy is
worth. It now says what killing one puts in the purse: a walker "$0.15", the
giant "$6".

**What the essence buys:**
- A year held well pays 256 essence at best and 64 at worst. That counts
  each Full Moon's share: eight Full Moons, two a season.
- Ten authored nights pay 44 at best, against a tree that costs 45.
- 0220 re-prices the tree against the year.

## 0221 - what the night leaves behind (2026-10-10)

**The rule** (plan sections 3.3 and 4.6): the morning picks up bones where
zombies fell and, after a Full Moon, moon stones along the horde's road. A
bone sells for $1 and becomes bone meal at 0222; a stone sells for $20 or
trades for 1 essence at the tree.

**Every body's bones were a second purse.** At a bone a body,
`src/tools/night_pay.gd` priced a spring night held well at 80 bones and a
winter one at 637 - more than the night's purse in every season, and in
winter more than a whole day. The plan's own spring morning picks up six.
The kills heap up where the towers stand: the autoplayer's spring nights
killed on 5 to 24 cells, so the pile cap alone did not hold it.

**So one body of a kind in `BONES_EVERY` (8) leaves its bones**: the
night's first, its ninth, its seventeenth; a boss always. What a night held
well leaves, before any pile is full (`night_pay.gd`'s new columns):

| Season | Bones a night | Their worth | With the moon stones, averaged | The night's purse | A day's band |
|---|---|---|---|---|---|
| spring | 11 | $11 | $23 | $74 | $180-400 |
| summer | 34 | $34 | $46 | $152 | $205-460 |
| autumn | 59 | $59 | $70 | $239 | $235-530 |
| winter | 82 | $82 | $93 | $319 | $270-610 |

- **Night 8 leaves 11** with everything it sent killed, and fewer as
  fewer fall.
- **A Full Moon's four stones** are $80 at the stall or 4 essence. Eight
  Full Moons are 32 stones a year: traded, they lift the best year's
  essence from 256 to 288, still short of the tree's 294.
- **What lies about fades** after `LOOT_FADE_DAYS` (3) mornings, so a farm
  nobody walks never holds more than three nights of it.

## 0222 - bone meal (2026-10-10)

**The rule:** two bones make a sack of bone meal at the workshop. A sack
puts one more morning of growth into one plot, once.

**Two bones a sack** (`grind_bone_meal`), against 0221's bones a night held
well:

| Season | Bones a night | Sacks a night |
|---|---|---|
| spring | 11 | 5 |
| summer | 34 | 17 |
| autumn | 59 | 29 |
| winter | 82 | 41, and nothing grows to spend them on |

- **A handful of plots in spring, never the field.** The starter beds hold
  sixty plots, and a spring night's bones fertilise five of them.
- **More later, as the field grows.** By autumn a night's sacks are
  about half a big field's.
- **A sack sells for $4**, its two bones for $2: `check_chain` holds.
- **What the morning is worth:** a plot's season divided by fourteen days.
  That is about $1 on a carrot and $5 on a strawberry, so the sack's price
  sits inside what it buys in the field.
- **The workshop can grind sixty sacks a day.** A sack takes twenty game
  minutes, so the bench is never what stands between the bones and the
  field.
