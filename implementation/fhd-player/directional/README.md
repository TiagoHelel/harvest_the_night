# Approved farmer: directional animation review

The user requested previews first and subsequently authorized game integration
on 2026-10-02: "quando terminar implementa no game". Idle, walk and run are now
promoted in all four directions. The thirteen activity families remain review
candidates. Runtime rendering uses the exact reviewed native locomotion PNGs;
movement speed, tools, collision and deterministic simulation remain unchanged.

The exact approved identity is `assets/art_source/player-fhd/approved/idle_south.png`
(SHA-256 `4706f5b8163d4be2d3d8f285bdffe970a315a9c770e6b28bef4e74c4993ba6f1`).
Previously approved south-facing idle/walk/run drawings and recipes are reused
unchanged. All other views are generated from that identity using built-in
ImageGen; subsequent activities also reference the generated cardinal idle views.

## Coverage

| Family | Frames per direction | Directions | Total native frames |
| --- | ---: | ---: | ---: |
| Idle | 3 | 4 | 12 |
| Walk | 8 | 4 | 32 |
| Run | 8 | 4 | 32 |
| Chop, mine, till, plant, harvest, water, fish, reel, collect, craft, trade, repair, carry | 4 each | 4 | 208 |
| Total | | 64 animations | 284 |

Most views were generated separately. The revised lateral walk and run follow the
creator repository recommendation: generate right and reflect the complete
source-owned poses to obtain left, with the reflected foot pivot retained. Walking/running have eight different native
lower-body drawings each. Work strips use four action key poses, not repeated
idle frames. A held rod is present in casting, waiting and reeling drawings.
The casting preview deliberately holds the final waiting pose before recasting.

## Review artifacts

- `todas-animacoes-horizontal.gif`: one 1040x288 horizontal clip cycling through
  all sixteen categories, 3.84 seconds per category / 61.44 seconds total.
- `gifs/<action>-horizontal.gif`: sixteen independently looping horizontal
  four-direction clips, 7.68 seconds each at 25 fps.
- `index.html`: local selector, exact FHD/native scale toggle, downloads and
  complete native contact-sheet links. It loads only the selected animation.
- `contacts/`: all 64 directional contact sheets at an exact nearest 2x scale.
- `review-stills/`: selected original Godot captures plus consecutive phase
  montages retained for visual evidence.
- `captures/<action>/`: all 192 original renderer PNGs per action, retained
  locally and reproducible; excluded from Git to avoid committing 3,072 captures.

The renderer presents standing bodies at 120 physical pixels (60 source-native
pixels enlarged exactly twice), matching the intended FHD actor appearance.
Locomotion uses 96x96 native canvases with (48,88) ground registration, or
(47,88) for the reflected west walk/run. Work uses
128x128 / (64,108) to preserve complete raised tools and contact below the boots.
The body scale stays 60 pixels; extra transparent canvas is tool clearance.
Runtime locomotion retains its 96x96 canvas and per-direction pivot, drawn at
0.5 logical scale. Existing activity/reaction padding remains independent.

## Source contract and revisions

Raw sources and all 265 newly cut native frames are in
`assets/art_source/player-fhd/directional/`. Exact prompts and actual call
metadata (including original built-in output paths) are in `prompts/`. The 19
existing front-facing native frames remain in the previous approved directory.
`jobs.json` records the initial atlas layout; `review-contract.json` records the
final source/prompt/output hashes, measured gutters, crops, body scale, foot
anchors, canvas geometry and selected focused revisions.

Only source component selection/crops, uniform nearest reduction, binary alpha and the existing
shared project palette produce the native PNGs. No native sprite is hand-painted
or procedurally substituted. Transparent gutters are measured near the requested
grid boundaries separately for each activity column, so a tool can extend below
the previous row's nominal boundary without leaking into the next farmer.
The largest connected farmer/tool component defines each crop; detached seed
and droplet components are included explicitly for planting/watering. Selection
mask hashes record exactly which original alpha pixels belong to each frame;
no color or tool is drawn to repair a crop. Tools do not determine body scale. Locomotion
registers hat center and a shared ground per source row, retaining raised boots.
Work registers boot contact so torso bending is not cancelled by head alignment.
The crown above the brown hat band is measured separately, and locomotion's
complete outline-to-sole silhouette is bounded to 60 native pixels. Body palette
subsets match the approved front farmer; additional prop colors are action specific.

