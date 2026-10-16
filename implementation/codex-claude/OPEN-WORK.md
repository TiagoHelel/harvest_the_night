# Everything left before 1.0

Kept by Claude. Last updated **2026-10-16**, with task 0269's commit; section 3a after Codex's two messages of 21:11 (all 21 packs approved).
Sources:
- `python tools/task.py stats`, `next` and `list todo`;
- `implementation/BACKLOG.md`;
- `implementation/backlog/INDEX.md`.

**The game backlog: 296 tasks, 278 done, 18 todo, 0 blocked (94%).**
Every art integration in 3a and 3b is ready, one a run (`task.py next`
says 0288). Only the farmer packs the owner deferred (3c) still wait on
art, and the rest of the backlog waits on those (section 2).

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

## 3. The art: 37 game tasks left, one pack each

Each game task integrates one Codex pack. The game already plays every
one of these with a placeholder (task 0120's road). The pack's state is
`implementation/backlog/INDEX.md`'s.

### 3a. The 21 new packs: all approved and complete (2026-10-14)

The owner approved 15 at 16:56 and the other six's additions at 21:11
("tudo aprovado, falta mais?"): 422 PNGs, none missing. The details are in:
- `implementation/backlog/deliveries/A028-dog/CLAUDE-CONTINUATION-APPROVED.md`
  (it supersedes the older batch notes for the six), `CLAUDE-BATCH-DETAILS.md`
  and `batch-approval.json`;
- each pack's own `APPROVAL.json`, `contract.json` and `CLAUDE-Axxx-PROMPT.txt`.

**Claude integrates each through its game task, one a run**:

| Pack | What | Game task |
| --- | --- | --- |
| A037 | The scarecrow decoy and zombie bait (**integrated** by 0236, 2026-10-14) | 0236 |
| A038 | The beehive (**integrated** by 0237, 2026-10-14) | 0237 |
| A039 | The pumpkin catapult (**integrated** by 0238, 2026-10-14) | 0238 |
| A040 | The garlic braid (**integrated** by 0239, 2026-10-15) | 0239 |
| A041 | The searchlight (**integrated** by 0240, 2026-10-15) | 0240 |
| A042 | The electric fence (**integrated** by 0241, 2026-10-15) | 0241 |
| A043 | Hardwood walls and sandbags (**integrated** by 0242, 2026-10-15) | 0242 |
| A044 | Day tarps over the defences (**integrated** by 0243, 2026-10-15) | 0243 |
| A045 | The power and weapon icons (**integrated** by 0244, 2026-10-15) | 0244 |
| A028 | The dog (**integrated** by 0245, 2026-10-15) | 0245 |
| A046 | The spitter (**integrated** by 0260, 2026-10-15) | 0260 |
| A047 | The rat swarm (**integrated** by 0261, 2026-10-15) | 0261 |
| A048 | The crow (**integrated** by 0262, 2026-10-15) | 0262 |
| A049 | The digger (**integrated** by 0263, 2026-10-15) | 0263 |
| A050 | The frost zombie (**integrated** by 0264, 2026-10-15) | 0264 |
| A051 | The wraith (**integrated** by 0265, 2026-10-15) | 0265 |
| A052 | The Harvester (**integrated** by 0266, 2026-10-15) | 0266 |
| A053 | The Scarecrow King (**integrated** by 0267, 2026-10-16) | 0267 |
| A054 | The Winter Lord (**integrated** by 0268, 2026-10-16) | 0268 |
| A055 | Fog, rain and the Blood Moon icons (**integrated** by 0269, 2026-10-16) | 0269 |
| A056 | The collection book, trophies and badges | 0288 |

Notes for the six released at 21:11:
- A042 and A043 compose their pieces from `joins.parts`, in N, W, E, S,
  post order, through import_art's compose entries.
- Some measured differences are accepted by the owner and stay recorded as
  false checks, not to be asked again:
  - A028: the wag, bark and sleep motion;
  - A040: the braid's size;
  - A042: the post span and the sparks;
  - A054: the death's height.

### 3b. The 13 packs once blocked: approved 2026-10-15, ready

The owner reopened them and authorised composing sources from ImageGen
crops. Codex redid all 13 (182 native PNGs, every measured check passing),
and the owner approved them all on 2026-10-15 ("tudo aprovado, avisa o
claude, que mais temos pra fazer?"). The handoff is
`implementation/backlog/deliveries/A003-guardian/CLAUDE-RETRY-APPROVED.md`,
and each pack has its own `APPROVAL.json` and `CLAUDE-Axxx-PROMPT.txt`.

Promoting them means composing parts and components, not cropping one
source:
- A034 mixes draw scales.
- A035's house tiers are 128x128 at draw 1.

**Claude integrates each through its game task, one a run**:

| Pack | What | Game task |
| --- | --- | --- |
| A003 | The porch guardian (**integrated** by 0145, 2026-10-15) | 0145 |
| A004 | The guardian's cursor (**integrated** by 0146, 2026-10-15) | 0146 |
| A017 | Autumn crops (**integrated** by 0200, 2026-10-15) | 0200 |
| A018 | Sprinklers (**integrated** by 0201, 2026-10-15) | 0201 |
| A023 | Fishing gear and the minigame (**integrated** by 0206, 2026-10-15) | 0206 |
| A026 | Sheep and pigs (**integrated** by 0209, 2026-10-15) | 0209 |
| A027 | The cow and the chicken redrawn (**integrated** by 0210, 2026-10-15) | 0210 |
| A030 | The coop and the barn (**integrated** by 0212, 2026-10-15) | 0212 |
| A033 | The shipping bin (**integrated** by 0215, 2026-10-15) | 0215 |
| A034 | The peddler at the stall (**integrated** by 0216, 2026-10-15) | 0216 |
| A035 | The house in three tiers (**integrated** by 0217, 2026-10-15) | 0217 |
| A036 | Bones, moon stones and essence (**integrated** by 0235, 2026-10-15) | 0235 |
| A057 | The morning report header (optional) | 0289 |

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
