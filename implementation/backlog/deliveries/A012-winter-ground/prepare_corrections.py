"""Record targeted source revisions after native seam/density measurements."""
from pathlib import Path
import json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];jobs=[]
fixes={
 'path_winter':'Replace the dominant cream snow BASE with packed dirty-snow colour EXACT RGB184,174,154(#b8ae9a), on at least230of256nativepixels. Keep all borders uniform this SAME beige. Retain onlyTWOsoft joined interior dirtysoil clusters,4-6nativepixels each, all nonbase clusters at least2pixels. NO dots, stray pixels or large cream patches. This is the darker trodden path, not the grass snow field.',
 'soil_winter':'Flatten the busy ground into a dominant EXACT soil RGB122,88,56(#7a5838) covering at least210of256nativepixels. ALLfour border rows andcolumns exactly this flat soil colour. Retain onlyTWOsmall joined interior cream dusting clusters of6-10nativepixels each, with at mostONEdarkbrown cluster4-6nativepixels. No isolated1pix dots, no other scattered texture. Opposite borders identical, whole tileopaque.',
 'tilled_winter':'Make all horizontal rows PERFECTLY UNIFORM left-to-right, with absolutely NO speckles, breaks or variable shading along a row. Sixteen native rows: row0dark soil RGB92,66,42; row1cream RGB232,224,207; rows2,3dark soil; rows4,5cream; rows6,7darksoil; rows8,9cream; rows10,11darksoil; rows12,13cream; rows14,15darksoil. EXACTLY these flat16row bands, evenly spaced. Row0equals15, column0equals15. Preserve whole1254square framing, four furrows; no perspective, objects or gradients.',
 'edge_n_winter':'Correct ONLY the boundary endpoint COLOURS. Native row0 column0 androw0 column15 must BOTH be identical cream bone RGB232,224,207, with zero alpha below bothendpoint columns. Retain the complete16pixel top snowline and all existingconnected interior scallops withinrows0..2. Keepevery remaining pixel/margin transparent, whole1254squarecanvas, no outlines/ground.'}
for name,detail in fixes.items():
    prompt='Use case: precise-object-edit. Image1 exact winter tile edit target,1254x1254canvas representing16x16logical squarepixel grid. ONE concrete correction: '+detail+' Keep squarecanvas and exactlogicalscale, no crop, rescale or extra texture. Flat pixels only, no gradients, blur, labels, glare, glow, shadow, objects or backdrop. '+('REALalpha outsidetop3rowsoverlay.' if name.startswith('edge') else 'FullyOPAQUEedge-to-edge terrain tile.')+'\n'
    args={'prompt':prompt,'referenced_image_paths':[str(HERE/f'raw/{name}-r1.png')],'transparent_background':name.startswith('edge')};stem=name+'-r2';jobs.append({'folder':HERE.name,'stem':stem,'revision':2,'args':args})
    (HERE/f'raw/{stem}.request.json').write_text(json.dumps(args,indent=2)+'\n',encoding='utf-8');(HERE/f'raw/{stem}.prompt.txt').write_text(prompt,encoding='utf-8')
recipes=json.loads((HERE/'recipes.json').read_text())
for name in ['grass_b_winter','grass_c_winter','grass_d_winter']:
    r=json.loads((HERE/f'preview/{name}-r1-recipe.json').read_text());recipes=[x for x in recipes if x['anim']!=name]+[r]
    p=HERE/f'raw/{name}-r1.call.json';c=json.loads(p.read_text());c.update(decision='accepted',inspection='Native16square and repeated field examined. Same1254source resolution and bone borders as master, >=232base pixels, all nonbase8connected clusters>=2. No owner approval inferred.');p.write_text(json.dumps(c,indent=2)+'\n')
(HERE/'recipes.json').write_text(json.dumps(recipes,indent=2)+'\n');(HERE/'correction-jobs.json').write_text(json.dumps(jobs,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'accepted_grass_variants':3,'corrections':len(jobs)}))
