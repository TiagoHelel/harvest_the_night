# 00 - RUNNER LOOP

**Read this file and execute it.** It does exactly one backlog task of
**HARVEST THE NIGHT** (a Godot 4.7 game, this repository), verifies it, ticks
its checkbox and writes the journal. Then it stops.

Point a loop at it and it will chew through the backlog:

```
/loop Read and execute implementation/prompts/00-RUNNER-LOOP.md
```

One task per invocation. Do the whole task or mark it blocked. Never leave a
task half done.

---

## Step 1 - pick the task

```bash
python tools/task.py next
```

That prints the task and its file path. It resumes a task left `doing` by an
interrupted run, otherwise it takes the lowest-numbered `todo` whose
dependencies are all `done`.

If it prints `nothing actionable`, print the blocked list it gives you, say the
backlog is finished or stuck, and **stop**. Change nothing.

Otherwise claim it:

```bash
python tools/task.py doing 0042
```

That also rewrites `implementation/BACKLOG.md`, so the index always matches.

## Step 2 - read before you type

- The task file that `next` printed. All of it, including "Done when".
- The files it lists under **Likely files**.
- The prompt files of its dependencies, if the design depends on them.
- `README.md` for how to run, test and export, and for the decisions already
  made.
- `design.md` is the original design document and the source of truth for
  intent. `docs/reference-sheet.png` is the source of truth for the look -
  **open it and actually look at it** on any task that draws something.

## Step 3 - implement it

House rules, non-negotiable:

- `src/core/` holds the game rules and stays **node-free and deterministic**.
  It advances only through `Sim.tick(state)` at a fixed rate. No nodes, no
  `randf()` outside the run's seeded RNG, no `Time.*`, no iterating an unordered
  Dictionary without sorting the keys first. The headless tools, the autoplayer,
  the skip-the-night button and the desktop-equals-browser guarantee all depend
  on this.
- `src/ui/` draws and reads input. It owns no rules. Anything it does - shake,
  particles, lighting, damage numbers - must be invisible to the determinism
  hash.
- Every number a designer might want to turn goes in `src/core/game_data.gd`
  next to the others, with `# LEVER` on the balance dials.
- A new rule ships with an assert in `src/tools/headless_check.gd`. A new input
  path ships with a case in `src/tools/input_check.gd`. Same pass, not later.
- Art is generated from ASCII maps in `tools/gen_sprites.py`, sound from
  `tools/gen_sfx.py`. Do not hand-author PNGs or WAVs: edit the source and
  regenerate.
- **Everything is in English** - identifiers, comments, commit messages and
  every player-facing string. Portuguese arrives as a translation file at task
  0097, never as a hardcoded string.
- Match the surrounding style: tabs, `snake_case`, `##` doc comments on public
  functions.
- Do not create a new top-level directory without saying why in the journal.

## Step 4 - verify

```bash
python tools/verify.py
```

Parse check, every script compiled with `--check-only`, `headless_check`, the
two hash guards, `input_check` and both exports. A check whose target does not
exist yet prints SKIP - the backlog builds them one at a time, and an early task
is not expected to have all of them. It prints one PASS or FAIL. **Everything
that is not a SKIP must pass.**

Run `verify.py` rather than the Godot scripts by hand: it does `--import`
first, which refreshes the global `class_name` cache. A brand new `class_name`
is invisible to `--script` runs until that happens, and the error you get
instead is a misleading "Identifier not declared in the current scope".

About the two hashes:

- The **sim hash** moves when the rules do: a fixed scenario, a fixed seed, a
  fixed number of ticks. The **data hash** moves when the balance tables in
  `game_data.gd` do. A port that changes no behaviour moves neither.
- If the task **intentionally** moved one, that is fine: run
  `python tools/verify.py --accept`, and record the old and the new number in
  the journal. It prints both for you.
- If one moved and the task had no business moving it, **that is a bug**. Find
  it before doing anything else. A view-layer task moving the sim hash means
  something in `src/ui/` is writing to the state; a task that was not a balance
  pass moving the data hash means a number was changed in passing.

If the task changed anything visible, capture the screenshots and **actually
look at them** (once task 0082 exists):

```bash
"C:/Users/PC GAMER DA FAMILIA/Documents/Godot/Godot_v4.7.2-stable_win64_console.exe" --path . --script res://src/tools/shot.gd -- ./implementation/shots/0042
```

Before 0082 exists, run the game and look at it.

## Step 5 - close it out

```bash
python tools/task.py done 0042
```

The checkbox in `implementation/BACKLOG.md` ticks itself. Then append to
`implementation/PROGRESS.md` (newest last):

```markdown
## 0042 - The shooting tower - done 2026-09-27

What changed: two or three sentences, in plain language.
Files: src/core/towers.gd, src/core/game_data.gd
Verify: 96 headless / 21 input / hash 1873912198 unchanged
Notes: anything the next session needs to know. Follow-ups worth a new task.
```

Could not finish it?

```bash
python tools/task.py blocked 0042 "why, in one line"
```

and write the same journal entry with `- blocked`, what you tried, and exactly
what decision or asset it is waiting on.

## Step 6 - commit

If this is a git repository, commit this task on its own:

```bash
git add -A && git commit -m "$(cat <<'EOF'
0042 The shooting tower

<one line on what changed>

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

If it is not a git repository, do not initialise one unless the task says to.
Mention it once in the journal and move on.

## Step 7 - report and stop

Two or three lines to the user: which task, what changed, the verify numbers,
and what `python tools/task.py stats` now says. Then stop. Do not start the next
task in the same invocation - the loop will call this file again.

---

## Judgement

You will hit tasks whose requirements turn out to be wrong once the code is in
front of you: a number that breaks balance, a feature that fights the design
document, a dependency that should have come first. When that happens:

- Do the version that serves the game, not the letter of the prompt.
- Write down what you changed and why in the journal.
- If it invalidates later tasks, edit those prompt files.

Do not silently skip requirements. Do not invent new scope. If a task is
genuinely a bad idea, mark it `blocked` with the reason and stop, so the next
invocation picks up the one after it.

**Two tasks are checkpoints, not features.** Task 0027 is the end of the first
playable build and task 0066 is the end of the MVP. Both ask you to answer the
design document's question in the journal - after surviving the night, did you
want to go back to the farm and improve? Answer it honestly. A "no" at 0027 is
worth more than forty more tasks built on top of it.
