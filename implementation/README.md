# implementation/ - the build backlog

108 tasks that take **HARVEST THE NIGHT** from an empty repository to a shipped
MVP: a cozy farm by day, a tower defence on the same tiles by night, ten nights,
a boss, and a store page.

```
implementation/
  BACKLOG.md                    checkbox index by phase (generated, do not tick by hand)
  PROGRESS.md                   append-only journal: what was done, when, what broke
  prompts/00-RUNNER-LOOP.md     the procedure: read and execute it to do one task
  prompts/NNNN-*.md             one task per file, each with a Status line
  loop.ps1 / loop.sh            unattended driver (needs the Claude Code CLI)
  logs/                         one log per loop iteration
  shots/                        screenshots, one folder per task
```

The prompts are **generated from data** in `tools/backlog/part*.py`. Reorder,
rescope or add tasks there and run `python tools/gen_backlog.py`. Existing files
are never overwritten, so progress is safe; pass `--force` if you really want to
regenerate a prompt from scratch.

---

## Running it

### From the Claude Code desktop app (no setup)

One task, verified, ticked and journalled:

```
Read and execute implementation/prompts/00-RUNNER-LOOP.md
```

Keep going until the backlog is ticked:

```
/loop 45m Read and execute implementation/prompts/00-RUNNER-LOOP.md
```

Drop the interval (`/loop Read and execute ...`) and Claude paces itself.
`/next-task` is a shorthand for the same thing - it just reads that runner file -
but the file path always works, even in a session that has not picked up the
project's slash commands yet.

`implementation/prompts/00-RUNNER-LOOP.md` is the single source of truth for how
a task gets done: picking it, the house rules, verification, the checkbox, the
journal, the commit.

### Unattended, for days (needs the CLI)

```powershell
npm install -g @anthropic-ai/claude-code
.\implementation\loop.ps1 -Tasks 40
```

or on a POSIX shell:

```bash
./implementation/loop.sh 40
```

Each task runs in its own invocation, so context never gets stale and every task
lands as its own commit. The loop stops by itself when the queue is empty, when a
task is left half-done, or when Claude exits non-zero. Add `-Yolo` / `--yolo` to
skip permission prompts on a machine you are happy to leave alone.

---

## Task lifecycle

Every prompt carries one line that the tooling reads and writes:

```markdown
- **Status:** todo
```

`todo` -> `doing` -> `done`, or `blocked` with a one-line reason. The checkboxes
in `BACKLOG.md` are **generated** from those lines - every status change rewrites
the index, so `- [x]` always means the prompt says `done`. Never tick a box by
hand; it would be overwritten on the next change.

```bash
python tools/task.py next            # what should be worked on now
python tools/task.py stats           # 108 tasks: 12 done, 0 doing, 95 todo, 1 blocked
python tools/task.py list todo
python tools/task.py doing 0042
python tools/task.py done 0042
python tools/task.py blocked 0042 "needs a decision on the night length"
python tools/task.py index           # rebuild BACKLOG.md from the Status lines
```

`next` picks the lowest-numbered `todo` whose dependencies are all `done`, and
resumes a `doing` task first if a previous run was interrupted.

---

## Definition of done

A task is done when `python tools/verify.py` prints PASS. That runs:

| check | what it protects |
|---|---|
| python tooling | the backlog scripts themselves still parse |
| backlog index | `BACKLOG.md` matches the Status lines |
| godot import | no script errors anywhere |
| `headless_check` | the game rules, every assert the backlog has added |
| sim hash | the rules still do the same thing from the same seed |
| data hash | the balance tables are still the balance tables |
| `input_check` | walking, gathering, building, shopping, fighting |
| exports | Windows and Web still build |

**The repository starts empty**, so early on most of those print SKIP with the
task number that will create them. That is intended: it is what lets task 0001
run the command at all. A SKIP is not a pass - it is a reminder.

**The two hash guards are the important ones**, and they answer two different
questions. The **sim hash** is a fixed scenario run for a fixed number of ticks
from a fixed seed: it moves when the rules do. The **data hash** folds every
balance table in `game_data.gd`: it moves when the design does. A port that
changes no behaviour must move neither.

Either moving on purpose is fine: record the old and the new number in the
journal and accept the new baseline with `python tools/verify.py --accept`,
which prints both. Either moving when the task had no business doing it is a
bug - find it before anything else. A task in `src/ui/` that moves the sim hash
means the view layer is writing to the state.

---

## House rules for the codebase

- `src/core/` holds the game rules. It is **node-free and deterministic**, and
  advances only through `Sim.tick(state)` at a fixed 30Hz: no nodes, no
  unseeded randomness, no clock reads, no iterating an unordered Dictionary
  without sorting the keys first. The headless tools, the autoplayer, the
  skip-the-night button and the browser build matching the desktop one all
  depend on this.
- `src/ui/` draws and reads input. It owns no rules, and nothing it does may be
  visible to the determinism hash.
- Every number a designer might want to turn lives in `src/core/game_data.gd`,
  with `# LEVER` on the balance dials.
- A new rule ships with an assert in `src/tools/headless_check.gd`. A new input
  path ships with a case in `src/tools/input_check.gd`. Same pass, not later.
- Art is generated from ASCII maps in `tools/gen_sprites.py` and sound from
  `tools/gen_sfx.py`. Do not hand-author PNGs or WAVs; edit the source and
  regenerate so the whole set stays consistent.
- **Everything is in English**: identifiers, comments, commit messages and every
  player-facing string. Portuguese arrives as a translation file at task 0097.
- `design.md` is the source of truth for intent and `docs/reference-sheet.png`
  for the look. A backlog task that contradicts either should say so in the
  journal.

---

## Phases

| # | Phase | Tasks | Why it is where it is |
|---|---|---|---|
| 0 | Foundation | 0001-0012 | the repo is empty: project, tick, levers, tests, save |
| 1 | The first playable build | 0013-0027 | section 19 of the design document, and nothing more |
| 2 | The full day | 0028-0041 | three crops, fishing, oil, energy, cooking, the real shop |
| 3 | The full night | 0042-0058 | five towers, walls, four enemies, the Giant |
| 4 | Ten nights and progression | 0059-0070 | waves as data, the tech tree, rewards, the autoplayer |
| 5 | Art and visual direction | 0071-0082 | the two palettes, the tileset, lighting, the transition |
| 6 | Sound and juice | 0083-0090 | generated sfx and music, shake, tooltips, the log |
| 7 | Shell and product | 0091-0100 | title, menus, options, pt-BR, exports |
| 8 | Ship the MVP | 0101-0108 | onboarding, perf, playtest, release, store page |

**Two tasks are checkpoints rather than features.**

[0027](prompts/0027-first-loop.md) is the end of the first playable build: three
waves, a payout, and a day 2 that is better than day 1. The design document is
explicit that this comes before the ten nights, and it is the cheapest possible
place to find out the game is not fun.

[0066](prompts/0066-run-end.md) is the end of the MVP: ten nights, the Giant, a
run summary. Both ask the same question in the journal - *after surviving the
night, did you want to go back to the farm and improve?* - and a "no" at 0027 is
worth more than forty tasks built on top of it.

Phases 5 to 8 do not change a rule. They are the difference between a prototype
that proves the loop and something a stranger plays to night 10.

**Start with git.** The loop commits per task, which is what makes days of
unattended work safe to review and cheap to undo.
