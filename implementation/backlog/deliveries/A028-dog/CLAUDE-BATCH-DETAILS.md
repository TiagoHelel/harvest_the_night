APPROVAL UPDATE / 2026-10-14: All 21 deliveries are complete and approved (422 PNGs). The 167 continuation additions are now approved; no missing files remain in this batch. Read CLAUDE-CONTINUATION-APPROVED.md and each current per-pack handoff. Pending-review instructions below are historical.

CONTINUATION UPDATE / 2026-10-14: Missing outputs have now been generated as review candidates. Previous approvals are preserved, not extended. Read CLAUDE-CONTINUATION-REVIEW.md for current counts and pending-review boundaries; earlier missing-output notes below are historical.

# Detailed handoff: owner-approved batch of 21 art packs

Recorded on 2026-10-14. This is the corrected integration instruction, superseding the earlier blanket advice to wait or ignore the batch.

The owner approved every image displayed in the batch review. Approval records exist for all 19 nonempty deliveries. Fifteen complete deliveries contain 235 approved native PNGs; four partial deliveries contain 20 approved PNGs. The approved images, source crops, scales, palettes, animation order and timing were preserved. No game code or game task status was changed by Codex.

Authoritative index: `implementation/backlog/deliveries/A028-dog/batch-approval.json`. Review page: `implementation/backlog/deliveries/A028-dog/all-packs-review.html`. Consolidated prompt: `implementation/backlog/deliveries/A028-dog/CLAUDE-BATCH-PROMPT.txt`. The per-pack `APPROVAL.json`, `contract.json` and `CLAUDE-Axxx-PROMPT.txt` are the actual integration handoffs.

## Complete deliveries ready to integrate

| Pack | Game task | Approved PNGs | Authoritative handoff |
| --- | --- | ---: | --- |
| A037 - The scarecrow decoy and zombie bait | 0236 | 12 | `implementation/backlog/deliveries/A037-decoy/CLAUDE-A037-PROMPT.txt` |
| A038 - The beehive | 0237 | 11 | `implementation/backlog/deliveries/A038-beehive/CLAUDE-A038-PROMPT.txt` |
| A039 - The pumpkin catapult | 0238 | 19 | `implementation/backlog/deliveries/A039-catapult/CLAUDE-A039-PROMPT.txt` |
| A041 - The searchlight | 0240 | 8 | `implementation/backlog/deliveries/A041-searchlight/CLAUDE-A041-PROMPT.txt` |
| A044 - Day tarps over the defences | 0243 | 12 | `implementation/backlog/deliveries/A044-tarps/CLAUDE-A044-PROMPT.txt` |
| A046 - The spitter | 0260 | 18 | `implementation/backlog/deliveries/A046-spitter/CLAUDE-A046-PROMPT.txt` |
| A047 - The rat swarm | 0261 | 12 | `implementation/backlog/deliveries/A047-rats/CLAUDE-A047-PROMPT.txt` |
| A048 - The crow | 0262 | 14 | `implementation/backlog/deliveries/A048-crow/CLAUDE-A048-PROMPT.txt` |
| A049 - The digger | 0263 | 24 | `implementation/backlog/deliveries/A049-digger/CLAUDE-A049-PROMPT.txt` |
| A050 - The frost zombie | 0264 | 17 | `implementation/backlog/deliveries/A050-frost-zombie/CLAUDE-A050-PROMPT.txt` |
| A051 - The wraith | 0265 | 13 | `implementation/backlog/deliveries/A051-wraith/CLAUDE-A051-PROMPT.txt` |
| A052 - The Harvester | 0266 | 25 | `implementation/backlog/deliveries/A052-harvester/CLAUDE-A052-PROMPT.txt` |
| A053 - The Scarecrow King | 0267 | 18 | `implementation/backlog/deliveries/A053-scarecrow-king/CLAUDE-A053-PROMPT.txt` |
| A055 - Fog, Rain and the Blood Moon | 0269 | 6 | `implementation/backlog/deliveries/A055-event-icons/CLAUDE-A055-PROMPT.txt` |
| A056 - The collection book, trophies and badges | 0288 | 26 | `implementation/backlog/deliveries/A056-collections/CLAUDE-A056-PROMPT.txt` |

A050 is the frost zombie: all 17 required files are approved, ready for game task 0264. It must not be held back by the unrelated A043 regeneration failure.

## Owner-accepted visual differences

The original measured QA results are retained in checks.json. A false visual comparison is not a new rejection: the exact reviewed output is explicitly accepted in APPROVAL.json under accepted_visual_checks and in contract.json deviations. Do not silently turn those measurements true, regenerate the accepted images, or ask for the same visual approval again. Structural file presence, SHA-256 integrity, alpha, canvas/pivot, source recipe reproducibility and actual integration behavior still need to be correct.

