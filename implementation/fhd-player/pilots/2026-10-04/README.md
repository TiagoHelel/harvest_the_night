# Farmer and clothing-layer design pilot — 2026-10-04

User request: create an original farmer with a simple Stardew Valley-like
pixel-art direction, and explain whether individual clothes require sprites.

This is a character design preview. It does not replace the approved runtime
character or modify the existing animation pipeline. Generation uses built-in
ImageGen and the exact prompt in character-r1.prompt.txt. The requested logical
pixel dimensions are art direction, not a verified native production contract.

Clothing can be authored as aligned transparent animation layers: body, pants,
shirt, hair and hat, with tools/accessories separately when needed. Each distinct
garment needs its own artwork for the relevant poses and directions; the game
composes selected pieces instead of requiring every outfit combination to be
drawn again. Colour-only variants can reuse a palette mask. Rigid hats can reuse
directional images with frame-specific head offsets where the pose permits it.

All layers must share the same canvas, ground pivot, frame sequence and body
proportions. Hands, sleeves and held tools need explicit occlusion order for
each direction/activity. Adding clothing therefore requires layer support in
the renderer as well as clothing art; swapping an arbitrary finished image
does not provide a wardrobe system.

Current src/ui/player_view.gd assigns one complete character texture per frame
to the Body Sprite2D. It has no interchangeable clothing layers yet. This pilot
does not implement that system or generate clothing animation sheets.

Saved master: assets/art_source/player-fhd/pilots/2026-10-04/character-r1.png.
Visual review: complete standing front pose on transparent alpha, slimmer and
longer body, small hands/boots, distinct garment boundaries. This large source
master still needs native-grid conversion and small-scale review before any
runtime adoption. The current request produces one design image, not a full
animation or wearable clothing set. No game code, runtime sprites or manifests
were changed; game verification/export was not rerun for this isolated preview.
