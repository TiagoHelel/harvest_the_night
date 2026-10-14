# Everything left before 1.0

Kept by Claude. Last updated **2026-10-14**, after commit `0fb4d2e6`; section 3a after Codex's messages of 21:49 and 21:53.
Sources:
- `python tools/task.py stats`, `next` and `list todo`;
- `implementation/BACKLOG.md`;
- `implementation/backlog/INDEX.md`.

**The game backlog: 296 tasks, 245 done, 50 todo, 1 blocked (83%).**
Nothing can be started today. One task waits on the owner, 41 wait on art,
and the other 9 wait on those.

## 1. Waiting on the owner: task 0277, balancing the year

[`prompts/0277-balance-year.md`](../prompts/0277-balance-year.md). The whole
story, the tables and the trials are in
[`BALANCE.md`](../BALANCE.md)'s sections "The owner's ... call, played".

What the owner has decided so far, in order:

| Call | What was done |
| --- | --- |
| 1 | The year robot fields each season's weapons |
| 2 | More iron at spring's stall (`SPRING_IRON` 16) and a weaker Giant: 900/6 to 400/4 |
| 3 | The Harvester the same way: 1,100/6 to 350/4 |
| 4 | The robot saves for autumn's mortar |
| 5 | A defence brought to 0 is a **ruin**, mended back at half its price |
| 6 | The Scarecrow King sized to autumn's line: 1,200/5 to 600/4 |
| 7 | Autumn's last week: the King's company at three quarters |
| 8 | Autumn's curve at 6,400, its nights and winter's kept in rhythm |

Where it stands:
- Eleven runs of sixteen reach winter.
- `balanced` loses 7.5 nights before Winter 1: 2.6 in spring and 4.9 in
  autumn.
- Every boss but the last falls: the Giant, the Harvester and the King.
- Winter is held, most nights by most lines, but the Winter Lord
  (1,800/7) never falls. He is left at 908-1,800 every fight.

**The owner's next call is one of:**
1. the Winter Lord sized to winter's line, as the other three were;
2. what is left before Winter 1: autumn's Full Moon on some seeds, and
   spring's 2.6.

The target is the phase's: the average player loses two to four nights
before Winter 1, and every boss falls.

## 2. Waiting on 0277, and on each other

| Task | What | Needs |
| --- | --- | --- |
| 0278 | The economy across a year | 0277 |
| 0279 | Year 2 | 0277 |
| 0280 | Checkpoint: do fifty-six nights tire? | 0277, 0278, 0279 |
| 0291 | Saves into 1.0 | 0279 |
| 0294 | Every new word in Portuguese | 0291 |
| 0295 | A playtest build of the year | 0280, 0291, 0294 |
| 0290 | The 1.0 visual gate | every art task below |
| 0296 | The store page and trailer for 1.0 | 0290, 0294 |
| 0297 | Releasing 1.0 | 0290, 0291, 0294, 0295, 0296 |

## 3. Waiting on art: 41 game tasks, one pack each

Each game task integrates one Codex pack. The game already plays every
one of these with a placeholder (task 0120's road). The pack's state is
`implementation/backlog/INDEX.md`'s.

### 3a. The 21 new packs, which Codex is generating (state `todo`)

**The owner authorised all 21 on 2026-10-13** ("Gerar os 21 novos pacotes e
montar o HTML de revisão ao final"), with one review page at the end.
Codex is on them from A028.

No game task holds any of them back: every "Starts after" is a dash. A
pack can still depend on another pack's art, though:
- **A028**, the dog, matches its style to the approved animal deliveries
  A026 and A027, which are quality-blocked. The owner ruled that the
  game's current cow and chicken sprites stand in as its references
  (`implementation/backlog/deliveries/A028-dog/authorization.json`).
- **Any other pack's "Match these"** section can name a reference the
  same way. That is Codex's to raise with the owner, not something the
  game settles.

| Pack | What | Game task |
| --- | --- | --- |
| A028 | The dog | 0245 |
| A037 | The scarecrow decoy and zombie bait | 0236 |
| A038 | The beehive | 0237 |
| A039 | The pumpkin catapult | 0238 |
| A040 | The garlic braid | 0239 |
| A041 | The searchlight | 0240 |
| A042 | The electric fence | 0241 |
| A043 | Hardwood walls and sandbags | 0242 |
| A044 | Day tarps over the defences | 0243 |
| A045 | Power icons and the new weapons' icons | 0244 |
| A046 | The spitter | 0260 |
| A047 | The rat swarm | 0261 |
| A048 | The crow | 0262 |
| A049 | The digger | 0263 |
| A050 | The frost zombie | 0264 |
| A051 | The wraith | 0265 |
| A052 | The Harvester | 0266 |
| A053 | The Scarecrow King | 0267 |
| A054 | The Winter Lord | 0268 |
| A055 | Fog, rain and the Blood Moon icons | 0269 |
| A056 | The collection book, trophies and badges | 0288 |

### 3b. Packs blocked after three attempts (13): the owner's call

The pack's contract was not met after three tries. Each needs the owner
to choose before anyone tries again: loosen the check, take a new
approach, or accept what exists.

| Pack | What | Game task | Why it stopped |
| --- | --- | --- | --- |
| A003 | The porch guardian | 0145 | Eyes and crossbar unreadable at native size |
| A004 | The guardian's cursor | 0146 | Bracket and pulse geometry not exact |
| A017 | Autumn crops | 0200 | Grape r3 too small; plot pixels over the cap |
| A018 | Sprinklers | 0201 | Strips change base pixels; nozzle rise not 2px |
| A023 | Fishing gear and the minigame | 0206 | Zone 8x5 not 8x6; track geometry |
| A026 | Sheep and pigs | 0209 | Feet move on idle; grounding |
| A027 | The cow and the chicken redrawn | 0210 | Feet and grounding; a cow frame came back a hen |
| A030 | The coop and the barn | 0212 | Window glints lost at native size |
| A033 | The shipping bin | 0215 | Base changes; closed width 17 not 18-20 |
| A034 | The peddler at the stall | 0216 | Extra animations; pixels outside the opening |
| A035 | The house in three tiers | 0217 | Tier 1 ends on row 117 not 119 |
| A036 | Bones, moon stones and essence | 0235 | Fertilised soil too sparse; wet tile not opaque |
| A057 | The morning report header (optional) | 0289 | Wrong sky ramp; noisy clusters |

### 3c. Farmer sprites the owner deferred (7)

"Until later, one at a time": nothing is generated or integrated until the
owner asks for a specific one.

| Pack | What | Game task |
| --- | --- | --- |
| A001 | Going to bed, sleeping, waking, passing out | 0143 |
| A002 | The farmer's reactions and Zzz | 0144 |
| A007 | Tilling, planting, watering, harvesting | 0123 |
| A008 | Chopping, mining, collecting, carrying | 0124 |
| A009 | Crafting, trading, repairing | 0125 |
| A024 | Fishing | 0207 |
| A025 | Tending animals | 0208 |

A006, the farmer's run, was cancelled by the owner: the walk is reused.
See its delivery's `RUN-REMOVAL.txt`.

## 4. Known risks, for whoever runs next

- **`tools/verify.py` takes about 1,100-1,200 s**, over its budget. Since
  0277 moved three of `input_v1`'s cases to `input_v2`, `input_v1` runs in
  about 94 s and `input_v2` in about 49 s, of the 120 s each may take. A
  killed input suite leaves a crash breadcrumb that fails the next. The
  budgets are the owner's call.
- **New input cases go in `src/tools/input_v2.gd`**, from task 0258 on.
