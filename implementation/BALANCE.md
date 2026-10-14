# The year - task 0277 (2026-10-13 to 2026-10-14), done on the owner's twelfth call

**Done, on the target itself** (2026-10-14, "vai na 3"): fourteen runs of
sixteen win the year, every boss falls wherever the house stands, and
`towers` loses 3.4 nights before Winter 1, inside the phase's two to four.
`balanced` loses 6.0, two over. The rest - spring's 2.6 and autumn's 3.4 -
is left to 0278 and 0280, which look at the whole year. The calls below
are newest first.

**Eleventh block, after the owner's eleventh call** - see "The owner's
eleventh call, played" below: the Winter Lord's company at three quarters,
and fourteen runs of sixteen win the year. `balanced` still loses 6.0
nights before Winter 1, two over the target.

**Tenth block, after the owner's tenth call** - see "The owner's tenth
call, played" below: autumn's Full Moon at 80%, and twelve runs of sixteen
win the year. `towers` loses 3.4 nights before Winter 1, inside the
target; `balanced` loses 6.0.

**Ninth block, after the owner's ninth call** - see "The owner's ninth
call, played" below: the Winter Lord at 900/4, and eight runs of sixteen
win the year. Every boss falls wherever the house stands. `balanced` still
loses 7.5 nights before Winter 1 against a target of two to four.

**Eighth block, after the owner's eighth call** - see "The owner's eighth
call, played" below: autumn's curve at 6,400 with its nights kept in
rhythm, and winter's made nights under autumn's. Eleven runs reach winter,
`balanced` loses 7.5 nights before Winter 1, and the Winter Lord never
falls.

**Seventh block, after the owner's seventh call** - see "The owner's
seventh call, played" below: the King's company at three quarters, five
runs reach winter. The rest of autumn's weight is its curve, which moves
0273's rhythm and winter's, and winter falls from Winter 4.

**Sixth block, after the owner's sixth call** - see "The owner's sixth
call, played" below: the Scarecrow King (600/4) falls wherever the house
stands, and two runs reach winter. Autumn's last week stops the other
fourteen, and from Winter 4-5 no line holds.

**Fifth block, after the owner's fifth call** - see "The owner's fifth
call, played" below: a defence brought down is a ruin, mended back at half
its price. Every `balanced` run reaches autumn, spring costs it 2.6 nights,
summer is clean, and every boss to Summer 14 falls. Autumn's last week and
the Scarecrow King are where the year stops.

**Fourth block, after the owner's fourth call** - see "The owner's fourth
call, played" below: the robot saves for autumn's mortar and puts it up,
and autumn still falls from Autumn 7. Neither more iron, a lighter horde
nor a third side opened later changes the shape: a lost night takes the
line, and no run ever wins one back.

**Third block, after the owner's third call** - see "The owner's third
call, played" below: the Giant (400/4) and the Harvester (350/4) now fall
for every line that reaches them, spring's stall carries 16 iron, and the
year stops at Autumn 7, where no line fields autumn's weapons.

**Second block, after the owner's call** - see "The owner's call, played"
below: the robot now fields each season's weapons, and the Giant still ends
every fight with 550-750 of its 900. What follows first is the original
block.

**Why it is blocked, first.** The target is the phase's: `balanced`, the
average player, loses two to four nights before Winter 1 (day 43) over
eight seeds, and every boss falls for it on every seed. With the
instrument fixed, **`balanced` holds every spring night on every seed, and
then no boss falls**:

- **The Giant** (900 hit points, armour 6) takes about 250 from an average
  spring line and walks into the house. It falls at 500 and armour 4 - but
  0058's own asserts say every boss is better armoured than every other
  enemy (one has armour 4) and that **eighteen crossbows must not stop it
  while four mortars do**. Since 0234 the mortar opens in autumn: in spring
  nothing concentrates damage, so the two tasks already disagree, and the
  Giant cannot be made to fall for a spring player without breaking one of
  them.
- **The Harvester** takes 100-230 of its 700-1,100 even at the easy end of
  every one of its ranges, and its company knocks the house down first.
- **The Scarecrow King and the Winter Lord** (armour 5 and 7) are the same
  arithmetic and were never reached.

Armour is taken off every hit, and a hit never lands under one
(`Combat.MINIMUM_HIT`). Against armour 5-7, a gun or a bolt below level
three lands one to four, so what beats a boss is a season's heavy weapon or
level three - and the average robot fields neither: it has no supply chain
for oil or gunpowder. **The owner's call**, set out under "What is still
off": the bosses' armour against an average arsenal, a robot that plays
each season's weapons, or the boss nights' companies. No game value moved.

Measured with `python tools/balance.py`, which since this task reads only
the autoplayer's `RUN` lines (0276) and plays the calendar: a run is up to
56 dates, a boss night played again until its boss falls or the cap (6
repeats) ends the run. A boss that walks into the house is a repeat, not a
loss (0153), and is counted apart.

## The owner's eleventh call, played: the Winter Lord's company (2026-10-14)

The owner chose the Lord's company, as the King's was: "A horda do Winter
Lord a 75%". **Fourteen runs of sixteen win the year now**, seven of each
shooting policy. The Winter Lord falls on the first fight in every run
that meets him.

**What moved** (`src/core/game_data.gd`, key night 56):
- Every row of the Winter Lord's company at three quarters, rounded, with
  its releases stretched alike to the fill line.
- At 9,664 hit points it is still the year's largest night, over the
  King's 8,414, as 0274's rhythm asks.

### The year after it

`--year 8` (32 runs in 1,962 s, 8 processes, a run 122-976 s):

```text
  policy     lost: spring summer autumn winter   repeats: sp su au wi   over  capped
  balanced           2.6    0.0    3.4    1.8         1.9  0.0  2.2  0.0   7/8    1/8
  economy           17.0    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8
  towers             0.4    0.0    3.0    3.0         0.0  0.0  2.0  0.0   7/8    1/8
  walls              8.1    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8
```

What it says:
- **Fourteen runs of sixteen win the year**, where twelve did. Winter's
  boss repeats are 0.0: every run that reached the Lord took him down on
  the first fight.
- **Before Winter 1, nothing moved**: `towers` loses 3.4, inside the
  target, and `balanced` 6.0.
- **The two unwon runs both stop in autumn**: `balanced` 9035 loses its
  line from Autumn 8, and `towers` 9000 from Autumn 10. Neither gets past
  the King.

### Where the phase's target stands

The target is that `balanced` loses two to four nights before Winter 1 on
eight seeds, and every boss falls for it on every seed.
- **Every boss falls on seven seeds of eight.** On the eighth (9035) the
  King's night is never won.
- **`balanced` loses 6.0 nights before Winter 1**, two over the target:
  2.6 in spring and 3.4 in autumn.

### The next call is the owner's

1. **Spring's 2.6**: four of eight `balanced` seeds lose a line on Spring
   9-13 and win it back only over the Giant's repeats.
2. **Autumn's 3.4**, chiefly seed 9035, which loses its line from Autumn 8
   whatever the trials moved.
3. **Or the target itself**: `towers` meets it, `balanced` is two nights
   over, and fourteen runs of sixteen win the year. Calling 0277 done here
   would hand the rest to 0278 (the economy across a year) and 0280 (do
   fifty-six nights tire).

## The owner's tenth call, played: autumn's Full Moon (2026-10-14)

The owner chose autumn's Full Moon: "vai na 1, ajusta a lua cheia do
outono". **The Full Moon (night 35) is 80% of what 0273 wrote, and twelve
runs of sixteen win the year.** `towers` loses 3.4 nights before Winter 1,
inside the phase's two to four; `balanced` loses 6.0.

**What moved** (`src/core/game_data.gd`, key night 35):
- Its rows at 80%, rounded, and its releases stretched alike to the fill
  line.
- At 5,836 hit points it is still the largest night of autumn's first
  half, over Autumn 6's 5,561, and under the King's night, as 0273's
  rhythm asks.

