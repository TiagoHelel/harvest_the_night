"""Keep bust identities while fitting the exact square native footprint."""
from pathlib import Path
import json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];jobs=[]
for kind in ['breaker','giant']:
    size=14 if kind=='giant' else 13;stem=kind+'-r2'
    details='Huge bald green head, pale small eyes, blood streaks, GREY stone plates tightly hugging shoulders. Square14wide14tall visible footprint, not broad horizontal shoulders; head dominates.' if kind=='giant' else 'Messy dark hair, rotten green face, torn RED shirt and a small iron sledgehammer head resting snugly on the shoulder. Hammer head must stay within the SAME13wide13tall visible square, never project sideways on a long shaft. Keep it as a recognizable thick grey hammer block partly over shoulder.'
    prompt=f'Use case: precise-object-edit. Image1 is the {kind} bust edit target. Correct ONLY the overly wide footprint that clips the16x16import: the COMPLETE visible head, neck, shoulders and any shoulder equipment together must form a SQUARE{size}wide{size}tall silhouette, not a landscape bust. Narrow shoulder reach and reveal more upper chest to gain height. One flat-cut bottom edge. '+details+' Preserve the exact enemy identity, camera turned to viewer LEFT, material colours and neutral upper-left light. Bold clear large flat planes and coloured dark outline. Image2 runtime enemy is IDENTITY/MATERIAL ONLY, never draw its full body. ONE complete unclipped bust, true transparent alpha and generous empty margins. No ground, shadow, halo, panels, border, labels, text, blur or gradients.\n'
    args={'prompt':prompt,'referenced_image_paths':[str(HERE/f'raw/{kind}-r1.png'),str(ROOT/f'sprites/enemies/{kind}_walk_0.png')],'transparent_background':True}
    for suffix,data in [('.request.json',json.dumps(args,indent=2)+'\n'),('.prompt.txt',prompt)]:
        path=HERE/f'raw/{stem}{suffix}';assert not path.exists();path.write_text(data,encoding='utf-8')
    jobs.append({'stem':stem,'revision':2,'folder':HERE.name,'args':args})
    with (HERE/'review-log.txt').open('a') as log:log.write('2026-10-07 | '+kind+'-r1 source over-wide: unchanged importer rejected canvas clipping. Regenerate square footprint, no output painting or non-uniform scaling.\n')
(HERE/'square-fix-jobs.json').write_text(json.dumps(jobs,indent=2)+'\n')
