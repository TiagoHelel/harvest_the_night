Zombie pixel-density review: Walker, Runner, Tank, Breaker and Giant.

Current ordinary body height is approximately29 authored pixels, already
low-resolution pixel art; Giant is approximately42. Half-size nearest sampling
produces approximately15–16 and21 body pixels respectively. Expanding these
pixels2x into the original runtime canvas preserves the on-screen dimensions
and ground pivots. At FHD, each coarser pixel spans8 physical pixels, matching
the selected16px farmer style. The comparison is approximately29 versus15,
not64 versus16. Colors and binary source alpha are retained exactly.

build.py exports all80 existing enemy PNGs to native-half and runtime-size,
without writing sprites/enemies, the source manifest or game rules. contract.json
records source/output SHA256 and bounds. The variants preserve existing poses,
including their motion limitations; they are not newly generated animation.

capture.gd uses the actual WorldView, source frame pivots and Relight at FHD,
in an isolated fixed-state authored-pose review. It selects walk/attack/death
and Giant windup/slam poses, waits normal30Hz view frames and captures them.
It does not simulate combat, invent damage or claim to test path-following gait.
1530 assertions passed, with unchanged state bytes, matching source canvases
and enclosed actor crops.76 seven-actor strips and4 full FHD scenes are saved
in captures/. build.py --rendered creates GIFs and the browser inspector.
The walk GIF alternates120/130ms durations for the four125ms nominal frames.
Other GIF timings are in checks.json. Ordinary death's final pose is held
while the Giant completes its fifth frame. Standalone attack and boss demos
show authored poses, not the timings of real combat logic.

The page compares current and coarse versions at identical display sizes.
Use the scale button for actual FHD size or half size to fit all seven columns.
The source inspector supports frame selection and the game's side-view mirror.
Original art has no eight-direction enemy cycle, so none is fabricated here.

Validation:80 original enemy hashes unchanged;160 converted PNGs byte-identical
on a second export; alpha/source-color invariants; renderer1530 checks0 failed;
all GIFs loaded in the browser and Giant death/next/mirror controls checked.
Production game files remain unchanged, apart from unrelated user edits.
No engine-wide rerun is needed for this isolated review/export; the latest
production verification is recorded in the farmer review journal. No promotion,
queue mutation, unattended task or push is performed.

Farmer comparison: existing16px grounded idle beside the32px sample, both
with80x80 runtime canvas, pivot(40,72), draw scale0.5 and approximately128px
physical body height at FHD. The32px variant is80->40->80 NEAREST, retaining
exact source colors and binary alpha. farmer32/ contains64 walks and8 idles
in native-40 and runtime-80, plus the idle-left comparison file. contract.json
records all72 source hashes and144 output hashes. No sources were repainted.

farmer32-all-eight.gif has all eight approved walking directions,8 frames
at100ms per frame, in actual Godot-rendered day/night strips.128 individual
walking captures are saved. These retain existing gait, not a new animation.
All306 generated PNGs reproduce byte-identically on a second export.
