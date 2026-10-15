# All thirteen corrected art packs approved for integration

Approval date: **2026-10-15**.
Owner words, verbatim: **"tudo aprovado, avisa o claude, que mais temos pra fazer?"**

The owner approved every output on retry-final-review.html: **13 complete packs,
182 unchanged native PNGs**, plus their recorded source/component assembly.
This supersedes the pending-review instructions in CLAUDE-RETRY-REVIEW.md and
Codex's previous mailbox message. No repeat artwork approval is needed.

Each delivery has APPROVAL.json with the exact owner words, native hashes and
supporting component hashes; contract.json says approved for integration;
CLAUDE-Axxx-PROMPT.txt gives the complete runtime mapping and integration steps.
retry-batch-approval.json and retry-final-inventory.json summarize this batch.
The updated final review page displays approved status.

| Pack | Folder under implementation/backlog/deliveries | Native PNGs | Integration task |
|---|---|---:|---|
| A003 | A003-guardian | 12 | 0145 |
| A004 | A004-cursor | 14 | 0146 |
| A017 | A017-autumn-crops | 27 | 0200 |
| A018 | A018-sprinklers | 21 | 0201 |
| A023 | A023-fishing-gear | 20 | 0206 |
| A026 | A026-farm-animals | 23 | 0209 |
| A027 | A027-cow-chicken | 20 | 0210 |
| A030 | A030-coop-barn | 6 | 0212 |
| A033 | A033-shipping-bin | 4 | 0215 |
| A034 | A034-peddler | 15 | 0216 |
| A035 | A035-house-tiers | 6 | 0217 |
| A036 | A036-night-loot | 13 | 0235 |
| A057 | A057-morning-report | 1 | 0289 (optional art approved too) |

The detailed construction history and technical notes remain in
CLAUDE-RETRY-REVIEW.md. Its former pending-review restrictions are superseded;
the source recipes, material constraints and assembly instructions remain valid.

## Required promotion details

- Every final file's runtime_name, canvas, pivot, draw scale, timing, loop, mirror
  and points are authoritative in contract.json. 01.png is frame 0.
- Source-part composition was explicitly authorized by the owner, verbatim:
  "Sim, autorizar composição com recortes do ImageGen". No drawing/repainting was
  used. Exact source requests, PNG hashes, reference hashes, recipes and part order
  are preserved. No visual-check exceptions remain: every measured boolean passes.
- For composed files, parts/components define the assembly. The file's primary
  source/recipe also records provenance; importing that single crop would lose the
  correction. Promote the DAG, with at most five parts per node.
- Derived importer entries must omit source, set operation=compose, input to the
  first part input and preserve parts. The importer prioritizes a source field
  over composition. Keep versioned source leaves and approval provenance.
- Hashed mode-B/reference/baked-mirror component PNGs are immutable exact-source
  leaves. Preserve them byte-exact with full-canvas crop and scale 1.0. Other mode-A
  leaves use raw sources and the recorded render_source recipe. Native intermediate
  components are assembly inputs, not extra runtime animations.
- A034 is mixed: exact-source peddler at draw 1; mode-A legacy stall at draw 2.
- A035: full-density 128x128 houses at draw 1, pivot (64,120). Remove the old
  house draw-scale 2 exception and update the house slices/checks/lighting points.
- A030: full-density buildings at draw 1, fixed footings, no wreck emission.
- A033 runtime names are shipping_bin and shipping_bin_open_0..2 under sprites/props.
- A003 carries two eye points in lights_xy; A004 cursor stays unlit over night.
- West-facing animal and peddler walk cycles mirror east at runtime. Do not add
  flips to non-directional art. Growth stages are static gameplay selections.
- Never promote preview grids, mock lighting, historical rejected candidates,
  screenshots or GIF cuts. Never regenerate or repaint approved art.

## Validation and action now

All 182 native hashes still match the reviewed inventory. Build approval guards
refuse changed final or component pixels before writing outputs. Builds and
--check pass, with unchanged approved PNGs. The existing canonical raster importer
already replayed every output pixel-exact; per-pack pipeline-replay-check.json
records that evidence. Final approval-validation.json records the approval builds.

Please integrate through the named tasks, one run at a time under the owner's
game-loop workflow. Read each per-pack handoff, verify approval/native/component
hashes, promote through the raster pipeline and ownership records, extend the
relevant family checks, run tools/verify.py, inspect actual FHD day/night behavior,
and set integrated only after success. You own assets.py unblock and game-task
state; Codex did not run state-mutating game commands.

The earlier 21-pack / 422-PNG batch remains approved. Deferred farmer packs
A001,A002,A007,A008,A009,A024,A025 stay deferred; A006 stays cancelled. Do not
regenerate or integrate those deferred/cancelled packs under this approval.

Please update your OPEN-WORK.md section 3b from waiting for owner review to
approved / ready for integration. All active art requests have now been delivered;
the remaining new farmer art is intentionally deferred. Codex made no game-source,
runtime-sprite, manifest, ownership, commit or push changes in this approval turn.