### The trials

`balanced` on all eight seeds, to night 43:

| The Full Moon | Hit points | Autumn nights lost | Past the King |
| --- | --- | --- | --- |
| as it was | 7,254 | 39 | 6 of 8 |
| 90% | 6,492 | 24 | 5 of 8 |
| 85% | 6,308 | 44 | 5 of 8 |
| **80%** | **5,836** | **27** | **7 of 8** |

- **The trials are noisy.** 85% came out worse than either side of it. A
  night moved changes every night after it, and eight seeds are few.
- 80% is the share that took the most runs past the King with near the
  fewest losses. The year below is the measure that counts.

### The year after it

`--year 8` (32 runs in 1,913 s, 8 processes, a run 113-957 s):

```text
  policy     lost: spring summer autumn winter   repeats: sp su au wi   over  capped
  balanced           2.6    0.0    3.4    4.0         1.9  0.0  2.2  2.2   5/8    3/8
  economy           17.0    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8
  towers             0.4    0.0    3.0    5.1         0.0  0.0  2.0  2.1   7/8    1/8
  walls              8.1    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8

    balanced  autumn  100 100 100 100 100 100 100  75  75  88  75  62  62  62
              winter  100 100 100 100  57  71 100 100  86  71  57  86  71  29
    towers    autumn  100 100 100  88 100 100 100 100 100  88  75  75  75  62
              winter  100 100 100 100   0  43  86 100  71  57  43  71  86  29
```

What it says:
- **Twelve runs of sixteen win the year**: five `balanced`, seven `towers`.
  Eight did before.
- **Before Winter 1**: `towers` loses 3.4, inside the target, and
  `balanced` loses 6.0 (2.6 in spring, 3.4 in autumn, where it lost 4.9).
- **`balanced`'s three unwon seeds**:
  - **9028 and 9042** lose the house on the Winter Lord's night, every
    fight. His company (13,701 hit points, untouched) takes it before he
    is touched.
  - **9035** loses its line from Autumn 8 and never wins it back.

### The next call is the owner's

1. **The Winter Lord's company**, at three quarters as the King's was: the
   two seeds that reach him and cannot win.
2. **Spring's 2.6**: four of eight `balanced` seeds lose a line on Spring
   9-13 and win it back only over the Giant's repeats.
3. **Or the target**: `towers` already meets it, `balanced` is two nights
   over, and twelve of sixteen win the year.

## The owner's ninth call, played: the Winter Lord sized to winter's line (2026-10-14)

The owner chose the last boss: "vai na 1, faz o Winter Lord igual ao
Gigante". **The Winter Lord is 900 hit points and armour 4 now, and for
the first time runs win the year: eight of sixteen end it with him
down.** Every boss falls wherever the house stands on its night.

**What moved** (`src/core/game_data.gd`):
- The Winter Lord: 1,800 hit points and armour 7 become **900 and armour
  4**.
- He is still the strongest boss in the table, over the King's 600, as
  0255's test asks.
- His night (56) is untouched, still the year's largest.

### The Lord's grid

The eight runs that reached his night with the house standing in the
eighth call: `balanced` 9014, 9021, 9028, 9049; `towers` 9021, 9028,
9042, 9049. To night 57.

| Winter Lord | The year won | Where it was not |
| --- | --- | --- |
| 1,800/7 (before) | 0 of 8 | Left at 908-1,800 every fight |
| 1,200/4 | 7 of 8 | One fight left him at 84 with the house up |
| **900/4** | **7 of 8** | `towers` 9028 lost the house before he came |
| 700/4 | 7 of 8 | The same |

900 is the most tried that falls wherever the house stands, as the
Giant's 400 was.

### The year after it

`--year 8` (32 runs in 1,811 s, 8 processes, a run 119-824 s):

```text
  policy     lost: spring summer autumn winter   repeats: sp su au wi   over  capped
  balanced           2.6    0.0    4.9    3.8         1.9  0.0  2.9  2.4   5/8    3/8
  economy           17.0    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8
  towers             0.4    0.0    4.8    4.1         0.0  0.0  3.0  1.8   3/8    5/8
  walls              8.1    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8

    balanced  winter  100 100 100 100  83  50 100 100  83  67  67  83  83  33
    towers    winter  100 100 100 100   0  60 100 100  40  60  40  60  60  60
```

What it says:
- **Eight runs of sixteen win the year**: five `balanced` and three
  `towers`. Each fell to the Winter Lord on the first fight it met him
  with the house up.
- **The phase's target is not met yet.** `balanced` loses 7.5 nights before
  Winter 1 against a target of two to four, and three of its eight seeds
  do not see every boss fall:
  - **9007** loses the house on the King's night, every fight;
  - **9035** loses its line on autumn's Full Moon (35) and every night
    after;
  - **9042** loses Spring 9-14 and autumn's last week, then the house
    before the Lord is touched.
- `walls` and `economy` still do not get out of spring.

### The next call is the owner's

Every boss is sized now, so what is left is the nights before Winter 1:
1. **Autumn's Full Moon** (35, 7,254 hit points from three sides), where
   9035's line breaks and never comes back;
2. **Spring's 2.6**: four of eight `balanced` seeds lose a nine-defence
   line on Spring 9-13 and win it back only over the Giant's repeats;
3. **Or the target itself**: two to four nights before Winter 1, when
   `towers` already loses 5.1 and the year is won by eight runs of
   sixteen.

## The owner's eighth call, played: autumn's curve, with the nights kept in rhythm (2026-10-14)

The owner chose the curve: "vai na 1, baixa o outono e ajusta as noites".
**Autumn's thirteenth day is 6,400 now, its hand-written nights and
winter's made nights came down to keep the plan's rules, and eleven runs
of sixteen reach winter.** `balanced` loses 7.5 nights before Winter 1
where it lost 11.0. The Winter Lord is the one boss that never falls.

**What moved** (`src/core/game_data.gd`):
- **Autumn's template**: `size` [5200, 8400] becomes [5200, 6400].
- **Autumn's hand-written nights**, rows scaled and releases stretched
  alike so each still sends to the fill line:

  | Night | What it is | Share | Hit points |
  | --- | --- | --- | --- |
  | 31 | The north opens | 95% | 5,452 -> 5,274 |
  | 33 | The first crows | 88% | 6,160 -> 5,452 |
  | 36 | The first diggers | 83.5% | 6,894 -> 5,635 |

  Each one lands between its made neighbours, so autumn still grows night
  by night to its Full Moon (35, unchanged) and on to the King's night (42,
  at three quarters since the seventh call).
- **Winter at 78%**: the template's [8400, 9800] becomes [6550, 7640], and
  the hand-written 45-50 come down alike: the west, the south, the frost
  zombie, the Full Moon and the wraith. This is 0274's rule: winter's made
  nights send no more bodies than autumn's (291 against 299).
- **The Winter Lord's night (56) is untouched**, at 13,701 hit points.
  Nothing asked it to move, and it is the owner's call.

How the numbers were found: `tune.py` (in the scratchpad) writes a set of
shares, measures every night from Summer 14 to Winter 14 (hit points,
bodies, fill), and checks the rules 0273 and 0274's tests hold:
- each season's rhythm;
- winter's bodies under autumn's;
- 56 the year's largest night;
- every night sent to the fill line.

The first set passed. Night 36 was then moved off a nine-hit-point margin
over 34.

### The year after it

`--year 8` (32 runs in 2,010 s, 8 processes, a run 122-993 s):

```text
  policy     lost: spring summer autumn winter   repeats: sp su au wi   over  capped
  balanced           2.6    0.0    4.9    4.6         1.9  0.0  2.9  5.2   0/8    8/8
  economy           17.0    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8
  towers             0.4    0.0    4.8    5.2         0.0  0.0  3.0  4.4   0/8    8/8
  walls              8.1    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8

  autumn  no dominant strategy: clean runs balanced 4, towers 3, economy 0, walls 0

    balanced  autumn  100 100 100 100 100 100  75  62  62  62  62  50  50  50
              winter  100 100 100 100  83  50 100 100  83  67  67  83  83  33
    towers    autumn  100 100 100  88 100 100  88 100  88  88  62  50  62  50
              winter  100 100 100 100   0  60 100 100  40  60  40  60  60   0
```

