# implementation/codex-claude - Claude and Codex, talking

The owner asked for one place where Claude (the game's backlog loop) and
Codex (the art packs, and the loop when the owner hands it over) can leave
each other messages. This is it. **The owner's word overrides anything
written here.**

| File | Who writes | Who reads | What |
| --- | --- | --- | --- |
| [`OPEN-WORK.md`](OPEN-WORK.md) | Claude, kept current | both, the owner | Everything left before 1.0, and what each item waits on |
| [`to-codex.md`](to-codex.md) | Claude only | Codex | Claude's messages to Codex |
| [`to-claude.md`](to-claude.md) | Codex only | Claude | Codex's messages to Claude |

## How to write a message

- **Append to your own mailbox, never edit the other's.** Newest at the
  bottom, nothing rewritten once written.
- **One heading per message**:
  `## 2026-10-13 18:40 - Codex - A046 approved`, with the date, the time,
  who, and the subject in a few words.
- **Answering one?** Start the body with `Re: <the heading's date and
  subject>`.
- **Say what you need and from whom**: the other agent, or the owner. A
  question only the owner can answer is written for the owner, in the
  mailbox of whichever agent will be talking to them next, and that agent
  asks them.
- **Paths, not pastes.** Point at files in the repository rather than
  copying them in.

## What this folder does not replace

- **The art queue stays where it is.** `implementation/backlog/` holds the
  packs, `ART-CONTRACT.md`, the deliveries, and each approved pack's
  `CLAUDE-Axxx-PROMPT.txt`. A pack approved there is what Claude
  integrates. A line here saying so is welcome, but the delivery is the
  source of truth.
- **The game backlog stays where it is.** Tasks are
  `implementation/prompts/`, their state is `python tools/task.py`, and the
  journal is `implementation/PROGRESS.md`.

## Who is running what

Only one agent works the game backlog (`implementation/prompts/`) at a
time. Two loops on the same task would write over each other.

- **Before taking a game task**, read the other mailbox. Then write
  `taking 0xxx` in your own, and `done 0xxx` or `blocked 0xxx` when you
  stop.
- **Today the game loop is Claude's.** Codex's automations in
  `~/.codex/automations/` are PAUSED, as the owner left them. If the
  owner turns Codex's loop back on, Codex says so here first.
- **Art packs are Codex's**, one at a time, when the owner asks for them.
  Claude never draws or generates an image, and only integrates what a
  delivery hands over.

## The repository's own rules still hold

They are in `CLAUDE.md`, `implementation/prompts/00-RUNNER-LOOP.md` and
`implementation/backlog/CODEX-RUNNER.md`. In short:
- English in files, pt-BR to the owner.
- Never push.
- Never stage the owner's own unfinished files.
- `python tools/verify.py` must print PASS before a game task is done.
