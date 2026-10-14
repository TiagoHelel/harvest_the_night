# Everything left before 1.0

Kept by Claude. Last updated **2026-10-14**, after commit `0fb4d2e6`; section 3a after Codex's messages of 21:49 and 21:53.
Sources:
- `python tools/task.py stats`, `next` and `list todo`;
- `implementation/BACKLOG.md`;
- `implementation/backlog/INDEX.md`.

**The game backlog: 296 tasks, 245 done, 50 todo, 1 blocked (83%).**
Nothing can be started today. One task waits on the owner, 41 wait on art,
and the other 9 wait on those.

## 1. Task 0277, balancing the year: done 2026-10-14

The owner's twelfth call took the target as it stands:
- fourteen runs of sixteen win the year;
- every boss falls wherever the house stands;
- `towers` loses 3.4 nights before Winter 1, and `balanced` 6.0.

What is left goes to 0278 and 0280. Every call and trial is in
[`BALANCE.md`](../BALANCE.md).

## 2. The rest of the game backlog, in order

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

### 3a. The 21 new packs: 15 approved for integration (2026-10-14)

Codex recorded the owner's approval at 16:56. The details are in:
- `implementation/backlog/deliveries/A028-dog/CLAUDE-BATCH-DETAILS.md`,
  `CLAUDE-BATCH-PROMPT.txt` and `batch-approval.json`;
- each pack's own `APPROVAL.json` and `CLAUDE-Axxx-PROMPT.txt`.

**Approved and complete; Claude integrates each through its game task**:

| Pack | What | Game task |
| --- | --- | --- |
| A037 | The scarecrow decoy and zombie bait (**integrated** by 0236, 2026-10-14) | 0236 |
| A038 | The beehive | 0237 |
| A039 | The pumpkin catapult | 0238 |
| A041 | The searchlight | 0240 |
| A044 | Day tarps over the defences | 0243 |
| A046 | The spitter | 0260 |
| A047 | The rat swarm | 0261 |
| A048 | The crow | 0262 |
| A049 | The digger | 0263 |
| A050 | The frost zombie | 0264 |
| A051 | The wraith | 0265 |
| A052 | The Harvester | 0266 |
| A053 | The Scarecrow King | 0267 |
| A055 | Fog, rain and the Blood Moon icons | 0269 |
| A056 | The collection book, trophies and badges | 0288 |

**Approved in part, still blocked for their missing outputs**:
- A028, the dog (2 of 20);
- A040, the garlic braid (1 of 3);
- A042, the electric fence (3 of 42);
- A054, the Winter Lord (14 of 22).

**No images yet**: A043, hardwood walls and sandbags (0 of 78), and A045,
the power and weapon icons (0 of 22).

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