What it says:
- **Eleven runs reach winter** (six `balanced`), where five did. **`balanced`
  loses 7.5 nights before Winter 1**, where it lost 11.0: 2.6 in spring
  and 4.9 in autumn. The phase's target is two to four.
- **The King falls in most runs now**: autumn's boss repeats are 2.9 a run
  where they were 5.8.
- **Winter is held**, most nights by most lines.
- **The Winter Lord never falls.** Every fight in every run leaves him at
  908-1,800 of 1,800, and each run ends on his night at the cap.
- **What still loses autumn**: `balanced` 9035 from its Full Moon (35)
  to the end, and 9042 from 36. `balanced` 9007 loses 40-42.

### The next call is the owner's

1. **The Winter Lord** (1,800/7), sized to winter's line as the other three
   bosses were: the year's last wall.
2. **What is left before Winter 1**: 7.5 nights against a target of two to
   four. The rest is autumn's Full Moon (35) on some seeds and spring's
   2.6.

## The owner's seventh call, played: autumn's last week (2026-10-14)

The owner chose autumn's last week next: "vai no outono". **The King's
company is three quarters of what 0273 wrote now, and five runs reach
winter where two did.** The rest of autumn's weight is in its curve, and
lowering that rewrites 0273's rhythm and winter's.

**What moved** (`src/core/game_data.gd`, key night 42):
- **Every row of the Scarecrow King's company at three quarters**,
  rounded: walkers 36 to 27, breakers 16 to 12, tanks 12 and 10 to 9 and
  8, and so on. Its crows go from sixteen to twelve.
- **Its releases stretched** from 10 ticks to 13, so the night still sends
  to the fill line: to tick 4,528 of a 3,600-5,400 window.
- **Three quarters is as low as it goes.** At 8,414 hit points the night is
  still the season's largest, over Autumn 13's 8,281, as 0273's rhythm
  asks.

### The trials

`balanced` on all eight seeds, to night 43 (the King at 600/4 in every
row):

| Autumn's curve (2nd -> 13th day) | The King's company | Autumn nights lost | Past the King |
| --- | --- | --- | --- |
| 5,200 -> 8,400 (as it is) | all of it | 82 | 1 of 8 |
| 5,200 -> 7,600 | all of it | 83 | 1 of 8 |
| 5,200 -> 7,000 | all of it | 86 | 1 of 8 |
| 5,200 -> 6,400 | all of it | 71 | 1 of 8 |
| **5,200 -> 8,400** | **75%** | **67** | **2 of 8** |
| 5,200 -> 7,600 | 75% | 52 | 4 of 8 |
| 5,200 -> 6,400 | 75% | 37 | 7 of 8 |
| 5,200 -> 6,400 | 60% | 37 | 6 of 8 |

What it says:
- **The King's company was the wall on its own night.** At full strength
  it took the house before the King was touched, every fight, on six
  seeds of eight. At three quarters the King is fought: left at 97-528,
  or down.
- **The bigger win is autumn's curve**: 5,200 -> 6,400 with the company at
  three quarters halves the losses, 82 to 37. **It is not in this
  change**, because it breaks two of the plan's rules, which 0271-0274
  wrote and 0273's and 0274's tests hold:
  - **The rhythm.** Autumn's made nights must grow from day to day around
    its hand-written ones: the north on 31, the crows on 33, the diggers
    on 36. A lower curve puts Autumn 4, 6 and 9 under the night before
    them.
  - **Winter sends no more bodies than autumn.** A lighter autumn puts
    winter's made nights over it.
  Both are the plan's shape, so the owner's to move.

### The year after it

`--year 8` (32 runs in 1,914 s, 8 processes, a run 120-902 s):

```text
  policy     lost: spring summer autumn winter   repeats: sp su au wi   over  capped
  balanced           2.6    0.0    8.4    3.0         1.9  0.0  5.8  1.8   0/8    8/8
  economy           17.0    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8
  towers             0.4    0.0    9.2    5.1         0.0  0.0  5.4  2.6   0/8    8/8
  walls              8.1    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8

    balanced  autumn  100 100 100  75  88  88  75  75  75  75  62  25  12   0
              winter  100 100 100   0   0   0   0   0  50 100   0 100   0   0
    towers    autumn  100 100 100  88 100 100  62  62  50  38  38  25  25  12
              winter  100 100 100  33   0   0   0   0  33  33  33  33   0   0
```

- **Five runs reach winter**: `balanced` 9042 and 9049, `towers` 9035, 9042
  and 9049. Two did before.
- **Autumn lost**: `balanced` 10.2 to 8.4, `towers` 10.2 to 9.2.
- **Winter holds Winter 1-3.** From Winter 4 few lines hold: the south
  opens on it and the frost zombie comes on Winter 5. The
  Winter Lord (1,800/7) was left at 1,039-1,800.

### The next call is the owner's

1. **Autumn's curve**: 5,200 -> 6,400 halves autumn's losses (82 to 37
   with the company at three quarters). It means rewriting 0273's rhythm,
   lowering the north's, the crows' and the diggers' nights to match, and
   winter's made nights under autumn's.
2. **Winter**, from Winter 4, and **the Winter Lord**, the last boss still
   at his first numbers.

## The owner's sixth call, played: the Scarecrow King sized to autumn's line (2026-10-13)

The owner chose the first road again: "vai na 1, faz o King igual ao
Gigante". **The King is 600 hit points and armour 4 now, and falls on the
first fight wherever the house stands.** Two runs reach winter for the
first time. The fourteen that do not are stopped by autumn's last week,
not by the King.

**What moved** (`src/core/game_data.gd`):
- The Scarecrow King: 1,200 and armour 5 become **600 and armour 4**.
- Armour 4 is the tank's, as the Giant's and the Harvester's are. Every
  boss is still at least as well armoured as anything that is not one, as
  0058's relation reads since the third call.
- The Winter Lord's 1,800 is still the most.

### The King's grid

The eight runs nearest its night: `balanced` 9007, 9028, 9042, 9049;
`towers` 9028, 9035, 9042, 9049. To night 43.

| King | It fell | Where it did not |
| --- | --- | --- |
| 1,200/5 (before) | 0 of 8 | The house went before it was touched, or it was left at 712-906 |
| 600/4 | 2 of 8 | The house went first: it was at 600 every fight, or never came |
| 450/4 | 2 of 8 | The same |
| 350/4 | 2 of 8 | The same |

- **`towers` 9049** now takes it down on the first fight, where it left
  747-906 of 1,200. **`balanced` 9049** takes it down once its line
  holds.
- **Below 600 its hit points change nothing**: in the other six runs no
  line ever hurt it.

### The year after it

`--year 8` (32 runs in 1,628 s, 8 processes, a run 114-748 s):

```text
  policy     lost: spring summer autumn winter   repeats: sp su au wi   over  capped
  balanced           2.6    0.0   10.2    2.1         1.9  0.0  6.8  0.9   0/8    8/8
  economy           17.0    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8
  towers             0.4    0.0   10.2    1.6         0.0  0.0  6.1  0.9   0/8    8/8
  walls              8.1    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8

    balanced  autumn  100 100 100  75  88  88  75  75  75  75  62  25  12   0
              winter  100 100 100   0   0   0   0   0   0   0   0   0   0   0
    towers    autumn  100 100 100  88 100 100  62  62  50  38  38  25  25  12
              winter  100 100 100 100   0   0   0   0   0   0   0   0   0   0
```

What it says:
- **Two runs reach winter**, both on seed 9049. They hold Winter 1-3 or
  1-4, then lose every night to the cap. The Winter Lord (1,800/7) was
  left at 1,159-1,298.
