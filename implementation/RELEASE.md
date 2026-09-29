# RELEASE - the list you run before publishing

Written once so nothing is remembered at the wrong moment. Top to bottom, in
this order, because each step assumes the one above it passed.

Every line is a command. If a command is not here, it is not part of the
release; if a step has no command, it says what to look at instead.

---

## 1. The tree is clean

```bash
git status --porcelain
```

Nothing uncommitted. A release built from a dirty tree is a build nobody can
get back to.

## 2. The whole suite

```bash
python tools/verify.py
```

**Everything that is not a SKIP must pass.** This is twenty-one rows and
about four minutes, and it already contains most of what the rest of this
list would otherwise repeat: the parse check, `headless_check`, `input_check`,
both determinism hashes, the sprite, font, sound and icon generators, the
string table, the perf budget, the playtest log reader and both exports.

If it prints `(OVER BUDGET)` the suite has got slower than its own target.
That is a note and not a failure - but it is a note somebody has to answer,
not one to read past. See the journal for task 0106.

The three below are inside `verify.py` already. Run them on their own only
when one of them is what you are working on:

```bash
python tools/i18n_check.py          # every string, in both languages, fits
python tools/perf.py                # the worst case against the budget
python tools/playtest.py --self-check
```

## 3. Saves from the last release still load

```bash
python tools/verify.py              # the `headless_check` row does this
```

Task 0104's golden saves live in `tools/goldens/` and are loaded and played
by every run of the suite. **If `State.VERSION` has moved since the last
release**, there is one more thing to do by hand before the bump:

```bash
godot --headless --script res://src/tools/make_goldens.gd
```

Run it on the **last build that still had the old version**, check the new
`run-vN.sav` in, and never touch it again. A golden is only worth anything
because nobody regenerated it.

## 4. The version

Three things move together, or none of them do.

1. `src/core/build_info.gd` - `VERSION`, and `STAGE` if it has changed.
2. `CHANGELOG.md` - a section for the new version, at the top, saying what
   changed in sentences a player would recognise.
3. The tag, at step 8, after the build is proven.

`headless_check` fails if `CHANGELOG.md` has no section for the version in
`build_info.gd`, so a bump with nothing written about it will not get past
step 2 the next time round.

`release.py` stamps `BUILT` with the build date on the way out. Do not edit
that by hand.

## 5. Build it

```bash
python tools/release.py
```

This re-runs `verify.py`, clears `build/`, stamps the date, exports Windows
and Web, refuses a pack with `tools/`, `docs/`, `implementation/` or `build/`
in it, weighs both against their budgets gzipped, and boots the Windows
binary for four hundred frames looking for errors.

`--skip-verify` exists and is for iterating. **Not for a release.**

## 6. Smoke-test both builds by hand

The suite boots the Windows build; nothing boots the Web one, and nothing
plays either. Five minutes, both platforms:

- It opens, and the title screen is the farm at dusk with the logo on it.
- `CONTINUE` is absent on a fresh profile and present after you save a run.
- Play a day. Sow something, chop something, build a wall.
- Send for the night. Survive it or lose it - either is fine, both should
  end in the payout screen.
- Options: change the language to Portuguese and back, change a key, change
  the volume. Each one survives a restart.
- Quit from the pause menu. Open it again. The run comes back where it was.

On Web, the one thing that is different and worth checking every time is that
**the canvas takes the keyboard**: click once, then press a key.

## 7. The playtest build, if one is going out

```bash
python tools/release.py --playtest
```

Separate on purpose: it writes a session log about whoever is holding it,
which is fine for somebody who agreed to test and is not fine for a stranger.
It lands in `build/playtest/` with `READ ME FIRST.md` beside it.

## 8. Tag it

```bash
git tag -a v0.1.0 -m "0.1.0 - <one line>"
git push --tags
```

After the build is proven, not before. A tag on a build that turned out to be
broken is worse than no tag.

## 9. Publish

Upload `build/windows/` and `build/web/`. The store page's own assets are task
0107 and are not part of this list.

---

## Known issues

Honest, and updated at every release. An empty list here means somebody did
not look.

- **Nobody has watched a first-time player through day one.** Task 0101 built
  the seven tutorial lines and measured which four a player clears without
  reading them; the three that have to be read - the stall, putting a defence
  down, and sending for the night - have never been watched. Task 0105 built
  the build and the log reader to do it with. It is an hour of somebody's
  time and it has not been spent.
- **Twenty-seven English sentences are still hard-coded in `src/core/`**
  (`building.gd`, `sim.gd`, `farm.gd`, `tech.gd`). They are refusals - "there
  is something there already" - and a Portuguese player gets them in English.
  Task 0110.
- **The web build's size budget is met gzipped.** On a connection that does
  not negotiate compression it is roughly three times that. Nothing is done
  about this and nothing is planned.
- **The tech tree's effects are checked, not balanced.** As of 0.1.0 every
  node does what its sentence says, which was not true before this list was
  first run - but no pass has been made over whether the numbers are worth
  their costs.
- **Endless mode past night ten** exists in the rules and has not been played
  for any length of time by anybody.

## Rollback

There is nothing to roll back **to** until 0.1.0 is out, and after that the
plan is short because the game is a single folder with no server behind it:
take the download link down, put the previous tag's build back up in its
place, and say what happened on the store page's news feed. The player's save
is in `user://` and is not touched by installing over the top, and task 0104's
migrations only ever run forward - so a player who already opened the newer
build and then went back to the older one will find their run refused rather
than eaten, with `THE SAVED RUN COULD NOT BE READ - it was written by a newer
version of the game` on the title screen and the file still on disk. Tell them
to keep it; the next build will read it.