Revisions kept alongside the originals:

- `run_north-r1`: transparency inspection candidate. Source alpha inspection
  confirmed the brown-looking preview background has zero alpha; raw RGB in
  invisible pixels is not a painted scene in the exported sprites.
- `run_east-r1`: correct the reversed facing in the second stride half.
- `plant-r1`: keep left/right crouching faces oriented toward the reach.
- `repair_west-r1`: make the hammer strike ahead to the left.
- `chop_north-r1`, `mine_north-r1`: strike away from the viewer, partly occluded
  by the hat, rather than below the farmer's boots.

## Reproduce

```powershell
python implementation/fhd-player/directional/build_review.py
. implementation/farm-house/prepare_qa.ps1
& 'C:\Users\Helel\Documents\godot\Godot_v4.7.1-stable_win64_console.exe' --headless --path $env:GODOT_PROJECT_PATH --editor --import --quit
& 'C:\Users\Helel\Documents\godot\Godot_v4.7.1-stable_win64_console.exe' --path $env:GODOT_PROJECT_PATH --fixed-fps 25 --position -4000,-4000 --script res://src/tools/fhd_directional_preview.gd
python implementation/fhd-player/directional/build_review.py --check --encode
```

`--check` validates exact source/prompt/native output hashes, complete direction
counts, unique work poses and all eight distinct lower-body walk/run phases.
GIF encoding validates the dimensions, 192 real renderer inputs and timing.
No game simulation is run by the isolated playback scene.

## Integration boundary

### Lateral walking review follow-up

The user accepted all four idle directions and requested replacements for west/
east walking. Following additional feedback, the final workflow imports the
actual `buildDirectionalPrompt` and `STUDIO_ACTIONS` from the local
`sprite-sheet-creator/app/lib/prompts.ts`. `import_creator_prompts.cjs` reads that
repository without changing it; `prompts/creator-provenance.json` pins its SHA-256.
Submitted prompts and calls are retained exactly, including focused revisions.

Reference order follows that builder: accepted facing-right rotation, canonical
farmer design, and accepted front walking. Its four anchor poses use a 2x2 grid.
Four distinct in-between poses complete the requested eight-frame cycle, with
explicit near/far boot material corrections where the generator reused the same
leg. Final sources are `creator-walk-right-keys-r1.png` and
`creator-walk-right-transitions-r2.png`. Left reflects the complete right poses,
as the creator README recommends, rather than regenerating a mismatched gait.

Only sixteen lateral walking frames changed; the remaining 268 native frames,
including approved idle and front/back walking, stay byte-identical. Warm boot
pixels in the generated transitions use the project's brown material ramp so
nearest palette mapping does not turn leather into hat gold. No pixels are
hand-painted. The source check now guards opposite near/far boot positions at
contacts and the support/reach phases (0,1,3,4,5,7), catching the earlier same-leg
cycle that passed simple frame-count/uniqueness tests. This guard is limited to
material separation; actual renderer playback still requires visual review.

`user-review.json` retains idle approval and leaves walking pending. The same
HTML versions image URLs by GIF content hash so revised previews avoid stale
browser images. Full Godot captures, eight consecutive phases and a browser
screenshot remain in `review-stills/`.

### Lateral running review follow-up

The user requested the same repair for left/right running. The reusable
`import_creator_run_prompts.cjs` imports the actual creator repository's `run`
action and directional prompt builder. Exact base/submitted prompts, source
hash and reference roles are in `prompts/creator-run-*`.

Final sources are `creator-run-right-keys-r1.png` and
`creator-run-right-transitions-r2.png`. Four anchors occupy frames 0,2,4,6;
four intermediates occupy frames 1,3,5,7. Foreground/background legs exchange
support, arms pump in opposite directions between stride halves, and both boots
clear the ground during flight phases 2,3,6,7. The contact/support phases
0,1,4,5 remain on the shared ground. Left reflects the complete right drawings.
The first anchors repeated their arm swing; the first intermediates repeated
extended contact and their revision hid the second leg in opposite support.
Focused edits correct those errors without painting native sprites.

