# 0015 — Ordinary enemy masters and authored motion

Completed on 2026-10-02 against baseline `6e81946`, with the user's Godot
4.7.1. Walker, runner, tank and breaker now use source-owned masters and
4/3/4 walk, attack and death poses. Death sources are ready; playback belongs
to 0016. Existing filenames remain available through twelve exact aliases.

The user explicitly asked to preserve completed sprites rather than regenerate
the project. Previous families, the owner's original sheets, the pilot walker
source, palette and core remain intact. No further generation followed that
clarification; this task finishes integration of the already returned enemies.

## Sources and physical scale

Twenty-one built-in ImageGen returns are preserved byte-for-byte in
`assets/art_source/enemies/{walker,runner,tank,breaker}/`. Exact submitted
prompts, reference SHA-256 values, original return paths and arguments are in
`implementation/sprites/generation/0015-*-call.json` and the corresponding
`.prompt.txt` files. Sixteen sources are accepted; five rejected attempts remain
archived. Runner and tank death revision 1 separates overlapping bodies.
Breaker walk revision 2 retains the hammer and separate frames; attack revision
1 separates the tool/body bounds. No asset exceeds two targeted revisions.

The installer only measures/crops source pixels and applies fixed nearest
reduction, palette mapping and binary alpha. Python draws review labels and
contact guides outside the sprites; it does not paint replacement enemy art.
Each strip shares one scale, preserving pose proportions and collapsed height.

The source brief started at the pilot's 32x40 envelope. Final runtime canvases
are deliberately 64x48 with pivot (32,44): extra transparent space accommodates
the runner's lunge and breaker's hammer without clipping. Standing/walk bodies
remain about 29 pixels high, near the farmer's 30-pixel body. Enlarging the
transparent canvas does not enlarge the visible enemy. All animation pivots
and feet stay fixed; placement still uses the original core positions.

The manifest contains 48 authored poses and twelve exact compatibility copies
for this task. Ownership is now 372 raster / 34 ASCII / zero player-sheet,
406 runtime PNGs. The complete ordinary families retire the old procedural
row-shift/lunge/fall recipes. Giant remains unchanged until 0016.

## View behavior and constraints

`EnemyMotion` observes existing fixed-tick positions and chew waits. Four walk
frames follow actual distance traveled, so existing slows/speeds affect cadence.
Horizontal movement mirrors the three-quarter sources; vertical movement
retains the last observed horizontal facing. Four cardinal source directions
are not claimed. Paused rendering does not advance animation.

An observed real structure hit selects contact and recovery; anticipation uses
the final three ticks of an already existing wait for the same live adjacent
target. The core's immediate first hit remains immediate. Stale target fields,
load, skipped observations and target changes do not invent attacks. Removed
entities are pruned and a new state clears the cache. No simulation, RNG,
collision, map, balance or save field changes.

Hurt modulation is reduced to retain cloth planes, body shape and tool identity.
Death poses are reviewed as textures, without retaining dead core entities or
implementing the subsequent death-playback task.

## Visual review

All accepted and rejected raw returns were opened. Final native and nearest 3x
motion sheets for every family, both silhouette sheets, and all 34 actual
480x270 captures were opened and reviewed. `captures.json` records each capture
hash and page. Review pages `captures-00.png` through `captures-16.png` pair
the whole native viewport with its exact 3x enlargement; no source or viewport
is redrawn. Originals are under `implementation/shots/sprites/0015/` and
`enemies/`.

Visual gates pass: thin slouched walker, forward-leaning runner, broad tank and
hammer-bearing breaker remain distinct as black silhouettes and in the mixed
night fixture. Foot contacts, mirrored movement, attack reach, low collapsed
death poses, farmhouse/tree scale and actor depth are stable. Hurt retains
family identity. Source strips have clean transparent separation and no clipped
hands/tools in runtime canvases.

Night colors are very dark under the existing shared lighting. Identification
relies more on silhouette than cloth color there; daylight retains material
differences. This is a real limitation recorded for atmosphere task 0019, not a
claim that enlarging the window restores lost detail or a reason to regenerate
finished families. Ordinary bodies remain recognizable in the actual mixed
wave; final lighting evaluation should reuse their existing art.

## Verification and preservation

`verify-final.log`: **45 passed, zero skipped, zero failed**, 320 seconds.
The runner's soft 300-second duration warning is reported as OVER BUDGET;
the command exits successfully. All 109 scripts parse, 6,611 rule assertions,
982 input cases, performance and Windows/Web exports pass. Night tick costs
562us of 8,333us; path rebuild 4,307us of 33,333us. Sim `1961000123` and data
`407837701` remain unchanged.

Source checks validate 372 exact outputs with zero writes. Enemy checks prove
48 authored poses, twelve byte-identical aliases, fixed contacts, shared strip
scale, genuine shape changes and decreasing death heights. Normalized pairwise
silhouette differences are 62, 63, 81, 79, 77 and 68, all above the guard.
Headless enemy showcase: 1,982 checks, zero failed; actual renderer capture run:
2,040 checks, zero failed. Fixtures compare observer state bytes against real
core ticks, exercise all walk/attack frames, horizontal mirrors, pauses, 4x
tick batches, hurt, removal/load reset, and a moving mixed night wave.

The initial full verification exposed an older Giant comparison that included
transparent canvas margins. It now compares both enemies' visible alpha bounds
and still requires Giant to be taller and wider than every ordinary type.
The complete suite then passes. Initial debug/import/showcase logs are retained
alongside the successful logs; no hash acceptance or check skipping occurred.
This task did not change the raster importer, so no additional fault-suite run
is claimed.

`scope-and-sources.json` proves 962 protected prior core/art files unchanged,
21 exact tool returns, sixteen selected sources and sixty task outputs. Raster
bytes are compared exactly; older text CRLF worktrees are compared with their
existing Git LF canonical form. Staged source/prompt/runtime bytes are audited
before commit. Fifteen unrelated pre-existing untracked files stay excluded.

Queue after completion: 15 done, five todo, zero doing/blocked. Next is 0016,
Giant and death playback. Exactly one art task is completed in this cycle.