- **Autumn's last week stops the other fourteen.** Their house falls on
  Autumn 12-14, and on the King's night before the King is touched, every
  fight.
- Spring and summer are as the fifth call left them.

### The next call is the owner's

1. **Autumn's last week** (Autumn 12-14 and the King's company): only 0-25%
   of lines hold it.
2. **Winter**: from Winter 4-5 no line holds. The Winter Lord at 1,800 and
   armour 7 is the last boss still at its first numbers.

## The owner's fifth call, played: a defence brought down is a ruin, mended back (2026-10-13)

The owner chose the first road for what a lost night costs: "vai na 1,
defesa zerada fica destruída e conserta". **Every `balanced` run now
reaches autumn, spring costs it 2.6 nights, and summer is clean for both
shooting policies.** Autumn's last week and the Scarecrow King are where
the year stops now.

**The rule** (`Building.ruins`, `Farm`, `Repair`):
- **A defence brought to 0 leaves a ruin.** Its cell is open as before:
  nothing to shoot with or at, a hole the field routes through. Its id and
  level stay in the state's `ruins` past the morning's sweep.
- **The rubble is still only the night's**, so the night's payout and
  "nothing lost" count only tonight's.
- **Not a trap** (spent), **not one walked over** (the bait and the
  garlic, eaten), and **not one with a lifetime** (the barricade, which
  would come back a wall that never rots).
- **A ruin is mended back** by the same road a hurt defence is: the cursor
  in the build step or at night, `Repair`. The first hit point raises it
  on its cell at its level, and mending goes on to whole. A whole mend
  costs `REPAIR_PERCENT` (50%) of what it is made of: a gun about 5 iron in
  place of 12, a level two keeping its level.
- **Something built over a ruin takes its place.**
- **Not a wreck that stands**, as a coop or barn does since 0186. A
  standing wreck would be a wall the zombies cannot bite and the guns
  cannot see, and every system that reads a defence would have had to
  learn to skip it. A ruin is not an occupant, so none of them had to.

**The view** draws a ruin with the wreck art the night's rubble already
used, at its level, until it is mended. A new scene, `ruins`, shows a line
the morning after.

**The robot** (`src/tools/autoplay.gd`):
- **Mends its ruins first.** The plan saves for each ruin's whole mend
  before anything new.
- **Raises a ruin only whole.** On the first try it raised them on the
  three hit points the purse ran to, and the next bite took them down.
- **Does not count a ruin as lost**, so it does not buy one again at full
  price.

### The year after it

`--year 8` (32 runs in 1,726 s, 8 processes, a run 117-659 s):

```text
  policy     lost: spring summer autumn winter   repeats: sp su au wi   over  capped
  balanced           2.6    0.0   10.4    0.0         1.9  0.0  7.0  0.0   0/8    8/8
  economy           17.0    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8
  towers             0.4    0.0   11.1    0.0         0.0  0.0  7.0  0.0   0/8    8/8
  walls              8.1    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8

  spring  no dominant strategy: clean runs towers 5, balanced 4, economy 0, walls 0
  summer  no dominant strategy: clean runs balanced 8, towers 8, economy 0, walls 0

    balanced  spring  100 100 100 100 100 100 100 100  88  88  88  75  50  50
              summer  100 100 100 100 100 100 100 100 100 100 100 100 100 100
              autumn  100 100 100  75  88  88  75  75  75  75  62  25  12   0
    towers    spring  100 100  62 100 100 100 100 100 100 100 100 100 100 100
              summer  100 100 100 100 100 100 100 100 100 100 100 100 100 100
              autumn  100 100 100  88 100 100  62  62  50  38  38  25  25   0
```

Against the year before it (the mortar rule on, no ruins):

| | Before | After |
| --- | --- | --- |
| `balanced` runs that reach autumn | 4 of 8 | **8 of 8** |
| `balanced` spring nights lost | 4.8 | **2.6** |
| `balanced` autumn, Autumn 7-10 held | 0% | **75%** |
| `towers` autumn, Autumn 9-11 held | 12% | **38-50%** |

What it says:
- **A lost night is won back now.** `balanced` 9000 lost Spring 12-13 and
  its line, mended seven ruins over the Giant's repeats, and took the
  Giant down. 9021 and 9049 did the same.
- **Every boss to Summer 14 falls on every seed.** The Giant fell for all
  eight `balanced` runs, some after repeats, and the Harvester fell on
  the first fight for all sixteen runs that met it.
- **Autumn's last week is the wall.** From Autumn 12 three lines in four
  fall, and the Scarecrow King was fought in four runs: untouched (the house
  went first) or left at 712-906 of its 1,200.
- `walls` and `economy` still do not get out of spring.

### The next call is the owner's

1. **The Scarecrow King sized to autumn's line**, as the Giant and the
   Harvester were. At 1,200 and armour 5 every line that reached it took
   300-500 a fight.
2. **Autumn's last week** (Autumn 12-14, the diggers and the King's
   company): 0-25% of lines hold it.

## The owner's fourth call, played: the robot saves for the mortar (2026-10-13)

The owner chose the first road for autumn: "vai na 1, faz o robô guardar
ferro pro morteiro". **The robot now saves for autumn's mortar and puts it
up, and autumn still falls from Autumn 7.** Neither of the other two roads
moves it either; what does is below.

**What moved in the instrument** (`src/tools/autoplay.gd`):
- **A season plan names its weapon**: `"weapon": &"mortar"` in `balanced`'s
  and `towers`' autumn.
- **`_season_weapon`**: that weapon, while none stands and every part of
  its bill can be come by (no press, no gunpowder, nothing saved).
- **The plan saves for it first** (`_the_plan_ahead`), after what the
  nights took and before the boss prep and the cursor's next thing.
- **The day waits for its gunpowder** rather than walking round it, and
  gets the rest of its bill meanwhile.
- **Its bill is kept** (`_kept_for_weapon`) from every mine, level and new
  defence, by day and by night. What the nights took is still put back
  first.
- **The build step puts it up first** once it is paid for.

No game value moved.

### What it did

Traced on seed 9000, Summer 14 to Autumn 10:
- **`towers`**: the cursor stays on the mortar from Autumn 2. Iron goes 8,
  7, 26, 43 while the line holds at seven guns and seven crossbows, and the
  mortar stands on Autumn 5. On Autumn 6 the line drops from eight guns to
  four, on Autumn 7 to two, and the house falls.
- **`balanced`**: iron never passes 17 before the same collapse on Autumn
  6-7, so its mortar never stands.

The year, `--year 8`, against the one before it:

| Policy | Autumn lost, before | After |
| --- | --- | --- |
| balanced | 6.9 | 7.0 |
| towers | 10.9 | 12.2 |

Saving for the mortar costs the guns it would have bought, and one mortar
does not hold Autumn 7.

### The other two roads, tried

The eight runs that reach autumn (`towers` 9000, 9014, 9021, 9035;
`balanced` 9000, 9007, 9028, 9035), the mortar rule on, to night 43:

| Trial | Autumn nights lost |
| --- | --- |
| As it is | 107 |
| The stall's iron at 16 all year | 107 |
| Autumn's horde at [5200, 6400] | 102 |
| Autumn's third side opened on its last day | 98 |

- **More iron at the stall moves nothing**: the line falls on the same
  nights with 16 a day as with 8.
- **A lighter horde, or two sides in place of three, buys one to three
  nights.** The first loss comes on Autumn 9-11 instead of 7-9, and then
  every night after it is lost too.

### What every trial shows: a lost night is never won back

In every run of every trial, autumn's losses are an unbroken run from the
night that starts them to the cap: `lost=35,36,37,38,39,40,41,42,42,...`.
One `towers` run lost a single Autumn 4 before its run began. The same
is true of `balanced`'s spring on its four bad seeds.

A lost night takes the line: four to eight towers in one night, the house
at 0. A gun is 12 iron to put back and a crossbow 20, and the farm brings
in 10-20 iron a day. The next night is a bigger horde against a thinner
line, and the line never comes back.

