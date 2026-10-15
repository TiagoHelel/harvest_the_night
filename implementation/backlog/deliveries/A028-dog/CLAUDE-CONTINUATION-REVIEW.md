APPROVAL UPDATE / 2026-10-14: All 21 deliveries are complete and approved (422 PNGs). The 167 continuation additions are now approved; no missing files remain in this batch. Read CLAUDE-CONTINUATION-APPROVED.md and each current per-pack handoff. Pending-review instructions below are historical.

# Missing-art continuation: candidate delivery complete, new approval pending

Owner continuation on 2026-10-14: “entao bora continuar essa poha”. This resumes the six incomplete deliveries of the 21-pack batch. It does not regenerate or revoke any previously approved PNG.

The six packs now contain 187 native PNGs: 20 previously approved PNGs preserved byte-for-byte and 167 new candidates. The 15 other complete packs retain their 235 approved PNGs. Therefore the original 21-pack batch has 422 candidate/approved PNGs and no missing file; 255 remain approved, and the 167 additions require a new owner review. This does not say every visual issue is resolved or that the additions are integrated.

Review: `implementation/backlog/deliveries/A028-dog/continuation-final-review.html`.
Exact new-file inventory and hashes: `implementation/backlog/deliveries/A028-dog/continuation-final-inventory.json`.
The earlier all-packs-review.html now links this additions-only page and preserves the original approval information.

| Pack | Existing approved | New pending review | Total | Game integration task |
|---|---:|---:|---:|---|
| A028 dog | 2 sitting frames | 18 | 20 | 0245 |
| A040 garlic braid | 1 fresh state | 2 | 3 | 0239 |
| A042 electric fence | 3 zap frames | 39 | 42 | 0241 |
| A043 hardwood and sandbag walls | 0 | 78 | 78 | 0242 |
| A045 powers and weapon icons | 0 | 22 | 22 | 0244 |
| A054 Winter Lord | 14 | 8 | 22 | 0268 |

## What was added

- A028: wag2, walk4, bark3, sleep2, run4, bite3. All are west-facing on 40x32, pivot (20,30), draw1; runtime mirrors east. The original sitting2 outputs are unchanged. Bite frame1 has the measured opaque jaw point `bite_xy: [9,21]`; animation metadata carries the same point. The preview compares the dog with farmer/cow/hen and aligns its west-facing bite against the walker's shin.
- A040: wilted and spent, retaining the fresh state's canvas/pivot/family source scale. The fresh PNG and its earlier accepted width difference remain unchanged.
- A042: six modules, one wreck and 32 joined masks. The existing zap3 is unchanged. Whole/hurt modules share one source scale. Joins follow ART-CONTRACT 2.3 in N,W,E,S,post order. The owner-authorized 27px vertical envelope resolves the shared source-ratio geometry conflict. Thin wires land on rows13/17; their lowest opaque row17 differs from the literal span-row19 check and remains a new review issue.
- A043: six hardwood modules + wreck +32 masks, and the same39 files for sandbags. All measured geometry, source/provenance and build checks pass. Each family shares one source scale. The earlier owner-authorized27px vertical envelope is retained. Repeatable horizontal source beams are cropped at that scale to one tile length; the hardwood lower face is cropped to the eight-pixel seam height. There is no per-piece scaling or native pixel repaint.
- A045: eleven independent ImageGen sources, each cut as16x16/pivot8,8 and10x10/pivot5,5. Both cuts use the same alpha bounds and scales14/max and8/max. Subjects: farm_bell,call_dog,emergency_repair,decoy,beehive,catapult,garlic_braid,searchlight,electric_fence,wall_2,sandbag_wall. Zombie bait remains A037's. The owner's candidate-reference exception is recorded and does not approve the referenced candidates.
- A054: walk4 and cast4 only. The other14 outputs are unchanged. Cast heights46/52/56/56 fit the58px ceiling at the retained body scale. The earlier owner-accepted death_never_grows=false measurement remains honest.

## Review boundaries and remaining visual concerns

All six builds were run twice and checked for deterministic output. Alpha, palettes, nonempty frames, canvas/pivot metadata, source/reference hashes and original approved-file hashes pass. False visual measurements were not rewritten as true.

A028 still has new false motion invariants: `wag_only_tail_changes`, `bark_paws_stationary`, `sleep_head_paws_stationary`. Three tail corrections were compared; the best source still changes14 native pixels outside the tail region. Do not treat this as exact stationary-body animation. Judge the walk/run cycles and the listed residual differences in the final review.

A042 still has the new `electric_fence_post_span_row20=false` difference because the thin wires have no ground foot; the post itself ends on row19, and wire rows13/17 preserve the mixed-fence seam. This deviation awaits the owner's judgment. The earlier zap warm-speck difference is already accepted; do not ask for that approval again.

A040's fresh width and A054's death height are existing accepted differences, not new failures. A043 and A045 have no false measured checks. None of this auto-approves any addition.

## What Claude should do now

Continue the already authorized integrations of the15 complete approved packs. Use their APPROVAL.json and actual current game-task state; do not request the same visual approval again.

For these six packs, read `contract.json` (`approved_existing_files` and `pending_review_files`) and the additions inventory. Preserve the previously approved subset. Wait for explicit owner approval of the additions before promoting them or marking the full pack approved/integrated. Codex has left all six packs in `review`, not `blocked` and not `approved`.

After approval, record the exact owner words and exact new SHA-256 values in APPROVAL.json, then complete the per-pack promotion/mapping handoff. Every file's authoritative runtime filename, timing, mirror and points is already in contract.json. For composed barriers, promote the raster modules and create importer `compose` entries from `joins.parts`; the composed file's source field records provenance of the modules and is not a direct raw crop recipe. Keep the exact2.3 slice/paste order.

All art was made with built-in ImageGen. Exact prompts, calls, hashes and crop/scale recipes are in each pack's raw folder. Unselected new returns are archived under rejected with reasons; their original call arguments are intact, and call input_images use archived_path where a reference moved. Never repaint native pixels or discard the approved outputs.

No runtime source, sprite, raster manifest, ownership file, game-task state, commit or push was changed by this continuation. Claude still owns game-task state, assets.py unblock and integration verification. The deferred farmer packs and cancelled run pack were not touched. Older art packs outside this21-pack batch were not reopened by this delivery.
