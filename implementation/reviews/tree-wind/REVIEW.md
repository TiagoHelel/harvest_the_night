# Leaf-only wind — 2026-10-02

The user reported that the trunks moved and requested gentle, different motion
between trees. The previous vertical mask faded out near row 40 of a 48px sprite,
so it moved both foliage and exposed wood. The effect now fades from rows 13 to
22 and is exactly zero below row 22, above all exposed branches in both existing
40x48 tree variants. Lower foliage stays anchored around the wood.

The canopy's maximum displacement is 0.65–0.95 native pixels. Each tree receives
stable position-derived speed, amplitude and phase; two slow sine components
produce individual rhythms. Only foliage uses horizontal interpolation with
premultiplied alpha, giving gradual movement at subpixel distances. Wood keeps
its original nearest-filtered pixels. Source PNGs, shadows, collisions, animals,
camera and simulation are unchanged. No new raster generation was required.

## Actual renderer verification

```powershell
$env:GODOT = 'C:\Users\Helel\Documents\godot\Godot_v4.7.1-stable_win64_console.exe'
python tools/show_art.py --tree-wind
python implementation/reviews/tree-wind/preview.py
```

`tree_wind_showcase.gd` checks three separated trees, covering both source
variants and two instances of the round variant with different rhythms. It
captures twelve seconds at 30Hz in daylight and twelve seconds at night: 720
unmodified 480x270 frames plus two static references rendered with no shader.
For every tree on every frame, the entire sprite region from row 22 downward
must equal the static reference pixel for pixel. It checks bounded wind
parameters, independent speeds, unchanged state/RNG and paused wind time.

Result: **3,617 checks, zero failures**. `parameters.json` records each tree's
source, screen origin and wind values. `pixel-motion.json` independently checks
all protected wood pixels and consecutive-frame canopy changes: maximum RGB
channel change is 3–4/255 by day and 1–2/255 at night, rather than abrupt pose
switches. Each canopy has 350–358 distinct native appearances over 360 frames.
The GIFs preserve the twelve-second capture cadence; their playback repetition
is a clip boundary, not a shared tree-animation period in the game.

`contact.png` contains native and exact 3x closeups from eight daylight phases.
Inspected those phases, native daytime/nighttime captures and enlarged source
wood/foliage boundaries. Trunk and exposed branches remain rigid while the
upper leaf clusters flex subtly; native silhouettes remain readable. The effect
has a slight interpolated edge only in moving foliage, deliberately keeping the
wood crisp. The sprite bounds and source scale are unchanged.

Focused regression verification passes: 117 scripts parse, 121 camera/zoom/ambient
checks, unchanged sim 3960053733 / data 3913993875 and performance budgets
(674us/8,333us night tick, 5,828us/33,333us path rebuild). See
`verify-focused.log` and `capture.log`. The previous full 53-gate verification
belongs to the preceding map/camera task; this correction ran the relevant
shader, native-render, presentation, determinism and performance checks.

The Godot project file had an unrelated editor serialization change when this
follow-up began and is excluded from this correction's commit.