The trials only move the night the first loss comes on. What would change
the shape is what a lost night costs.

### The next call is the owner's

1. **What a lost night costs the line.** For example, a defence brought to
   0 stands wrecked, to be mended with food and wood, as a coop or a barn
   has since task 0186, rather than being lost and paid for again in iron.
2. **The robot rebuilds out of what it has**: walls, kits and mending
   before new iron.
3. **Autumn's Full Moon and its third side**, which bring the first loss
   two to four nights earlier.

The mortar rule stays, as the owner asked: whatever comes next, autumn's
line should have its mortar.

## The owner's third call, played: the bosses sized to the season's line (2026-10-13)

The owner chose to combine two roads: a little more iron at spring's stall
and a weaker Giant, with 0058's rule rewritten only as far as needed. Then,
once the Giant fell and summer was reached: "faz o Harvester igual ao
Gigante".

**What moved in the game** (`src/core/game_data.gd`):
- **The Giant**: 900 hit points and armour 6 become **400 and armour 4**.
- **The Harvester**: 1,100 and armour 6 become **350 and armour 4**.
- **`SPRING_IRON` 16**: a spring morning's stall carries 16 iron, against
  the year's `DAILY_STOCK` of 8.

Armour 4 is the tank's. A spring gun (6 a shot) lands 2 of it, and a bolt
(5) lands the minimum.

**What moved in 0058's test**, and nothing else in it:
- "Every boss is better armoured than every other enemy" becomes "at least
  as well armoured": the Giant's 4 is the tank's.
- "A line of nothing but crossbows does not stop it" becomes "a line of
  spring's crossbows stops it". Since 0234 the mortar opens in autumn, so a
  spring boss eighteen crossbows could not stop was one no spring player
  could kill. Four mortars still do it for less money: 18 crossbows ($3,330)
  kill it in 480 ticks, 4 mortars ($3,040) in 522. A mixed defence still
  has 28 seconds to spare.

**What moved in the instrument**:
- **Bought before dug** (`BUY_BEFORE_DIGGING` 60): with money over the
  plan's, the field's packets and 60, the robot buys the stall's iron
  rather than dig it.
- **`boss_left` on the `RUN` line**: each boss fight's fewest hit points,
  0 when it fell. `tools/balance.py` reads it as a list.
- `tools/balance.py`'s Giant levers match the Giant's own lines, since the
  Harvester's range comments are the same now.

### The Giant's grid

`balanced` and `towers` on seeds 9000, 9001, 9007 and 9014, to night 15,
the buy rule on. "First fight" is a run where it fell on Spring 14's first
night; "fell" is a run where it fell at all, within the six repeats.

| Giant | Spring iron | First fight | Fell | Spring nights lost |
| --- | --- | --- | --- | --- |
| 900/6 (before) | 8 | 0 of 8 | 0 of 8 | 26 |
| 700/4 | 20 | 0 of 8 | 1 of 8 | 29 |
| 600/4 | 20 | 0 of 8 | 3 of 8 | 28 |
| 600/4 | 8 | 0 of 8 | 3 of 8 | 25 |
| 500/4 | 20 | 1 of 8 | 3 of 8 | 27 |
| 500/3 | 20 | 6 of 8 | 6 of 8 | 17 |
| 550/3 | 16 | 6 of 8 | 6 of 8 | 17 |
| **400/4** | **16** | **6 of 8** | **6 of 8** | **17** |
| 350/4 | 16 | 6 of 8 | 6 of 8 | 17 |

What it says:
- **A spring line takes 350-590 off it a fight at armour 4**, whatever the
  stall holds: at 600/4 `balanced` left it at 144-254 and `towers` at
  12-211.
- **400 is the most hit points tried at armour 4 that falls on the first
  fight** everywhere the house stands. Armour 3 falls at 550 too, but would put the
  Giant under the tank, which 0058's relation would then have to drop.
- **The two runs it never falls in** (`balanced` 9001 and 9014) lose the
  house before it takes a shot. Their line goes from nine defences to two
  in one night, on Spring 11 or 13, with the house untouched. With 0-20
  iron and under $450, the robot rebuilds a gun a night, and Spring 14,
  repeated, takes that too.
- **Spring's stall iron moves nothing the robot does**: 600/4 at 8 and at
  20 measured the same, as 20 and 40 did before. The robot buys it now,
  one to three times a day, but by Spring 11 its purse is $100-450, not the
  $1,500-2,700 of the first block's robot. It stays at 16 as the owner
  asked: a player who buys it has it.

### The Harvester's grid

The four seeds that reached summer (9000, 9007, 9028 and 9035), to night
29:

| Harvester | First fight | Fell | Summer nights lost |
| --- | --- | --- | --- |
| 1,100/6 (before) | 0 of 8 | 0 of 8 | (the year: every run stopped on Summer 14) |
| 500/4 | 3 of 8 | 5 of 8 | 13 |
| 400/4 | 6 of 8 | 7 of 8 | 2 |
| **350/4** | **7 of 8** | **8 of 8** | **0** |

- At 1,100/6 every line took 60-300 off it a fight.
- At 400/4 `balanced` 9007 left it at 16-88 every fight. 350 is under the
  Giant's 400: its charge takes the line's towers down as it comes.

### The year after both

`python tools/autoplay.py --year 8` (32 runs in 1,066 s, 8 processes, a run
111-507 s):

```text
  policy     lost: spring summer autumn winter   repeats: sp su au wi   over  capped
  balanced           4.8    0.0    6.9    0.0         3.6  0.1  3.5  0.0   0/8    8/8
  economy           17.0    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8
  towers             0.4    0.0   10.9    0.0         0.0  0.0  7.0  0.0   0/8    8/8
  walls              9.5    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8

  summer  ALARM: 'towers' gets through it clean 8 times where the next gets 4 - a dominant strategy
  autumn  ALARM: no policy got through it without a loss

    balanced  spring  100 100 100 100 100 100 100 100  88  88  88  75  50  38
              summer  100 100 100 100 100 100 100 100 100 100 100 100 100 100
              autumn  100 100 100 100 100 100  25   0   0   0   0   0   0   0
    towers    spring  100 100  62 100 100 100 100 100 100 100 100 100 100 100
              summer  100 100 100 100 100 100 100 100 100 100 100 100 100 100
              autumn  100 100 100  88 100 100  75  75  50  50  50  12  12   0
```

What it says:
- **Both bosses fall.** The Giant falls in every run that holds Spring 13:
  8 of 8 `towers`, 4 of 8 `balanced` (one after a repeat). Every run that
  reaches summer
  holds all of it, and the Harvester falls on the first fight in all of
  them but one (`balanced` 9035, 30 hit points short, then down).
- **Summer's alarm is spring's**: only the four `balanced` runs that got
  through spring reached summer, and all four held it.
- **Autumn is the new wall, from Autumn 7.** The runs that reach it hold
  Autumn 1-6 (one night lost in all), then lose most of what follows. The Scarecrow King
  was fought once: `towers` 9049 left it at 960 of 1,200.
- `walls` and `economy` are where they were: they do not get out of
  spring.

### Why autumn falls: the robot never fields autumn's weapons

Traced (`towers` and `balanced` on seed 9000, Summer 14 to Autumn 9):
- **The line that meets Autumn 7 is guns and crossbows**: 4-10 guns, 3-7
  crossbows, 2-5 mines. Not one mortar or catapult stood on either run.
- **The plan walks round them.** The mortar costs 35 iron and 15
  gunpowder, and the catapult 4 pumpkins. The cursor passes over both and
  the plan buys guns and mines in their place.
- **Iron again**: 0-14 every autumn morning, while wood sits at 800-1,000
  and money at $300-1,100. A gun wants 12 iron and a level 15-18, and
  what comes goes there.
- Autumn's horde comes at 5,200 hit points on its second day and 8,400 on
  its thirteenth, where summer's ended at 5,000. Around 6,700 on Autumn 7
  is where a guns-and-crossbows line stops holding.

