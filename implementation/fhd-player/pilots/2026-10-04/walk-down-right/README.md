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

Selected materials-r2 restores denim/leather with consistent lighter near leg
and shadowed far leg, and calibrates the uniform head size to approved directions.
Actual generated canvas is 1774x887; export uses rounded quarter/half cuts in
transparent gutters instead of assuming exact requested dimensions. One common
scale per source family applies across all eight poses; no per-pose body fitting.
Hard alpha >=128 and nearest sampling yield 80x80 frame canvases, visible heights
62-65px and hat regions31-32px (standing diagonal hat31px). The colored diagnostic
precedes head calibration and therefore has a different head/body ratio.

Exports: main down-diagonal-comparison.gif compares unchanged approved down with
candidate at integer2x proposed FHD display and4x detail, eight100ms frames;
idle-walk-down-right.gif; two-color versus denim leg-tracking-slow.gif at200ms;
native frames, transparent strip, contact sheet, posters and HTML frame controls.
Inspected all poses, opposite contacts, both passing poses and browser display.
Checks cover both forward/back colored displacements, lifted recovery3/7 and
separate forward-foot positions at opposite contacts. These measurements assist
review, not anatomical proof. Material/head edits are not pixel-identical:
normalized native silhouette IoU0.81532, explicitly documented in validation.

Reproduce: run create_guide.py for the base schematic, pack_transitions.py for
tracking-r4, check_leg_tracking.py, export_preview.py and
build_direction_comparison.py. Raw ImageGen masters and exact prompts are saved;
generating new artwork remains a separate creative step using the saved prompts.

Await explicit user approval of the corrected DOWN-RIGHT. No runtime integration,
game code, project resolution or simulation changes. No engine verification suite
was rerun for this isolated preview and no in-game playback is claimed.
