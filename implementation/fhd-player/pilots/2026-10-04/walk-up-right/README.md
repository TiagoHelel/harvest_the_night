# Walk up-right: R5 motion review

The user approved down-right R5 on2026-10-04, then rejected up-right R3:
"reprovado, a perna troca sem movimento coerente". This direction remains
awaiting approval. Up-left and down-left have not started.

All character artwork was created with built-in ImageGen. The initial workflow
uses the sprite_generator fixed-hip construction concept, a rear diagonal
rotation master, opposite contacts and two four-frame transitions. Exact prompts,
raw originals, reference roles and rejection reasons are in generation.json.
Raw project copies are under assets/art_source/player-fhd/pilots/2026-10-04/
walk-up-right. Earlier contact, arm, head and material revisions are preserved.

The2026-10-05 correction addresses temporal continuity rather than merely having
different endpoint drawings. continuity-guide-r2.png shows continuous support
and recovery paths around fixed hips; it is a schematic, not character artwork.
Whole-sheet studies tracking-r2/r3/r4 did not satisfy the color/pose contract.
R3 incorrectly attaches a red boot to a cyan calf and repeats contact geometry;
R4 returns ordinary denim, so its colored-centroid analysis is invalid.
These studies are rejected and are not selected animation proof.

Passing poses3/7 and reaching poses4/8 were instead generated as two isolated
pairs. pack_continuous_poses.py cuts those whole sprites, uniformly calibrates
each pair to the source hat width, and packs them with four R3 source cells.
It never paints pixels or deforms joints. continuous-packing.json records all
cuts, scales and hashes. Derived materials-r4 had short intermediate shins;
materials-r5 is a targeted ImageGen calf-length correction. It preserves the
closer intermediate stances. Generated edits are not pixel-identical.

Selected source: materials-r5.png,1774x887, four columns by two rows.
export_preview.py retains R3's common scale0.15980024968789014 across all frames,
with fixed head-top/hat-center anchors, hard alpha128 and nearest sampling.
Eight80x80 frames have visible heights62-65px and hat widths31-32px. Standing
rotation reference has a30px brim and is labeled MASTER, not an approved idle.
No pose-specific body fitting or head enlargement is applied during export.

Review artifacts:

- up-diagonal-continuity-r5.gif: unchanged approved up beside up-right at the
  same integer2x proposed FHD display and4x detail, eight100ms frames.
- rejected-vs-revised-slow-r5.gif: rejected R3 on the left and selected R5 on
  the right, eight200ms frames. This is a before/after comparison, not a colored
  construction diagnostic. Historical leg-tracking-slow.gif now has the same
  explicitly labeled comparison for link compatibility.
- contact-sheet.png: rejected R3 above selected R5.
- index.html: normal playback, slow comparison and individual frame controls.
- browser-review-r5.png: actual browser review capture. Controls were checked
  at passing3, reaching4, opposite passing7 and wrapping8 back to1.
- Parent all-walk-directions-up-right-r5.gif: six directions; the five approved
  direction frame files remain unchanged.

Rebuild selected previews by running export_preview.py,
build_direction_comparison.py and the parent build_all_directions_preview.py.
pack_continuous_poses.py recreates the intermediate R4 source, not the generated
R5 calf edit. New artwork requires ImageGen and the saved prompts.

Export checks pass: eight unique frames, unclipped native canvases, binary alpha,
100ms normal timing and looping GIFs. Existing-game verify.py passed55checks,
0skips/0failures,526seconds (over its300second budget),7768headless asserts and
1006input cases. Sim1270427719 and data8148086 remain unchanged; see
verify-result.json. Engine checks do not approve this preview's anatomy/motion.
No runtime assets, simulation, collision, resolution or game queue changed.
The user's unrelated project.godot edits were preserved. Visual approval pending.