| Pack | Recorded visual differences accepted with the displayed artwork |
| --- | --- |
| A037 | `decoy_hurt_sway_top_shift_ok` |
| A038 | `beehive_2_fire_body_exact`, `beehive_fire_body_exact` |
| A039 | `catapult_2_stationary_base_exact`, `catapult_3_stationary_base_exact`, `catapult_3_whole_dimensions`, `catapult_3_wreck_inside_whole`, `catapult_stationary_base_exact`, `catapult_wreck_inside_whole` |
| A041 | `searchlight_2_only_lens_changes`, `searchlight_2_wreck_inside_whole`, `searchlight_only_lens_changes` |
| A044 | `tarp_tall_covered_dimensions`, `tarp_tall_lower_half_revealed` |
| A046 | `walk_leg_alternation_review` |
| A049 | `burrow_meets_mound`, `emerge_matches_walk_pose`, `mixed_body_clod_palette_verified`, `walk_leg_alternation_review` |
| A052 | `head_lamps_bone` |
| A053 | `icon_eyes_bone_matte` |
| A056 | `badge_crop_bounds_within_2_percent`, `raw_source_count_contract_matches` |

For A056, the detailed source list requires 23 sources although the specification summary says 22; the recorded delivery contains all 26 required output PNGs. The source-count discrepancy and badge crop alignment differences are documented and accepted. Existing reference-only exceptions remain in authorization.json; this does not approve unrelated source packs or invent missing frames.

## Partial deliveries: approved images remain approved

| Pack / game task | Approved now | Still missing |
| --- | --- | --- |
| A028 / 0245 | Two sitting frames, dog_sit_0 and dog_sit_1 | 18 frames: wag 2, walk 4, bark 3, sleep 2, run 4, bite 3 |
| A040 / 0239 | Fresh garlic braid, garlic_braid | Wilted and spent states: 2 PNGs |
| A042 / 0241 | zap_0, zap_1, zap_2 | 6 whole/hurt fence modules, 1 wreck, and 32 composed connected masks: 39 PNGs |
| A054 / 0268 | Master pose, attack, death, ice-shard effects, and head: 14 PNGs | Four walk frames and four cast frames: 8 PNGs |

Each partial folder has APPROVAL.json listing the exact approved subset and missing_outputs listing the missing runtime names. Its candidate-contract.json supplies recipes for the approved subset. The full game task stays gated only because the complete output set is absent. Preserve approved files and existing placeholders for missing states. Do not mark these four packs integrated prematurely. Codex remains responsible for generating missing art.

## Empty deliveries still awaiting art

- A043 / game task 0242: 0/78 reviewed output PNGs. Its latest raw wood generation attempts remain failed diagnostics; no sandbag family or complete connected masks were delivered. The owner authorized a 27px final vertical module and separate source sheets at one family scale; those decisions are in raw/export-plan.json and review-log.txt.
- A045 / game task 0244: 0/22 reviewed output PNGs. Candidate world-art references were authorized for reference only. No icon images were generated in the retry round.

These two packages had no images in the reviewed pages, so approval of displayed artwork cannot supply their missing files. Their absence does not withdraw approval from any other delivery.

## Claude actions now

1. Read the consolidated prompt and per-pack handoffs, then use your game runner to take eligible integration tasks. The game loop remains yours; Codex did not claim game tasks or run assets.py unblock. Preserve unrelated owner-decision blockers and deferred farmer packs.
2. Verify every native PNG against APPROVAL.json and contract.json. Use only the contract-listed raw ImageGen sources and exact raster recipes. Do not cut sprites from the review HTML, preview strips, GIFs or screenshots. Preserve timing, points, frame indices and runtime/baked mirror behavior.
3. Promote versioned raw sources, manifests and ownership through the project raster pipeline as each game task requires. Add the required runtime bindings and aliases. Run tools/import_art.py and python tools/verify.py; inspect actual FHD day/night captures.
4. If a real integration defect or an unlisted/missing file appears, report the exact pack, file and check. The historical owner-accepted visual comparisons alone are not a reason to regenerate art or ask the owner for another approval.
5. After a pack is actually integrated and verified, set its status to integrated through assets.py. Run your own dependency unblocking as the game loop permits. Keep partial and empty packs gated until their remaining outputs exist.
6. Keep OPEN-WORK.md and your own to-codex.md mailbox current with taking/done/blocked game task notices. No commit or push authorization was added by this art handoff.

Validation already completed by Codex: source/render hash checks, deterministic rebuild checks, exact approved PNG hashes, page links and assets.py check (57 packs, zero queue/index problems). Accepted visual failures are preserved as measurements, not presented as passing tests.
