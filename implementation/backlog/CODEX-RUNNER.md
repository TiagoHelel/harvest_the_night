# Codex runner: one art pack per run

The owner starts a run with: **"Read and execute implementation/backlog/CODEX-RUNNER.md"**.
Then:

1. Take exactly **one** pack from the queue.
2. Generate it with ImageGen.
3. Review it with the owner.
4. Hand it to Claude once it is approved.
5. Stop.

Before you start, read `implementation/backlog/ART-CONTRACT.md` in full. It defines
every number, folder and file this runner mentions. Run every command from the
repository root.

## Ground rules

| Rule | Detail |
|---|---|
| One pack per run | When the pack is approved, blocked, or waiting for the owner's answer, stop. Never start a second pack in the same run. |
| Language | Talk to the owner in **Brazilian Portuguese**. Everything written to files stays in **English**: prompts, JSON, `build.py`, `index.html`, the Claude handoff. The owner's own words are quoted verbatim and never translated. |
| Where you write | Only inside `implementation/backlog/deliveries/<Axxx-slug>/`. The pack's Status line changes only through `assets.py set`, which also rewrites `implementation/backlog/INDEX.md`. |
| Never edit | Game code (`src/`, `tools/`, `project.godot`, scenes), `sprites/`, `assets/art_source/`, the game backlog (`implementation/prompts/`, `implementation/BACKLOG.md`, `tools/backlog/`), any pack file's text, `ART-CONTRACT.md`, this file, `assets.py` |
| Statuses | Change only **this** pack's status, and only as the steps below say. Never touch another pack. Never run `assets.py unblock` or any `tools/task.py` command that changes state: those belong to Claude's loop. |
| Where art comes from | Only from the **ImageGen** tool. Never draw art with code, never use ASCII maps (`tools/gen_sprites.py`), never trace or repaint existing sprites into new ones. `build.py` may only do the conversions the contract allows: crop, nearest scale, palette mapping, alpha threshold, exact flip, 2x, module composition. |
| Approval | Only the owner's explicit words approve a pack. Never infer approval. |
| Git | No commits unless the owner asks (step 9). Never push. Never `git add -A` or `git add .`. The working tree has unrelated changes from other work: leave them alone and never reset or check them out. |

## Statuses

The status is the `- **Status:**` line in `implementation/backlog/packs/Axxx-<slug>.md`.
Change it only with `python implementation/backlog/assets.py set Axxx <status> ["note"]`.

| Status | Meaning | Who sets it |
|---|---|---|
| `todo` | Not started | Initial. The owner sets it again to reopen a blocked pack. |
| `generating` | Codex is making and exporting candidates | Codex, step 2 |
| `review` | The review page is ready and waiting for the owner | Codex, step 7 |
| `approved` | The owner approved. `APPROVAL.json` and `CLAUDE-Axxx-PROMPT.txt` exist. | Codex, step 8, and only with the owner's words |
| `integrated` | Claude's integration task put the art in the game | **Claude only** |
| `blocked` | Cannot continue. A note says why. | Codex (or Claude) with a one-line note. The owner reopens it with `assets.py set Axxx todo`. |

`assets.py next` resumes a pack left in `generating` or `review` before it offers a
new `todo`. An unfinished pack is always picked up again first.

## Step 1 - Pick the pack

```
python implementation/backlog/assets.py next
```

It prints `Axxx Title  [reason]` and the pack file path.

- **`nothing left to generate`:** tell the owner and stop.
- **`resume (was left generating)` or `resume (was left review)`:** go to step 3 and
  continue the existing delivery folder. Do not start over.
