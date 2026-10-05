# Walk down-right: corrected approval candidate

The user approved left and requested the next direction only. This task makes
DOWN-RIGHT; up-right, up-left and down-left await later approval turns.

Built-in ImageGen creates all farmer artwork. Approved down/right first-cell
crops establish identity and proportions. A standing diagonal master establishes
the front-right camera before animation. Temporary colors identify complete
anatomical chains: near RIGHT/red rooted at screen-left hip, far LEFT/cyan at
screen-right hip. Motion projects right and down from each leg's own fixed hip.

Earlier full eight-frame generations failed the visual ownership requirement.
The user rejected repeated forward-leg silhouettes even after both endpoint
displacements passed a color check. Those candidates and exact prompts remain
archived. Color displacement alone is insufficient to approve the gait.

The corrected approach follows sprite_generator's prepare_ranger_transition.py:
establish an isolated opposite contact, then animate two four-frame transitions
between the two contact references. Opposite contact shows near thigh running
back left from the left hip, and far thigh advancing right from the right hip.
Transition B initially invents an extra red shin; R2 removes it and corrects arm
counter-swing. pack_transitions.py losslessly cuts/reorders the two 2x2 sheets
into tracking-r4 (2508x1254). Source pixels are neither painted nor rescaled.

Selected materials-r5 addresses the user's remaining trouser-width and shoe
mismatch feedback. R4 restores the approved brown ankle-work-boot design,
including flat dark outsole, modest heel and small outer gold detail. Its
legs remained broad on native equal-scale inspection, so R5 further narrows
thighs/calves/cuffs and compacts the toe/foot contour, preserving the two
opposite leg contacts and both recovery poses. R3/R4 raw atlases, exact prompts,
R4 comparison input and intermediate validation remain archived.
Actual generated canvas1774x887 uses rounded quarter/half cuts. R5 retains the
R3 common scale0.1702127659574468 across all poses, so smaller boots cannot
increase the upper-body display scale. Hard alpha128 and nearest sampling
produce80x80 frames, visible heights62-64px and hat widths32-33px. Generated
edits still alter contour pixels; no exact upper-body pixel equality is claimed.
Native lower-trouser blue area averages191.125 instead of254.375; boots brown
area131.875 instead of161.75. Approved down values185.125/95 and right
246.375/160.75 differ due to pose/projection. These counts are review aids,
not anatomical equivalence; see lower-body-review.json. Earlier torso-area
measurements in body-volume-review.json refer to superseded R3, not R5.
Inspected all eight poses, both leg chains at contacts1/5 and recovery3/7.
The colored diagnostic precedes head/body calibration.

Exports: main down-diagonal-comparison.gif compares unchanged approved down with
candidate at integer2x proposed FHD display and4x detail, eight100ms frames;
idle-walk-down-right.gif; two-color versus denim leg-tracking-slow.gif at200ms;
native frames, transparent strip, contact sheet, posters and HTML frame controls.
The parent all-walk-directions.gif and versioned leg-boots-r5 copy show
all five current walks at the same scale; four approved directions are unchanged.
Inspected all poses, opposite contacts, both passing poses and browser display.
Checks cover both forward/back colored displacements, lifted recovery3/7 and
separate forward-foot positions at opposite contacts. These measurements assist
review, not anatomical proof. Material/head edits are not pixel-identical:
normalized native silhouette IoU0.80293, explicitly documented in validation.

Reproduce: run create_guide.py for the base schematic, pack_transitions.py for
tracking-r4, check_leg_tracking.py, export_preview.py and
build_direction_comparison.py. Raw ImageGen masters and exact prompts are saved;
generating new artwork remains a separate creative step using the saved prompts.

The user approved selected DOWN-RIGHT R5 on2026-10-04 ("aprovado, proximo"). No runtime integration,
game code, project resolution or simulation changes. No engine verification suite
was rerun for this isolated preview and no in-game playback is claimed.
