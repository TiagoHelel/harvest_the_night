# Common walker gait correction

Follow-up to the user's 2026-10-02 report that zombies do not look like they
are walking. The original visual sign-off checked distinct drawings and sparse
captures, which was insufficient evidence of convincing continuous motion.

This correction replaces only the common walker's four walk drawings and the
exact legacy alias for frame 2. The accepted identity master, original walk
source, attack/death art, other enemy families, project resolution, animation
observer and simulation remain unchanged. It is a targeted gait correction,
not a regeneration of the completed sprite catalogue.

Built-in ImageGen produced one new transparent strip using the existing walker
master as its identity reference. The exact prompt and call are recorded in
generation/walker-walk-fix.prompt.txt and walker-walk-fix-call.json. The raw
source is assets/art_source/enemies/walker/walk-v2.png (SHA-256
58a56d3e7189e61fe2e57ec812f6f3fa27a2bc3a95d894673cf16f806ee12c5d).
The old source remains preserved at walker/walk.png.

The deterministic importer measures the four bodies using genuinely empty
transparent column gutters. All poses share scale 29/645 and the existing
64x48 canvas and ground pivot (32,44). No pixels are painted in Python. The
native comparison shows wider contact poses, narrower passing poses, more
visible lifted boots and less dense body shapes. The four-frame sequence still
uses the existing distance-based cadence: one full cycle per 16-pixel tile,
about 0.67 seconds for the normal walker at 1x. Pausing remains tick-driven.

New --walk-loop showcase mode records 60 consecutive real core ticks during
day and night, rather than sparse coverage stills. Before and after each pass
completed 1,572 checks with zero failures, including byte comparisons against
unobserved core movement. Original viewport captures are 480x270 in
implementation/shots/sprites/walker-walk-fix/{before,after}/. playback.py makes
30-Hz native before/after GIFs and filmstrips without altering sprite pixels.

Viewed the full native day/night captures, the native and 3x source comparison,
and all 120 consecutive replacement samples in the two filmstrips. Contact
poses now visibly separate the feet from the narrow passing poses; ground
contact stays fixed. Night lighting still reduces small limb contrast. Near
and far leg identity remains subtle at 29 pixels; this is not a claim of a
fully polished four-direction animation. Runner/tank/breaker/giant art is
unchanged and this review does not sign off new gait quality for those types.

Reproduction: prepare.py reads preserved before-entries.json and builds the
candidate recipes/comparison; install.py applies only four recipes;
python tools/import_art.py installs exactly five runtime PNG changes. Render
with python tools/show_art.py --enemies --walk-loop --out=<capture folder>.
Run playback.py with the saved before/after captures to rebuild the clips.

Full verification: 52 passed, zero skipped, zero failed in 472 seconds (the
soft 300-second budget is exceeded; exit code is zero). 6,646 core assertions,
982 input cases and exports pass. Sim hash 1961000123 and data hash 407837701
remain unchanged. See verify.log and the appended progress journal.
