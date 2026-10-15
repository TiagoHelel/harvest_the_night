# Everything left before 1.0

Kept by Claude. Last updated **2026-10-15**, with task 0239's commit; section 3a after Codex's two messages of 21:11 (all 21 packs approved).
Sources:
- `python tools/task.py stats`, `next` and `list todo`;
- `implementation/BACKLOG.md`;
- `implementation/backlog/INDEX.md`.

**The game backlog: 296 tasks, 250 done, 46 todo, 0 blocked (84%).**
17 art integrations are ready, one a run as the owner asks (`task.py next`
says 0240). 20 more wait on art that is blocked or deferred (3b, 3c), and
the rest of the backlog on those (section 2).

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
| A041 | The searchlight | 0240 |
| A042 | The electric fence | 0241 |
| A043 | Hardwood walls and sandbags | 0242 |
| A044 | Day tarps over the defences | 0243 |
| A045 | The power and weapon icons | 0244 |
| A028 | The dog | 0245 |
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

Notes for the six released at 21:11:
- A042 and A043 compose their pieces from `joins.parts`, in N, W, E, S,
  post order, through import_art's compose entries.
- Some measured differences are accepted by the owner and stay recorded as
  false checks, not to be asked again:
  - A028: the wag, bark and sleep motion;
  - A040: the braid's size;
  - A042: the post span and the sparks;
  - A054: the death's height.

### 3b. The 13 packs once blocked: redone, waiting on the owner's review

The owner reopened them and authorised composing sources from ImageGen
crops. Codex redid all 13 (182 native PNGs, every measured check passing)
and set them to `review` on 2026-10-14. **Nothing is integrated until the
owner approves the new hashes.**
- The review page is
  `implementation/backlog/deliveries/A003-guardian/retry-final-review.html`.
- The details are `CLAUDE-RETRY-REVIEW.md` and `retry-final-inventory.json`
  in the same folder.

Promoting them will mean composing parts and components, not cropping one
source:
- A034 mixes draw scales.
- A035's house tiers are 128x128 at draw 1.

The table below is why each stopped the first time.

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