### The next call is the owner's

- **Autumn** - which of:
  1. **The robot saves for its season's weapon** before it adds guns. This
     is the instrument: a player shown the mortar puts iron aside for it.
  2. **Iron through the year**, as spring's: the stall's `DAILY_STOCK`
     iron, or the mortar's 35.
  3. **Autumn's horde**: `autumn size` [5200, 8400].
- **`balanced`'s spring.** Four of eight runs lose a nine-defence line in
  one night on Spring 9-13 and never rebuild it. That is the boss nights'
  companies, or the breakers, and it is unmeasured which.

## The owner's call, played: a robot that fields each season's weapons (2026-10-13)

The owner chose the second road: before any boss number moves, make the
average robot play what each season offers. **It does now, and the Giant
still does not fall: it ends every fight with 550-750 of its 900 hit
points.** The robot is no longer the reason; the next call is the bosses'
numbers (the first road) or their companies (the third).

**What the robot learned** (`src/tools/autoplay.gd`). Each item is a fault a
losing run showed, fixed in the instrument, not tuned around:
- **It makes what it cannot dig** (`_can_be_had`, `_make`, `_come_by`):
  - Gunpowder at the workshop from the seams' coal and oil, and oil at the
    press from fish, corn or sunflowers. Incendiary from oil, and the
    catapult's pumpkins in the field (`_field_crop`).
  - It follows a recipe two deep (`MAKE_DEPTH`) and puts one batch on at a
    time (`_on_order`). A batch waiting on its inputs is fed, not doubled.
  - It used to plan around every ingredient nobody could dig, so no mine,
    no mortar round and no level three was ever reached.