- **`next in order`:** continue with step 1b.
- **Skipped packs:** `next` skips packs whose `Spec after game task: NNNN` is not
  done yet, because that game task still has to settle the pack's final canvas,
  footprint, levels or states. When it reports a skip, tell the owner which packs
  are waiting for which game task (e.g. "A030 espera a tarefa 0183 definir as
  medidas").
- **Safety check** before starting a pack:
  1. Open the pack file. If it has a `Spec after game task: NNNN` line, run
     `python tools/task.py list done` and confirm that NNNN is listed.
  2. If it is not listed, do not start the pack. Tell the owner and stop.

## Step 1b - Make sure ImageGen exists

Skip this step only when you are resuming a pack in `review` and no new image is
needed.

1. Confirm that the built-in image generation tool is in your tool list. In earlier
   work it wrote its files under `~/.codex/generated_images/`.
2. Never simulate it, never describe images instead of generating them, and never
   substitute code-drawn or ASCII art.
3. If image generation is unavailable:

   ```
   python implementation/backlog/assets.py set Axxx blocked "ImageGen unavailable in this Codex session: <what you observed>"
   ```

   Then tell the owner (in Portuguese) that the pack is blocked and why, and that
   after enabling image generation they reopen it with
   `python implementation/backlog/assets.py set Axxx todo`. Stop.

## Step 2 - Claim it

```
python implementation/backlog/assets.py set Axxx generating
```

Skip this when the pack is already `generating`. When resuming a `review` pack,
leave it in `review` unless you are about to generate new candidates.

## Step 3 - Read before you generate

1. **The pack file**, all of it:
   - the Deliverables table;
   - the palette mode;
   - the reference art it names;
   - `For game task`;
   - `Spec after game task`.
2. **`ART-CONTRACT.md`**:
   - section 1;
   - the family's rows in section 2;
   - sections 3-6;
   - section 9.
3. **The reference art.** Open every PNG the pack names and the family's rows in
   section 7 of the contract. Look at each one at actual size and zoomed in. Also
   open `docs/reference-sheet.png` and the approved farmer walk frame for scale.
4. **`implementation/sprites/generation/PROMPTS.md`**: BASE, STRIP, the family's
   section, and CORRECTION.
5. **When resuming:** read the delivery folder first (`contract.json`,
   `review-log.txt`, `raw/`, `rejected/`). Continue from there. Never regenerate an
   accepted asset unless the owner asked you to.

If a number the contract needs is missing, or the pack contradicts the contract,
ask the owner before you generate. If you cannot get an answer:

```
python implementation/backlog/assets.py set Axxx blocked "spec unclear: <what is missing>"
```

Then stop. Never guess.

## Step 4 - Plan the deliverables

1. Create `implementation/backlog/deliveries/<Axxx-slug>/`. The slug is the pack
   file's name without `.md`.
2. List every output file in a first draft of `contract.json`. For each one give:
   - `anim` and `dir`;
   - frames and ordered poses;
   - canvas and pivot, draw scale, timing and loop;
   - mirror;
   - runtime name and metadata points.
3. The total must equal the pack's Deliverables table.
4. Decide the palette mode (contract section 3).

## Step 5 - Generate

1. **Generate one identity master** for a new character, family or material.
   Check it before you make anything else.
2. **Make strips:** one animation, in one direction, per call, with at most 8
   frames. Assemble each prompt as BASE + family section + STRIP, with the exact
   native canvas, pivot and ordered poses. Attach the reference images and state
   each one's role.
3. **Set `transparent_background`** to `true` for isolated sprites and `false` for
   opaque terrain tiles.
4. **Copy every return byte-for-byte** from where the tool saved it into
   `raw/<asset>-r<N>.png`. Write beside it:
   - `raw/<asset>-r<N>.prompt.txt`: the exact text;
   - `raw/<asset>-r<N>.call.json`: the exact call (contract 9.1).
5. **Inspect the raw image:**
   - real alpha, not a painted checkerboard;
   - every frame present, with nothing clipped;
   - the same identity, scale, camera and light as the references;
   - feet on one baseline.
6. **Revise** with the CORRECTION prompt, one concrete fix per revision. The limit
   is **3 revisions per asset** (`r1`-`r3`). After that, ask the owner whether to
   keep going, change the brief, or stop.
7. **Move every rejected return** to `rejected/` with a one-line
   `<name>.reason.txt`.

## Step 6 - Export and build the review page

1. Write `build.py` as contract section 9.4 says. It produces:
   - `native/` (and `runtime/` for 2x farmer-style packs);
   - `preview/`, `contract.json`, `checks.json` and `index.html`.
2. Run it twice, then run it with `--check`:

   ```
   python implementation/backlog/deliveries/<Axxx-slug>/build.py
   python implementation/backlog/deliveries/<Axxx-slug>/build.py
   python implementation/backlog/deliveries/<Axxx-slug>/build.py --check
   ```

   The second run must leave every file byte-identical.
3. **Look at the result yourself:** open the preview PNGs at 4x and the night
   previews, and compare them with the farmer. Fix problems before the owner sees
   them.
4. Go through the checklist in contract section 10. `checks.json` must be all
   `true`, or each `false` must be explained in `review-log.txt`.

## Step 7 - Review with the owner

```
python implementation/backlog/assets.py set Axxx review
```

Tell the owner, in Portuguese:

- the absolute path of `index.html`;
- what is in it;
- what to judge: size next to the farmer, readability at 1x, the night preview,
  motion;
- the known issues;
- a direct question.

Example:

> O pacote A030 (galinheiro e celeiro) está pronto para revisão:
> `C:\Users\Helel\Documents\repos\harvest_the_night\implementation\backlog\deliveries\A030-coop-barn\index.html`.
> Compare o tamanho com o fazendeiro de 32px e veja a prévia noturna.
> Aprova para integração ou quer mudanças?

During the review:

- **Log every round** in `review-log.txt`: the date, the owner's words verbatim,
  and what you changed.
- **Change requests:** make a targeted revision (steps 5-6), rebuild, and show the
  page again. The pack stays in `review`.
- **A whole direction rejected:** move those candidates to `rejected/` with the
  reason and generate again.
- **The owner wants something the contract forbids** (another scale, a baked
  shadow): say that it is a contract change and ask them to confirm. If they
  confirm, record it under `deviations` in `contract.json` with their words.
- **The owner leaves or the session ends:** leave the pack in `review` and stop. The
  next run resumes it.

## Step 8 - Approval and handoff to Claude

Only continue if the owner explicitly approves, for example "aprovado" or "pode
mandar pro Claude".

- If the answer is ambiguous ("ficou bonito"), ask: "Posso marcar como aprovado
  para integração?"
- A partial approval keeps the pack in `review` until every deliverable is approved.

Then:

1. Write `APPROVAL.json` (contract 9.7) with the owner's words verbatim.
2. Rerun `build.py` and `build.py --check`. `contract.json` now says
   `"status": "approved for integration"`.
3. Write `CLAUDE-Axxx-PROMPT.txt` (contract 9.8).
4. Set the status:

   ```
   python implementation/backlog/assets.py set Axxx approved
   ```

5. Run `python implementation/backlog/assets.py check`. Report any problem it prints
   to the owner. Do not fix files outside the delivery folder.
6. Tell the owner, in Portuguese:
   - the pack is approved;
   - Claude's loop will integrate it on its own through the game task named in
     `For game task`;
   - which pack `assets.py next` would offer next run.

## Step 9 - Commit (only if the owner asks)

1. Check what you are about to commit:

   ```
   git status --short
   git diff implementation/backlog/packs/Axxx-<slug>.md
   ```

   The pack file's diff must be the Status line only.
2. Stage and commit only those paths:

   ```
   git add implementation/backlog/deliveries/<Axxx-slug> implementation/backlog/packs/Axxx-<slug>.md implementation/backlog/INDEX.md
   git commit -m "Deliver art pack Axxx: <title>"
   ```

   `INDEX.md` is the index that `assets.py` regenerated along with the Status line.
3. Never push.

## How Claude picks it up

- A game task that integrates art has an `Art packs: Axxx` line.
  `python tools/task.py next` **skips art tasks whose packs are not approved**, so
  Claude's loop never spends a turn on missing art.
- When a pack becomes `approved`, its integration task becomes eligible. The loop
  takes it in id order automatically, and nobody has to tell Claude.
- The integration task:
  1. reads `CLAUDE-Axxx-PROMPT.txt` and `contract.json`;
  2. checks every sha256;
  3. promotes the files through the raster pipeline;
  4. runs `python tools/verify.py`;
  5. looks at day and night captures;
  6. sets the pack to `integrated`.
- Game tasks that blocked themselves with "waiting for asset Axxx" are reopened by
  Claude's own `assets.py unblock`. Codex never runs it.
- If Claude finds a problem in an approved pack, it blocks its task with a note. The
  owner decides. Codex reopens the pack (`review` or `generating`) only when the
  owner asks. A pack that is already `integrated` needs a new pack to change.

## When something goes wrong

| Situation | What to do |
|---|---|
| ImageGen missing or failing every call | Step 1b: `blocked` with the exact observation, then stop |
| The pack's numbers are missing or contradict the contract | Ask the owner. Without an answer: `blocked "spec unclear: ..."`, then stop. |
| Three revisions of one asset failed | Ask the owner: continue, change the brief, or stop |
| The pack needs art from another pack that is not approved (e.g. an identity master) | Ask the owner. Without an answer: `blocked "waiting for Axxx approval"` |
| You changed a file outside the delivery folder by mistake | Tell the owner exactly which file. Never "fix" it with `git checkout`, `git reset` or `git stash`: other work may be in the same file. |
| The owner wants to stop mid-pack | Leave the status as it is (`generating` or `review`). The next run resumes it. |

## End of run

Finish with a short report to the owner in Portuguese:

- the pack id and its final status;
- the delivery folder path;
- how many frames were made and how many candidates were rejected;
- any open questions;
- what the next run will pick.
