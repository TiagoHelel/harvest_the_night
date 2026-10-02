# 0016 - Giant motion and bounded enemy deaths

Reviewed on 2026-10-02. This task creates only the missing Giant family and
reuses every ordinary enemy drawing from 0015. Completed player, terrain,
props, crops, buildings, defenses and ordinary enemies remain unchanged.

## Sources and native contract

Five actual built-in ImageGen returns were accepted, with zero revisions:
`assets/art_source/enemies/giant/{master,walk,windup,slam,death}.png`.
The master references the accepted tank master and reference sheet. Each
motion references its own accepted Giant master and the tank master. Exact
prompts, original returned paths, actual arguments, hashes and measured cuts
are saved under `implementation/sprites/generation/0016-*`. All five returned
sources were opened and reviewed. No API/CLI fallback or code-painted art was
used. Conversion performs measured crop/nearest/palette/binary-alpha only.

Sixteen canonical poses comprise one master, four steps, three wind-up poses,
three slam poses and five death poses. Four old names remain exact aliases:
walk_b -> walk_2, attack -> slam_0, telegraph -> windup_2, death -> death_4.
Ownership is 392 raster / 29 ASCII / zero player-sheet, 421 runtime PNGs.
The ASCII generator skips Giant only when the entire migrated family is owned.
Source checks prove exact outputs and real pose differences rather than row
shifts, binary alpha, unclipped silhouettes and fixed strip scale/contact.

The final canvas is 80x64 with pivot (40,60), rather than the pilot 64x64.
Only transparent width grew: the ground-contact fist needs clearance while
the feet stay planted. The master has a 43x42 visible body; ordinary standing
bodies remain about 29 pixels tall. Wind-up heights are 39/48/55; death heights
are 39/33/27/20/16. All poses preserve the measured ground support. Slam cuts
use the feet rather than the extended contact fist as the support anchor.
`measured-contract.json` records the complete output and source bounds.

## Runtime behavior

EnemyMotion tracks Giant with the four ordinary families. Real core deltas
advance walking and facing. A valid existing adjacent target and chew wait
select wind-up; an observed real hit starts contact/recovery. Distant/stale
targets and a newly assigned target with old chewing data do not invent a
strike. The three slam poses last nine core ticks cosmetically; subsequent
core movement can continue during recovery. Art never freezes or slows rules.

EnemyDeaths borrows only coordinate Arrays across one fixed tick because
Enemies moves them in place before traps/projectiles can remove the enemy.
Afterward it copies the final position, kind and facing, then releases all
borrowed arrays. No entity dictionary is retained, and no dead entity remains
in core, occupancy, hits or pathing. The cap is 24 cues and 24 lazily allocated
sprites in the existing y-sorted actor container. A full pool replaces the
oldest cue. Each frame lasts 0.12 render seconds: ordinary deaths expire after
0.48s, Giant after 0.60s. Expiry hides the reusable sprite. Duplicate after-tick
calls, skipped tick gaps, state replacement and morning cleanup cannot replay
death. All ordinary death textures are reused byte for byte from 0015.

## Visual review and corrections

Opened all six complete motion sheets at native size and exact 3x nearest:
`motions-{light,dark,checker}-{native,3x}.png`. The heavy shoulders, fists and
bare torso distinguish Giant beside the farmer, house and ordinary enemies.
The raised arm changes the silhouette before contact. Death progressively
collapses at the same scale. Alpha has no generated floor, aura or baked glow.

Opened all 49 accepted real 480x270 captures alongside exact 3x nearest on
`captures-00..24.png`. `captures.json` identifies every original and hash.
Original shots live in `implementation/shots/sprites/0016/` and its `giant/`
folder. Reviewed both walking directions with ordinary escorts, all wall
wind-up/slam phases in both directions, the actual house tell and spent Giant,
day/night identities, black silhouettes, all five families' one-shot death
frames and expiry, the 24-sprite stress view, and all five standard game views.
Visible body size, fixed contact, scale, depth, source ownership and motion pass.

The house fixture exposed a real visual failure: the old below-occupants target
ring produced zero visible pixels beneath the roof in all three wind-up phases.
Rejected captures remain under `pre-warning-layer/`, with the failed log
`showcase-house-warning.log`. The ring now draws on EnemyWarning above actors
and roof, below projectiles, using the same existing target/radius/color/time.
Actual hide/show pixel comparisons pass for wall tells in both directions and
all house phases. Natural roof occlusion still hides part of a boss standing
behind the house; the warning remains visible throughout the valid tell.
No source regeneration was needed for this correction.

Night cloth/material colors remain dark under the existing shared lighting.
The Giant retains readable size/shape and the small face highlight; ordinary
identities mainly read through silhouette at night. Atmosphere task 0019 should
improve this using current accepted art. The user explicitly requested that
completed sprites be preserved; enlarging a window alone adds no native detail.

## Verification and preservation

Final headless Giant showcase: 2,433 checks, zero failed. Actual renderer:
2,530 checks, zero failed, saved in `showcase-capture-final.log`. It compares
serialized state with an unobserved control, actual pre-hit waits/contact,
post-movement death locations, all poses/expiry, repeated observer rejection,
load/day resets and 64 simultaneous removals with a hard 24-sprite cap.
Full-pool refresh measured 110.6us against an 8,333us budget in capture mode.
Source checker proves sixteen authored poses and four exact aliases.

The first full verify passed 46 gates and failed the old interface assertions
that still expected the procedural two-frame walk/telegraph names. The input
case now checks the four authored steps and lets core begin a valid house tell,
instead of assigning a distant stale winding_at value. The focused rerun passes
982 cases, zero failed. Initial failures and successful logs are retained.
Final full verify PASS: 47 passed, zero skipped/failed in 352 seconds using
Godot 4.7.1. The soft 300-second target reports OVER BUDGET without failing.
All 111 scripts parse, 6,612 rule assertions and 982 input cases pass, and
Windows/Web exports pass. Raster verification proves 392 outputs with zero
writes. Night tick performance is 555us/8,333us; path rebuild is 4,246us/33,333us.
Sim hash `1961000123` and data hash `407837701` remain unchanged. Complete
results are in `verify.log`; no hash acceptance or skipped gate was used.

Audit against `94ce993` preserves 1,109 prior core/art files and every preceding
raster manifest entry. Owner art, all earlier raw sources/runtime families,
palette and hash baseline files are protected. Five raw tool returns, five
exact submitted prompts/references and twenty owned outputs/aliases are checked;
staged exact bytes are checked before commit. Unrelated generated import files
from prior tasks remain excluded. The raster importer is unchanged and no extra
fault-suite run is claimed. Rules, balance, collision, grid, saves and core code
are unchanged.