Only sixteen lateral run PNGs changed in this follow-up. The other 268 native
frames, including idle, all walking and front/back running, remain byte-identical
to commit `d5a27f7d`. `check_lateral_run.py` and `run-gait-regression.json` retain
the old same-leg negative control and final measurements. All sixteen new
material/contact/flight measurements pass, while the previous cycle fails the
opposite-leg check. Material checks do not establish subjective motion quality.

Real Godot captures refresh `gifs/run-horizontal.gif` (1040x288, 7.68s at 25fps)
and the running section of the 61.44s overview. Native sheets, eight consecutive
actual renderer phases and the browser proof are retained. At preview commit
`82307ecd`, run remained pending user validation and actor bindings were unchanged.
The subsequent explicit user integration request promotes locomotion as recorded
below. Older rejected pilot assets remain separate from the promoted selection.


## Runtime integration — 2026-10-02

`promote_locomotion.py` registers 76 reviewed locomotion PNGs with the existing
raster importer: 12 idle, 32 walk and 32 run. `runtime-locomotion-contract.json`
pins the original master/prompt/crop/native output recipes. Its `--check`
rederives every original cut and checks exact runtime bytes and geometry.
The 208 directional activity candidates remain pending review.

The game defaults to 1920x1080 with Canvas Items rendering over the existing
480x270 layout. A 60-native-pixel body draws at 120 physical pixels in FHD.
Each locomotion family owns its canvas, pivot and 0.5 draw scale; old tools and
reactions keep their own metadata. East no longer substitutes a flipped west
walk. West walk/run retain the reviewed reflected (47,88) ground pivot.

Holding **Shift** while moving selects RUN; releasing it returns to WALK.
Shift alone remains IDLE. This selects animation at the existing movement
speed, outdoors and indoors, and is rebindable in the controls menu.

```powershell
python implementation/fhd-player/directional/promote_locomotion.py
python tools/import_art.py
python implementation/fhd-player/directional/promote_locomotion.py --check
. implementation/farm-house/prepare_qa.ps1
$env:GODOT = 'C:/Users/Helel/Documents/godot/Godot_v4.7.1-stable_win64_console.exe'
& $env:GODOT --path $env:GODOT_PROJECT_PATH --fixed-fps 25 --position -4000,-4000 --script res://implementation/fhd-player/directional/runtime_capture.gd
python implementation/fhd-player/directional/runtime_encode.py
python tools/shot.py sprites/fhd-locomotion --fhd noon dusk wave result tech house_interior
python tools/verify.py
```

`runtime_capture.gd` runs the production World/PlayerView and Player.tick at
30Hz while sampling at 25fps, with the actual day/night relight pipeline.
All 24 timed sequences show every registered pose: 1,536 FHD renderer frames,
6,168 checks, no failures. Captures are excluded from Git and protected from
editor import by .gdignore. `review-stills/runtime-horizontal.gif` retains
physical pixels without rescaling; four complete FHD frames are saved alongside.
`runtime-capture-report.json` records the sequences. Full-game screenshots,
including the house, are in implementation/shots/sprites/fhd-locomotion/.

Final full verification: **55 passed, zero skipped/failed**, 491s.
Parsed 125 scripts; 7,768 core assertions; 1,006 input cases.
Sim/data hashes remain 1270427719 / 8148086. Evidence: runtime-verify.log.


## Lateral run: actual two-leg exchange — 2026-10-03

The user reported that integrated left/right RUN still looked like one moving
leg. The preceding color-based test was a false positive: baseline 0cbb4a27
passes all its boot checks while its foreground trouser/knee remains nearly
stationary between opposite contact and passing phases.

