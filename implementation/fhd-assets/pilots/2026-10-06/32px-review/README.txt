Non-character asset gallery at the selected32px farmer pixel density.

320 existing runtime PNGs:166 buildings/defenses,27 props,10 interior,
14 crops,28 terrain,26 effects including the separate contact shadow,
and49 interface assets. Farmer poses and all enemies are excluded.
States, upgrades, connected pieces, structural slices and atlas are included.

No new raster generation or destructive conversion is needed. Current world
assets already draw at one logical pixel per authored pixel: the4x FHD
viewport expansion matches the selected32px farmer's4 physical pixels per
detail pixel.32px is not a universal32x32 canvas. Larger objects retain their
proportions. The gallery is unlit source art; procedural ambient shaders are
not simulated. No animation or growth-stage timing is invented.

build.py inventories the runtime files and recipe provenance, generates
index.html and contract.json, and never writes production PNGs or metadata.
The browser provides category/search controls and native1x/overview2x/FHD4x
nearest display. Sprite links open the original transparent PNGs. No palette
changes, filtering blur, source downsampling or game integration occur.

Validation:320 unique existing image paths,320 original SHA256 values
unchanged, integer4x display dimensions, explicit farmer/enemy exclusion,
and byte-identical page/contract regeneration. Browser category filtering,
search(tree gives2 files),2x display then4x restoration were checked.
browser-review.png records visible tree/animal/object art. checks.json stores
inventory validation. No engine-wide gameplay rerun for this isolated HTML
review; concurrent user core/project changes are preserved.
