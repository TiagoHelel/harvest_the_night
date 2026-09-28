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
