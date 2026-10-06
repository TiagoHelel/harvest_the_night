32px walking mirror review —exact sprite transforms, no new generation.

Requested mapping: right -> left; down-left -> down-right; up-right -> up-left.
The other five directions are copied unchanged.64 walking frames are exported
in native-40/runtime-80;24 are mirrored,40 untouched. Idle and work are not
modified. Each horizontal flip preserves the entire transparent cell, source
palette, binary alpha,8-frame order and100ms timing. Native pivot(20,36)
reflects onto itself in40x40 coordinates; runtime80 pivot(40,72)/scale0.5
keeps physical FHD body height about128px and4px detail blocks.

Original32px PNGs remain in the enemy review's farmer32/ folder. contract.json
records the exact before/source/output hashes, map and review-only status.
build.py exports exact Pillow FLIP_LEFT_RIGHT transformations; it does not
write production sprites or canonical sources. capture.gd uses the actual
WorldView/PlayerView/Relight renderer at FHD and a frozen scene. Only character
textures change, not the grass, camera or ground shadow.176 fixed-contact
before/after crops cover both daylight and night. Unchanged directions reuse
the same before captures in the after comparison. Gameplay is never ticked.

build.py --rendered assembles all-eight and changed-three horizontal GIFs
at8x100ms, plus a pause/next/previous/day/night frame inspector. BEFORE is
above AFTER. Page default is half display size to fit eight directions; the
scale button shows actual FHD size. The three-direction comparison uses actual
FHD-sized character crops by default. GIF palette quantization affects only
the review presentation, never the exported transparent PNGs.

Validation:24 exact mirror transforms and40 unchanged copies;64 original
before sources retain their hashes;128 native/runtime PNGs reproduce
byte-identically. Godot704 checks,0 failures, all176 capture contacts identical.
All four GIFs retain8 frames at100ms. Browser frame-next and night selection
checked; browser-review.png shows the actual visible result. No engine-wide
rerun for an isolated review. No gameplay integration, idle/tool modification,
queue mutation, automation or push. Await user's visual selection before
changing the accepted production/handoff source choice.