Built-in ImageGen generated creator-run-two-leg-keys-r1 from the approved east
idle identity. It was rejected because flight repeated an extended stride.
A targeted r2 replaces flight with compact, bent-knee passing poses and makes
opposite near/far chains explicit. creator-run-two-leg-transitions-r1 supplies
four compressed/reaching intermediates. Exact submitted prompts, references,
original output paths and decisions are retained in prompts/*.call.json.
The creator repository's existing run/push-off/opposite-stride guidance remains
the basis of the prompts. No pixels were painted by a script.

Sixteen lateral native/runtime PNGs are replaced; other 268 review frames are
byte-identical to 0cbb4a27. West reflects the complete east source and pivot.
The foreground trouser knee now exchanges by 5.94 native pixels across contact
and 10.22 across passing in both directions. The new geometric guard excludes
boot pixels and rejects the actual reported baseline. It runs during review
and the full runtime-source check. Boot/material and contact/flight guards
remain, rather than being removed to accept a new image.

The eight-phase contact sheets and normal-speed Godot preview were refreshed,
as were the FHD day/night runtime sequences and runtime-horizontal.gif.
review-stills/run-two-leg-comparison.gif compares old/new left and old/new
right at the same 25fps clock. This is renderer evidence, not interpolated
or procedurally generated motion. The same index.html links this comparison
and loads the new RUN GIF using its content hash. Runtime speed/control rules
remain unchanged; RUN continues to use the existing travel speed.

Reproduction: run build_run_comparison.py after the RUN Godot capture.
Full working-tree verification passed **55 checks**, zero skips/failures,
in 529s (over the 300s soft target): 125 parsed scripts, 7,768 core assertions,
1,006 input cases. Sim/data hashes remain 1270427719 / 8148086.
Logs: two-leg-verify.log, two-leg-gait-check.log, two-leg-runtime-capture.log.

## 2026-10-03 — Follow-up: match front/back WALK head proportions to idle

The user reported enlarged heads while walking down and up. Native comparison
confirmed south head/brim widths of 48/44 pixels and north widths of 46/42,
versus the accepted idle head width of 43 and south/north brim width of 39.
This is source-art proportion drift, not a window/resolution issue.

Built-in ImageGen made one targeted edit per eight-pose sheet, retaining the
existing contact/lift order, compact farmer identity and approved eye whites.
Selected raw masters: assets/art_source/player-fhd/directional/walk_south-head-r1.png
and walk_north-head-r1.png. Exact submitted prompts, original built-in output
paths, reference roles and decisions are under directional/prompts/walk_*-head-r1.*.
Original approved sheets remain unchanged. No native sprite was painted.

New source-owned cuts keep 96x96 canvases, (48,88) pivots and 0.5 draw scale.
South head width is 42, brim 37–38; north head is 42–44, brim 38–40. Maximum
body height stays 60 native / 120 physical pixels at FHD, with natural passing
pose variation. Eight unique lower-body phases remain in each strip. The other
268 native review drawings, every other runtime actor and fifteen other action
GIFs are byte-identical to 80d269e6. Exactly sixteen runtime PNGs were rewritten.
Body/leg drawings within the two edited sheets are generated source edits;
they are not claimed byte-identical to the old sheets.

build_review.head_dimensions excludes overall buttons from hat measurements.
assert_walking_head_scale checks all sixteen head/brim widths against accepted
idle and cycle consistency during review and the full runtime-source guard.
check_walking_heads.py / walk-head-regression.json retain the actual old
oversized-head negative control and preservation measurements. Revised south
walking has an explicit source owner; the historical approved front contract
stays intact. Stable contract ordering avoids unrelated manifest churn.

Actual Godot WALK preview: 192 frames at 25fps, same horizontal gallery and
7.68s four-direction GIF. build_walk_head_comparison.py provides old/new down
and old/new up at matched clocks in review-stills/walk-head-comparison.gif.
Native nearest-3x idle/before/after comparison was opened. Production
World/PlayerView and 30Hz Player.tick day/night capture: 1,536 FHD frames,
24 sequences, 6,168 checks, zero failures. The runtime GIF, every consecutive
front/back phase montage and day/night nearest-3x crops were inspected for
proportions, separate boots and loop continuity. Captures remain local,
excluded from Git and editor import. UTF-8 gallery text is preserved.

Full-game FHD screenshots for noon, dusk, wave, result, tech and house_interior
were opened in implementation/shots/sprites/fhd-walk-heads/. Full verify/export:
55 passed, zero skipped/failed, 510s (over the 300s soft target); 125 parsed
scripts, 7,768 core assertions and 1,006 input cases. Sim/data hashes remain
1270427719 / 8148086. Evidence: walk-head-verify.log, walk-head-check.log,
walk-head-source.log, walk-head-import.log, walk-head-preview-capture.log,
walk-head-runtime-capture.log, walk-head-encode.log and walk-head-shots.log.
Sprite queue check remains PASS for twenty completed prompts.

The existing integration authorization persists; walking remains pending user
visual validation. During this work the user again rejected lateral RUN, so its
next revision is separate from this completed head correction. No RUN drawing
was changed in this commit. Unrelated pilot files stay outside the commit.
No push, automation or core/control/movement change was made.

## 2026-10-03 — Follow-up: readable anatomical leg recovery in lateral RUN

The user again rejected lateral running after 80d269e6: it still looked like
only one leg stayed forward. That baseline passed anchor-knee tests, but its
phase-3 bright trouser connected to the dark foreground boot, contact sleeves
barely alternated and the far front boot was too bright to distinguish support.
The completed front/back WALK head correction c876a33 is preserved.

Built-in ImageGen, using the actual sprite-sheet-creator run prompt and existing
farmer references, produced creator-run-leg-swing-keys-r1/r2/r3.png and
creator-run-leg-swing-transitions-r1/r2.png under
assets/art_source/player-fhd/directional/. Exact submitted prompts, original
output paths, reference roles and selection/rejection decisions are saved in
directional/prompts/creator-run-leg-swing-*.*. Key r1 repeated sleeves; r2 still
misassigned a passing trouser/boot. Select only r3 source cells 0/2/3 as phases
0/4/6. Its cell 1 is rejected; phase 2 remains byte-identical to the coherent
existing creator-run-two-leg-keys-r2 cell 1. Transition r1 also misassigned the
phase-3 trouser; r2 corrects that connection and supplies phases 1/3/5/7.
This is three targeted key revisions and two transition revisions. No native
sprite was painted and no intermediate pose was procedurally invented.

Partial source selection now measures scale and row ground from the complete
four-cell family before choosing output cells, preserving the old passing pose.
The existing lateral boot material ramp explicitly covers these new sources;
without it, generic nearest-palette conversion incorrectly made boots gold.
Fourteen native/runtime PNGs changed; two phase-2 poses and all 270 remaining
native frames are byte-identical to c876a33. Eight frames per direction,
96x96 canvas, existing pivots, 0.5 draw scale and 120px FHD body height remain.

All previous anchor-knee, boot material, contact/flight, unique lower-body and
walking-head guards remain. The additional recovery/sleeve/contact guard rejects
the actual reported baseline. In both directions, phase-3 recovery improves
from 1.03 to 5.72 native pixels, opposite contact sleeve movement from -0.12 to
5.38; contact boot contrast is now 105.48/102.12 instead of 94.89/51.99.
check_run_leg_swing.py and run-leg-swing-regression.json record the negative
control, both passing loops and unchanged-art checks. Tests support structural
consistency; subjective motion remains pending user validation.

Actual Godot preview captured 192 RUN frames at 25fps. Normal before/after
comparison uses 80d269e6 and matched clocks, 7.68s; the slow GIF uses the same
frames at 80ms, 15.36s, without interpolation. The same index.html has normal
and slow comparison links, preserved UTF-8 text and new RUN hash f36eae092348.
Its RUN selection and screenshot were checked in the existing browser tab.
The gallery overview remains 61.44s and the fifteen other action GIFs are
unchanged. Selected native nearest-3x strip was visually inspected.

Production World/PlayerView with 30Hz Player.tick captured 24 day/night
sequences, 1,536 FHD frames and 6,168 checks, zero failures. Consecutive RUN
phase montages, normal-cadence playback and day/night nearest-3x crops were
inspected for continuous trouser-to-boot ownership, alternating supports/arms
and loop continuity. Phases 2/6 clear the ground by three native pixels;
intermediate phases 3/7 clear it by one, retaining quantized eight-frame motion.
All six full-game FHD stills were opened in
implementation/shots/sprites/fhd-run-leg-swing/: noon, dusk, wave, result, tech,
house_interior. Original timed capture trees remain local and excluded from Git.

Full tools/verify.py passed 55 checks, zero skipped/failed, 518s (above the
300s soft target), including 125 parsed scripts, 7,768 core assertions,
1,006 input cases and exports. Sim/data hashes remain 1270427719 / 8148086.
Evidence is directional/run-leg-swing-{source,promotion,import,godot-import,
check,preview-capture,runtime-capture,encode,shots,verify}.log.
Both journals are appended; queues remain 110 game and 20 sprite tasks complete.
Existing integration authorization is used; no new approval is inferred.
No core, controls, movement speed, project resolution, push or automation change.
Unrelated pilot and import sidecar files remain outside this focused commit.

## 2026-10-03 — Follow-up: match the reported front WALK body to idle

The two user screenshots identified a remaining size mismatch. Masked pixel
matching against actual 9c2e51ec production frames identifies idle_south_1 and
walk_south_4; reported-size-diagnostic.json preserves the matches and source
anatomy. Their head widths were already 43/42 and heights 60/59 native pixels.
The walking upper body, including sleeves/hands, was 40 pixels wide versus idle
34–35, about 14% wider; chest width alone and total height missed this drift.

One targeted built-in ImageGen edit uses the current walking sheet as edit
target and the exact approved idle as identity/proportion reference. Source:
assets/art_source/player-fhd/directional/walk_south-body-r1.png. Prompt and call
metadata: directional/prompts/walk_south-body-r1.*. Original generated output:
C:/Users/Helel/.codex/generated_images/01a0f7e5-4a37-7612-b3d9-590f2b3bfba5/exec-b71fded5-ebcc-461c-ae65-412d3b413e60.png.
No native pixels were painted, no whole-sprite stretch was introduced and the
approved idle remains unchanged. Generated legs retain eight distinct phases;
the lower bodies of the regenerated sheet are not claimed byte-identical.

New eight-frame front walking has upper-body width 33–34, blue chest 15–16,
head width 42, brim 38, visible height 59–60. Shoulder offset is 29–30 versus
idle 30–31: one passing pose remains one pixel outside the idle range, within
the single-pixel animation tolerance. Build and promotion now check torso/arm
width and shoulder proportion as well as all previous head, native scale,
leg/boot, contact, palette, ownership and lateral RUN guards. The regression
helper rejects all eight actual old broad poses and verifies all 276 unrelated
native frames are byte-identical to 9c2e51ec, including every RUN and the other
three WALK directions. Runtime importer reports 512 outputs, exactly eight
rewritten. Fifteen other action GIFs are byte-identical. Existing 96x96 canvas,
ground pivot and 0.5 draw scale remain unchanged.

Actual preview captured 192 IDLE and 192 WALK frames at 25fps. Production
World/PlayerView with real 30Hz Player.tick captured 1,536 FHD frames over
24 day/night sequences, 6,168 checks, zero failures. Native contact strip,
consecutive day/night phase montages and nearest-3x runtime crops were opened.
The normal-speed idle/before/after production GIF uses saved baseline renderer
frames and current exact-size crops; 768x232, 192 frames, 7.68s, without motion
interpolation or sprite rescaling. Comparison still and explicit nearest-3x
magnification were inspected. All six full FHD screenshots were opened under
implementation/shots/sprites/fhd-walk-body/. An initial legacy-size capture was
replaced by the required --fhd capture; final files are 1920x1080.

The same HTML includes the new size comparison link and current WALK GIF hash
88c114e1e239. Its fresh WALK selection and screenshot were checked in the
existing browser tab. Sources/prompts, diagnostic, anatomy regression and
comparison helpers are saved for reproduction. Original timed captures remain
local, excluded from Git. Integration uses existing user authorization, while
subjective visual validation remains pending. Queues remain 110 game and
20 sprite tasks complete. No core, speed, camera, resolution or controls changed.
The pre-existing project.godot input-event serialization remains outside this
commit, along with unrelated pilot/import sidecars. No push or automation.


Full tools/verify.py: 55 passed, zero skipped/failed, 623s (above the 300s soft
budget), including 125 parsed scripts, 7,768 core assertions, 1,006 input cases
and both exports. Sim/data hashes remain 1270427719 / 8148086. Evidence logs:
directional/walk-body-{diagnostic,source,promotion,import,godot-import,qa-import,
check,preview-capture,runtime-capture,encode,comparison,shots,verify}.log.
Sprite queue and final journal checks also pass; no queue statuses changed.