- **Each season has its plan and its tree** (a policy's `seasons`):
  - **Spring**: the press, three mines and `oiled works` - level three -
    in `balanced`'s tree.
  - **Summer**: the flamethrower, `a standing order` and `heavy shot`.
  - **Autumn**: the mortar, the catapult and `tall mounts`.
  - **Winter**: the searchlight, the electric fence and `greased works`.
  - `towers` gets the same in its own order. `walls` and `economy` keep
    their year-round plans.
  - The cursor starts from the top on each season's first morning.
- **Rounds and a reserve kept** (`_stock_up`):
  - `AMMO_PER_DEFENCE` (12) of whatever a standing defence fires, before
    the plan.
  - Once a press stands and the plan or the tree wants gunpowder, a
    `POWDER_RESERVE` (18), out of the time the plan leaves. Put first, the
    reserve left Spring 9 with three guns and 300 wood.
- **The bench makes only what the farm spends** (`_worth_making`,
  `BENCH_GOODS`):
  - Food, bread, hay, oil, gunpowder and incendiary, and at most two kits
    (`KITS_AHEAD`) of a defence the plan puts up.
  - Only when the inputs are in the bag now, and never out of the chain the
    plan is making (`_chain_of`).
  - Before this it turned the towers' wood into 44 barricade kits, and
    when told to skip bone meal it moved on to bait. It filled the
    workshop with corn gunpowder no spring grows, and let the kitchen cook
    every fish the press was waiting on.
- **The boss prep**:
  - It arms the mines first, up to the mine's `armed_limit`. A mine goes
    on the free cell of tonight's horde road nearest the house
    (`_mine_spot`). By the house, off the road, seven Giant nights set
    none off.
  - Then it deepens the line: every shooter before any wall, and only for
    a bill the farm can come by now (`_to_be_had_now`). It had stopped
    for a week on a wall wanting hardwood that no stump on the farm could
    give.
- **A rebuild is not a new tower** (`_place_by_cursor`'s `counted`).
  - This was 0276's: counted, a rebuilt tower left the lost count where it
    was, so the same lost gun went back up every night. By Spring 14 there
    were twenty-five guns at level one, and never the iron for a mine.
- **The night row** carries `boss_left`, the fewest hit points the boss was
  seen at.

**The year, after** - `python tools/autoplay.py --year 8` (32 runs in 600 s,
8 processes, a run 92-177 s):

```text
  policy     lost: spring summer autumn winter   repeats: sp su au wi   over  capped
  balanced           3.0    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8
  economy           17.0    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8
  towers             3.6    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8
  walls              9.4    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8

  spring  ALARM: 'balanced' gets through it clean 4 times where the next gets 1 - a dominant strategy

    balanced  spring  100 100 100 100 100 100 100 100  88  88  88  88  75  50
    towers    spring  100 100  62 100 100 100 100 100 100 100 100 100 100  12
    walls     spring  100 100 100 100 100 100  75 100 100  88  88  12   0   0
    economy   spring  100 100 100   0   0   0   0   0   0   0   0   0   0   0

  days no run of any policy held: none
```

**The Giant, fight by fight** (`boss_left`, Spring 14, eight fights each):

| Run | Its line on Spring 14 | Hit points left after each fight |
| --- | --- | --- |
| `balanced` 9000 | 5-7 guns, 2 crossbows | 741 724 740 729 737 733 753 716 |
| `balanced` 9001 | 6 guns (one at level 2), 3 crossbows | 741 756 749 713 720 719 687 708 |
| `towers` 9000 | 5 guns (one at level 2), 3 crossbows, a mine | 706 718 719 721 701 703 695 713 |
| `towers` 9001 | 4 guns (two at level 2), 3 crossbows, a mine | 650 668 630 579 570 900 559 550 |

What it says:
- **The Giant loses 150-350 a fight to every line the robot fields**, and
  each fight it starts again at 900. Between 0277's first block and this
  one, the season's weapons moved it from about 250 to the same 150-350:
  mines and level two on a spring income do not add up to 900.
- **The binding number is spring's iron.** Every line ran at 3-20 iron
  with hundreds of wood and money. A mine is 5 iron and 8 powder, a level
  two gun 20 iron, a level three 35 iron and 10 powder, and a new gun 12
  iron. Mines and levels compete with the towers that hold spring.
- **Spring got harder for the robot that prepares**: `balanced` now loses
  3.0 nights in spring (Spring 9-14 on some seeds), where it lost none
  when it built guns only. The press, the reserve and the mines are bought
  out of the guns.
- **Nothing reaches summer**, so the Harvester, the Scarecrow King and the
  Winter Lord stay unmeasured. The new summer, autumn and winter plans
  have not had a night to play yet.

**The next call is the owner's**, from the same list, now that the robot
fields what a season gives:
1. **The bosses' numbers**, with 0058's relation rewritten. From the trials
   below, the Giant falls in one fight at 500-600 hit points and armour
   3-4.
2. **The boss nights' companies**, so the guns' time goes to the boss.
3. **Spring's iron** (the seams and the stall), so mines and levels are
   not paid for with towers. This one is new: the data puts it there.

## The instrument first, as 0068 found

0276's year had every run of every policy stop on Spring 14, the Giant
fought seven times. Asked what it was doing, a losing run showed eight
faults in the robot before it showed one in the game. Each was fixed in
`src/tools/autoplay.gd`, not tuned around:

| What the robot did | What it cost | Fixed |
| --- | --- | --- |
| Built generators and never fed them | Spring 7 on seed 9000 fought with six guns at the 50% power floor, three plants standing and nothing to burn | `_feed_the_generators`: coal from the seams while the oil and coal in the store are under four tanks a plant |
| Bought the plan's iron with its seed money | Tilled plots stood empty for days | Packets before the plan's materials, and the field's packet bill (`_seed_bill`) kept back when the stall sells the plan its iron |
| Had no kitchen, and shipped every carrot and fish it had | No food, so no mending: towers chewed down by breakers and never repaired | `towers`, `walls` and `balanced` build a kitchen third or fourth (only `economy` had one), and the bin leaves what the farm's stations eat |
| ...then kept nine of every fish for that kitchen | Thirty fish in the bag for six days, $3 in the purse and a tower to put back | Two batches of a station's input (`KEEP_BATCHES`), a group such as the fish counted as one |
| Upgraded with the iron its next tower was saving | Met Spring 6's rain with two guns | An upgrade only out of what the plan's next thing leaves |
| Walled its own porch in with a kitchen and a second generator | Woke on Spring 13 in a strip of six cells, went back to bed at 06:00, lost the night, and the spiral to the Giant began there | `_room_for` refuses a cell that cuts any ground off from the porch (`_keeps_the_road`, `ROAD_SLACK` 3) |
| Never upgraded once all spring | Met the Giant with ten level-one towers - a gun's six and a bolt's five landing one each through armour six - and its company knocked the house down before it arrived | **Ready for the boss**: from five nights before a boss night (`boss_prep_days`, 0234's "days of focused saving") the line is deepened, the lowest tower first, and nothing new goes down while an upgrade is unpaid. The house now holds on Spring 14 at every value tried |
| Built `balanced`'s generator before its third gun | Twenty iron not in a tower when spring's first tank came | After the crossbow |

**Tried and taken back:**
- **deepening all spring** (the plan's next gun an upgrade once three
  stood): too few towers for the hordes, and seed 9014 fell on Spring 11
  and never recovered;
- **summer's flamethrower in `balanced`'s plan, with a press for its oil**:
  the plan saved for it all summer and never had the oil, and met
  Summer 14 with fewer towers than before.

Not a fix, a tool: the `RUN` line carries the dates of the nights lost
(`lost=`), which survival per day is read from.

## The year: `python tools/autoplay.py --year 8`

0276's table, before the instrument fixes - every run stopped on Spring 14:

```text
  policy     lost: spring summer autumn winter   repeats: sp su au wi   over  capped
  balanced          12.4    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8
  economy           17.0    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8
  towers             8.4    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8
  walls             10.4    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8
```

After them, every game value as it was - the table this task ends on, since
no value moved (32 runs in 776 s, 8 processes):

```text
  policy     lost: spring summer autumn winter   repeats: sp su au wi   over  capped   money at winter  essence  walked/run
  balanced           0.0    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8           -        -       17431
  economy           17.0    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8           -        -       16223
  towers             0.4    0.2    0.0    0.0         6.2  2.6  0.0  0.0   0/8    8/8           -        -       23702
  walls              9.4    0.0    0.0    0.0         7.0  0.0  0.0  0.0   0/8    8/8           -        -       15330

  spring  no dominant strategy: clean runs balanced 8, towers 5, economy 0, walls 0
  summer  ALARM: 'towers' is the only policy that gets through it clean (2 of 8)
  autumn  not reached: every run stopped before it
  winter  not reached: every run stopped before it
```

Survival per day, of the runs that reached the date (`balanced` 100% on
every spring date; the others below):

```text
economy   spring  100 100 100   0   0   0   0   0   0   0   0   0   0   0
economy   summer    -   -   -   -   -   -   -   -   -   -   -   -   -   -
towers    spring  100 100  62 100 100 100 100 100 100 100 100 100 100 100
towers    summer  100 100 100 100 100 100 100 100 100 100 100 100 100  67
walls     spring  100 100 100 100 100 100 100 100 100  88  62  12   0   0
walls     summer    -   -   -   -   -   -   -   -   -   -   -   -   -   -
```

What it says:
- **`balanced` holds every spring night on every seed and the Giant never
  falls**: seven fights a run, and the cap ends it. Its 0.0 losses is the
  Giant being unbeatable, not spring being easy.
- **`towers`**, with 'oiled works' on its branch, gets the Giant down on
  some seeds and reaches summer, where the Harvester stops it.
- **`walls` breaks on Spring 10-13**: a maze and one gun, its character.
- **`economy` loses every night from Spring 4**: its plan puts the third
  gun after four stations and the kitchen last, so nothing is mended and the
  25% a lost night takes keeps it down. Its character, and its cost.
- **No day sits at 0% across every policy**; summer's alarm is `towers`
  being the only one that reached it.

## The sweep: `python tools/balance.py 4 --with="giant hp=500" --with="giant armour=4" --days=42`

`balanced`, four seeds a configuration, around the Giant's candidate point
(so that the sweep could see past Spring 14 at all), each run stopped at day
42. **Fifteen configurations in 2,348 s** - two at a time on eight
processes, a run 3-7 minutes. Losses and boss fights are a run's average;
"Giant fights lived through" counts the Spring 14 nights it walked away
from. `game_data.gd` came back clean and the lock went with it.

| Configuration | Lost before day 43 | Spring | Summer | Giant fights lived through | Harvester's | Summer's survival, days 1-13 | Wall |
|---|---|---|---|---|---|---|---|
| baseline | 6.5 | 0.0 | 6.5 | 1.5 | 7.0 | 100 100 100 100 100 100 100 100 100 100 100 100 100 | 399 s |
| spring size 2000 | 6.5 | 0.0 | 6.5 | 0.0 | 7.0 | 100 100 100 100 100 100 100 100 100 100 100 100 100 | 351 s |
| spring size 3600 | 6.8 | 0.0 | 6.8 | 1.2 | 7.0 | 100 100 100 100 100 100 100 100 100 100 100 100 100 | 335 s |
| summer size 4000 | 6.5 | 0.0 | 6.5 | 1.5 | 7.0 | 100 100 100 100 100 100 100 100 100 100 100 100 100 | 400 s |
| summer size 6000 | 8.2 | 0.0 | 8.2 | 1.5 | 7.0 | 100 100 100 100 100 100 100 100 75 75 75 50 50 | 348 s |
| autumn size 7000 | 6.5 | 0.0 | 6.5 | 1.5 | 7.0 | 100 100 100 100 100 100 100 100 100 100 100 100 100 | 399 s |
| full moon 120 | **does not validate**: Winter 7 is all sent before the fill line | | | | | | |
| giant hp 700 | 0.0 | 0.0 | - | **7.0**, capped | - | not reached | 172 s |
| giant armour 6 | 0.0 | 0.0 | - | **7.0**, capped | - | not reached | 176 s |
| breaker bite 200 | 6.5 | 0.0 | 6.5 | 1.2 | 7.0 | 100 100 100 100 100 100 100 100 100 100 100 100 100 | 399 s |
| defeat loss 10 | 6.2 | 0.0 | 6.2 | 1.5 | 7.0 | 100 100 100 100 100 100 100 100 100 100 100 100 100 | 393 s |
| house tier 80 | 7.0 | 0.0 | 7.0 | 1.5 | 7.0 | 100 100 100 100 100 100 100 100 100 100 100 100 100 | 397 s |
| night length 280 | **does not validate**: six nights are all sent before the fill line | | | | | | |
| essence 2 | 6.0 | 0.2 | 5.8 | 1.0 | 7.0 | 100 100 100 100 100 100 100 100 100 100 100 100 100 | 363 s |
| night money 30 | 6.8 | 0.0 | 6.8 | 0.0 | 7.0 | 100 100 100 100 100 100 100 100 100 100 100 100 100 | 315 s |

What it says:
- **Spring holds at 100% on every date in every configuration** but one
  (essence 2, one seed on Spring 14), and the Giant falls in one or two
  fights - **at 500 hit points and armour 4 only**. At 700, or at armour 6,
  it is fought seven times and never falls.
- **Summer holds every date to Summer 13, and Summer 14 - the Harvester's
  night - is 0% in every configuration.** Every run stops there.
- **Summer's size is the one other lever that moves anything**: at 6,000 hit
  points on its thirteenth day, Summer 9-13 are lost on a quarter to a half
  of the seeds; 4,000 changes nothing.
- **Dead weight, honestly read**: the autumn size never matters because no
  run reaches autumn; the breaker's bite, the defeat's share, the house
  tier, essence and the night's money move a fraction of a night either
  way, the Harvester's wall hiding the rest.
- **Two levers cannot move at all.** The Full Moon at 120% and the night at
  280 seconds both fail `GameData.validate()`: the nights' records are
  written to 240 seconds and to Winter 7's Full Moon, and the fill line
  (0274) refuses them. Their `# LEVER` ranges said otherwise and now say
  130-200 and 230-240 seconds (values unmoved). The night's length is off
  the sweep's list.

## The bosses, a night at a time

A sweep is a year a configuration; a boss is one night. Each trial played
`balanced` to the boss night on seeds 9000 and 9007, its levers set for
that run only, and followed the boss's hit points to the house, up to
three fights.

**The Giant (Spring 14):**

| Giant | Full Moon | Did it fall | The house |
| --- | --- | --- | --- |
| 900, armour 6 (as it is) | 150% | never; reaches the house with ~650 | holds (80-125) |
| 600, armour 4 | 120% | once in six fights; reaches it with 70-100 | holds |
| 600, armour 3 | 150% | first fight, both seeds | holds (120-165) |
| 700, armour 3 | 150% | first fight, both seeds (3 and 17 left a second before) | holds |
| 500, armour 4 | 150% | first fight, both seeds | holds |
| 600, armour 4, 70 ticks a tile | 150% | first fight, both seeds | holds |

Without the boss prep the house fell to the Giant's company first, at any of
these.

**The Harvester (Summer 14)** - its company is 1.53 times Summer 13 in hit
points (7,662 with the Full Moon, from two sides, 108 rats among them) where
the Giant's is 1.38 times Spring 13, and the house falls to it before the
machine arrives:

| Harvester | Its company | Did it fall | The house |
| --- | --- | --- | --- |
| 1,100, armour 6 (as it is) | as written | never; ~1,000 left | falls 5 of 6 |
| 800 or 700, armour 5 | as written | never; 550-730 left | falls 5 of 6 |
| 1,100 | Full Moon 130% | never | falls 5 of 6 |
| 700, armour 5 | 70% | never; ~550 left | falls 3 of 6 |
| 700, armour 5 | 60% | never; ~540 left | holds 5 of 6 |
| 700, armour 5, a charge every 12 s for 4 tiles, 60 ticks a tile | 60% | never; ~470 left | holds 5 of 6 |

**At the easy end of every one of its ranges it still takes about 230.** By
the Giant's arithmetic it would fall at armour 2-3 and 600-700 hit points:
frailer than a tank to a bolt.

## What moved

| Lever | Old | New | Why |
| --- | --- | --- | --- |
| `FULL_MOON_HORDE_PERCENT`'s range | 120-200 | 130-200 | Value unmoved; under 130 Winter 7 fails the fill line |
| `NIGHT_TICKS`'s range | 180-300 s | 230-240 s | Value unmoved; the nights' records pin it |

Neither hash moved. **Proposed, not applied**: the Giant at 500 hit points
and armour 4 - the sweep's and the trials' answer for spring - waits on the
decision below, since it breaks 0058's two relations.

## What is still off

- **The bosses against an average arsenal.** Nothing the average robot
  fields beats armour 5-7 in time. The owner's choice, any of:
  1. **the bosses' armour and hit points**: the Giant at 500 and armour 4
     (and 0058's two relations rewritten: a boss outlasts every enemy but
     need not out-armour the tank's cousins; cheap towers can kill a spring
     boss), the Harvester near armour 3 and 700, the Scarecrow King and the
     Winter Lord to be measured;
  2. **a robot that plays each season's weapons**: a press for oil from
     spring, summer's flamethrower (a cone that lands its minimum every
     tick - the armour answer by design), autumn's mortar and catapult, and
     'oiled works' for level three, with the oil and gunpowder chains they
     need. An instrument task of its own - and what 0234's "days of focused
     saving for a heavy tower" describes;
  3. **the boss nights' companies**: Summer 14's is 1.53 times its season's
     last night where Spring 14's is 1.38. At 60% the house holds; a
     balance call that waits on the other two.
- **Autumn opens at 5,200 hit points**, above what the robot holds at the
  end of summer (it starts losing at 6,000). No run has reached it, so no
  number is offered.
- **`economy` dies from Spring 4 on every seed**: its plan, not the game.
- **The game lets a player wall in their own porch**: `Farm.buildable`
  refuses only the porch cell. The robot did it by accident; a person can
  too. Raised as its own task.

---

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

## 0234 - the arsenal by season, and its money (2026-10-11)

**The rules** (plan sections 1, 5 and 7):
- the calendar opens the arsenal: spring the gun tower, the crossbow, the
  mine and the three barriers; summer the flamethrower, the decoy, the hive,
  the bait and the sandbags; autumn the mortar, the catapult and the garlic;
  winter the searchlight and the electric fence;
- the day's money pays part of every defence, the materials the rest;
- at the start of each season a good day buys about one new defence, and
  beating the boss takes five to seven days of focused saving.

**The measure is 0194's**: a defence's price is its money share and its
materials at what the stall charges for them (`Building.price_of`), what it
costs somebody who has only money. It is set against the season's band for
a well-worked day (`GameData.DAY_TARGETS`); "days" below is the price over
the band's middle.

**The money shares** (`MONEY` in each `cost`, levers) grow with the season a
defence opens in, as the day's money does:
- **spring's are small**, so a new game's $25 still pays the first gun
  tower's $15 and a fence's $2 on night one, off a day at the rock face (the
  robot's night-one tower is 0067's assert);
- **none reaches $100**, so a price, money first, fits its 40-pixel slot.

| Season | Defence | Materials at the stall | Money | Price | Days | Money's part |
|---|---|---|---|---|---|---|
| spring ($180-400) | barricade | $12 | $1 | $13 | 0.04 | 8% |
| | fence | $15 | $2 | $17 | 0.06 | 12% |
| | wall | $80 | $4 | $84 | 0.3 | 5% |
| | **gun tower** | $246 | $15 | $261 | **0.9** | 6% |
| | auto crossbow | $405 | $30 | $435 | 1.5 | 7% |
| | mine | $530 | $8 | $538 | 1.9 | 1% |
| summer ($205-460) | zombie bait | $36 | $2 | $38 | 0.1 | 5% |
| | sandbag wall | $40 | $3 | $43 | 0.1 | 7% |
| | decoy | $36 | $8 | $44 | 0.1 | 18% |
| | **beehive** | $145 | $60 | $205 | **0.6** | 29% |
| | flamethrower | $1160 | $90 | $1250 | 3.8 | 7% |
| autumn ($235-530) | garlic braid | $58 | $8 | $66 | 0.2 | 12% |
| | **catapult** | $350 | $40 | $390 | **1.0** | 10% |
| | mortar | $1695 | $95 | $1790 | 4.7 | 5% |
| winter ($270-610) | electric fence | $41 | $6 | $47 | 0.1 | 13% |
| | **searchlight** | $320 | $80 | $400 | **0.9** | 20% |

The bait's fish are counted at the cheapest kind's price.

**What the numbers say:**
- **Every season opens a defence a good day buys** (in bold), its price
  inside the season's band. `_task_0234_arsenal` asserts it, so a lever moved
  far enough to break the rule fails the suite. Summer's hive sits at the
  band's low end, and with a decoy and a line of sandbags it is a day.
- **The heavy towers are the season's saving:** the crossbow a day and a
  half, the mine two, the flamethrower nearly four and the mortar nearly
  five. The plan's five to seven days for the boss buys one of them and a
  level or two.
- **The barriers and the throwaways cost a fraction of a day:** the
  barricade, the fence, the sandbags, the bait, the decoy, the garlic and
  the wire a fifth or less, the wall under a third.
- **Money's part is what the day's purse buys outright:**
  - a twentieth of a heavy tower, whose materials are the work;
  - a fifth to a third of the new seasons' openers - the hive, the
    searchlight - which are bought more than gathered.
- **A kit is the materials only:** placing one still charges its money, so
  the night's purse decides how many kits go down as well as what is built.
- **Mending takes its share of the money too:** 50% (`REPAIR_PERCENT`) of
  it for a whole mend, as a coop's always has.
