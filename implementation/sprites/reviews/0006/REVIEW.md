# 0006 — Player reactions and ground shadow

Accepted on 2026-10-01. All five assets are saved and integrated. This review
closes only task 0006; the next art task is 0007.

## Sources and deterministic contract

Built-in ImageGen produced six actual outputs: four accepted farmer reactions,
one accepted contact shadow, and one rejected initial bang. The bang received
one targeted revision because the first native reduction joined its outline
and dot, making the punctuation ambiguous. The revised straight stem and
separate dot passed. Other assets needed no revisions; none exceeded the
three-revision limit. No API/CLI fallback or code-drawn replacement was used.

Accepted originals are `assets/art_source/player/react_{bang,question,note,heart}.png`
and `assets/art_source/player/shadow.png`. The rejected bang is preserved as
`assets/art_source/player/candidates/react_bang-r0.png`. Exact prompts, actual
returned file paths, references, decisions and SHA-256 values are in
`implementation/sprites/generation/0006-generations.json` and its six individual
call/prompt records. Saved source copies were checked byte-for-byte against
the actual tool files. The approved farmer master, locomotion/work sources
and owner's original player sheet were preserved.

`measured-contract.json` freezes measured alpha components, source crops,
boot centers, uniform scales, source hashes and output hashes. Each reaction
uses one source-proportional reduction based on its body height: 30 native
pixels, a 48x48 canvas, feet (24,44), shared palette and binary alpha at 128.
The four complete runtime PNG paths remain unchanged. Their measured native
glyph rectangles are bang (33,11,3,8), question (32,11,5,7), note (34,11,6,8)
and heart (31,11,6,6). These are actual measurements, not the approximate
symbol dimensions requested in the prompts.

The shadow has a 20x8 canvas, anchor (10,4), visible bounds (1,3)-(19,6), one
opaque palette color and clean alpha. Its 18x3 visible ellipse intentionally
preserves the generated source's flat proportions through one uniform scale;
it was not stretched vertically to fill the canvas. Existing view opacity
0.42 and placement (0,-1) remain. It is a separate shared ground asset, not
part of the player's 48x48 pose metadata.

Ownership now totals 93 raster, zero player-sheet and 155 ASCII outputs,
or 248 exclusively owned runtime PNGs. All 77 player pose frames are raster.
The legacy cutter writes zero pose PNGs while still checking all merged
counts, canvas and feet metadata. The importer rejects glyph rectangles
outside the canvas, over body pixels, or missing any glyph pixels.

## Integration and criteria

| Criterion | Result and evidence |
| --- | --- |
| Four existing reactions in the approved style | PASS: hat, face, overalls, body scale and planted boots match the accepted farmer; distinct straight bang, hooked question, musical note and red heart. Final source alpha and native sheets were opened on light, dark and checker backgrounds. |
| Crop-ready and fishing events | PASS: actual Farming.tick creates crop-ready/note; actual Fishing.tick creates bite/bang after work ends. Main `react.png` also shows crop-ready through the game's regular view. |
| Hurt/night and destruction cases | PASS: actual Phases.begin_night produces bang; actual Farm.damage destroys a fence and produces question with the existing priority. No new player hurt rule or reaction event was invented. |
| Existing selection, priority and lifetime | PASS: PlayerArt.reaction_pose and Reactions.now still select the art. Walking and all twelve real work verbs suppress all four kinds; idle can resume an unexpired reaction, then the existing 45-tick lifetime returns to normal idle. Heart remains available through the existing reaction kind with no invented automatic trigger. |
| Glyphs fit the viewport | PASS: all four kinds at all four extreme map corners retain complete glyphs within a two-pixel viewport margin. Only the glyph is shifted; ground contact, body canvas and y-sorting remain fixed. Existing camera clipping of the body at extreme map boundaries is unchanged. These bounds tests use the actual World/PlayerView; they do not assert a new HUD exclusion region. |
| Day, dusk and night | PASS: all four symbols and farmer silhouettes were inspected under actual settled day/dusk/night world lighting at native and nearest 3x. Night keeps the existing dim violet world tint; symbols remain separate and identifiable. Full Main captures also cover existing effects and lighting. |
| Work stays unobscured | PASS: real timed/instant Player.tick fixtures exercise chop, mine, till, plant, water, fish, reel, harvest, craft, trade, collect and repair. Bubble visibility and body mask reset during work, recovery and walking. Existing tree/station occlusion remains ordinary ground sorting. |
| No duplicate symbol, halo or painted shadow | PASS: four real-render comparisons show split body/glyph pixels equal the combined committed PNG pixel-for-pixel away from viewport boundaries. The mask discards only the source-owned glyph region; all other shader pixels remain untouched. |
| Contact shadow | PASS: farmer, tree and walker use one shared source with their existing placements. Actual shadow-visible/hidden renderer comparison changes 23 exposed ground pixels around the farmer, with no shifted boots or oversized halo. |
| View-only behavior | PASS: complete var_to_bytes state is unchanged by view updates, including reaction state that the simulation hash does not cover. Core event producers run outside those read-only comparisons. Core rules, balance, save format and simulation/data hash baselines remain unchanged. |

## Verification and visual evidence

Full `tools/verify.py`: **28 passed, zero skipped/failed in 177 s**. This includes
105 parsed scripts, 6609 headless assertions, 980 input cases, performance,
Windows/Web exports, placement 476, locomotion 468, work 3749 and reactions 690
checks. Simulation hash **1961000123** and data hash **407837701** are unchanged.
Raster verification checks 93 outputs and metadata with zero writes. Logs:
`verify-full.log`, `reaction-check.log`, `reaction-capture.log`, `captures.log`
and `fault-check.log` in this folder.

The real Compatibility/OpenGL renderer passes **828 reaction checks**, including
the four split-pixel comparisons and the visible shadow comparison. The
headless 690 checks validate state/placement but do not claim renderer proof.
`fault-probes.json` and `fault-check.log` record **27 fault/rebuild probes**:
all expected failures occurred, deterministic rebuilds changed no bytes, and
all deliberate corruption was restored.

All **70 actual 480x270 Godot captures** were opened and reviewed at native
size and nearest 3x: 64 reaction fixtures in
`implementation/shots/sprites/0006/reactions/`, plus noon, dusk, wave, result,
tech and react in its parent. `captures-00` through `captures-17` collect
them; the 3x pages were viewed at original 2880x1728 resolution. Pages 00-03
cover corners, 04 actual events, 05-11 lifetime/facings/lighting/shadows,
11-12 split-render equivalence, 12-15 walking/work suppression, and 16-17 Main.
`frame-review.json` lists every capture. Five final source-alpha pages and
all three native/nearest-3x alpha contact sheets were also opened and reviewed
after the bang revision.

Ground noise and existing night bloom remain follow-ups for 0007 and 0019.
Tree/station overlap remains for their respective art tasks. No outstanding
0006 visual or verification gate remains.
