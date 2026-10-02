"""Install source-owned barrier modules, all cardinal joins, and trap states."""
from pathlib import Path
import json
import sys

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'tools'))
import import_art

SELECTED={'wall':'whole-r3','fence':'whole-r3'}

def call(family,kind):
    return json.loads((HERE/f'0014-{family}-{kind}-call.json').read_text())

def meta(c,canvas,pivot):
    return dict(owner='raster',palette='tools/palette.py:COLOURS',seconds=0.55,loop=True,frame=0,
                canvas_wh=canvas,pivot_xy=pivot,cell_offset_xy=[8-pivot[0],16-pivot[1]],
                prompt=c['prompt'],prompt_sha256=c['prompt_sha256'],
                references=[dict(path=p,sha256=c['reference_hashes'][p],role='Source master / farm material-camera reference as indexed in exact prompt') for p in c['references']],
                tool='built-in ImageGen',generation_task='0014',revision=c['revision'])

def source(c,measure,ident,scale,canvas,pivot,bottom):
    e=meta(c,canvas,pivot)
    w,h=[max(1,round(n*scale)) for n in measure['crop_xywh'][2:]]
    e.update(id=ident,output='sprites/'+ident+'.png',animation=ident,source=c['source'],source_sha256=c['source_sha256'],
             crop_xywh=measure['crop_xywh'],sheet_cell_xywh=measure['sheet_cell_xywh'],gutter_xy=[0,0],
             alpha_threshold=128,content_scale=scale,content_anchor_xy=[w//2,h+pivot[1]-bottom])
    e['output_sha256']=import_art.sha(import_art.png(import_art.render_source(e)))
    return e

def entries():
    out=[]
    for family,kind in SELECTED.items():
        whole,hurt=call(family,kind),call(family,'hurt-r1')
        scale=16/max(c['measurements'][1]['crop_xywh'][2] for c in (whole,hurt))
        for state,c in [('whole',whole),('hurt',hurt)]:
            suffix='' if state=='whole' else '_hurt'
            for original in c['measurements'][:3]:
                # Select modules independently after native/runtime review.
                # R3 supplies taller piers/panels; the earlier lengthwise
                # spans retain the approved screen-Y camera and common scale.
                module_call=call(family,'whole-r2' if state=='whole' else 'hurt') if original['role']=='vertical' else c
                m=next(x for x in module_call['measurements'] if x['role']==original['role'])
                ident=f'buildings/modules/{family}_{m["role"]}{suffix}'
                e=source(module_call,m,ident,scale,[16,32],[8,28],28 if m['role']=='vertical' else 20)
                e.update(barrier_family=family,barrier_state=state,module=m['role'])
                out.append(e)
            for mask in range(16):
                name=family+(f'_join_{mask}' if mask else '')+suffix
                e=meta(c,[16,32],[8,28])
                post=f'buildings/modules/{family}_post{suffix}'
                h=f'buildings/modules/{family}_horizontal{suffix}'
                v=f'buildings/modules/{family}_vertical{suffix}'
                parts=[]
                # Native source cuts overlap the central post and the neighbor
                # span; no tilt, new colors, per-pose fit or painted connector.
                if mask&1:parts.append(dict(input=v,slice_xywh=[0,8,16,20],paste_xy=[0,0]))
                if mask&8:parts.append(dict(input=h,slice_xywh=[0,0,8,32],paste_xy=[0,0]))
                if mask&2:parts.append(dict(input=h,slice_xywh=[8,0,8,32],paste_xy=[8,0]))
                if mask&4:parts.append(dict(input=v,slice_xywh=[0,8,16,20],paste_xy=[0,8]))
                parts.append(dict(input=post,slice_xywh=[0,0,16,32],paste_xy=[0,0]))
                e.update(id='buildings/'+name,output='sprites/buildings/'+name+'.png',animation='buildings/'+name,
                         input=post,operation='compose',parts=parts,barrier_family=family,barrier_state=state,join_mask=mask,output_sha256='0'*64)
                out.append(e)
        rubble=call(family,'whole-r2')
        e=source(rubble,rubble['measurements'][3],f'buildings/{family}_wreck',scale,[16,32],[8,28],28)
        e.update(barrier_family=family,barrier_state='wreck')
        out.append(e)
    for family in ('barricade','mine'):
        c=call(family,'states')
        scale=(14 if family=='barricade' else 12)/max(m['crop_xywh'][2] for m in c['measurements'])
        canvas,pivot=([16,24],[8,20]) if family=='barricade' else ([16,16],[8,14])
        for i,m in enumerate(c['measurements']):
            name=family+(['','_hurt','_wreck'][i] if family=='barricade' else ['','_triggered','_spent'][i])
            e=source(c,m,'buildings/'+name,scale,canvas,pivot,pivot[1])
            e.update(barrier_family=family,barrier_state=m['role'])
            out.append(e)
    # A temporary registry independent of files is sufficient for deterministic
    # graph resolution and output hashes; load_manifest validates saved owners.
    files,_=import_art.build({'assets':out})
    for e in out:e['output_sha256']=import_art.sha(files[e['output']])
    return out

def main():
    out=entries()
    review=ROOT/'implementation/sprites/reviews/0014'
    review.mkdir(parents=True,exist_ok=True)
    (review/'measured-contract.json').write_text(json.dumps(out,indent=2)+'\n',encoding='utf-8',newline='\n')
    if '--preview' in sys.argv:
        files,images=import_art.build({'assets':out})
        from PIL import Image,ImageDraw
        for family in ('wall','fence'):
            image=Image.new('RGBA',(320,236),'#e8e0cf');d=ImageDraw.Draw(image)
            for state,dy in [('',16),('_hurt',126)]:
                for mask in range(16):
                    sprite=images['buildings/'+family+(f'_join_{mask}' if mask else '')+state]
                    x=(mask%8)*40;y=dy+(mask//8)*50
                    d.text((x+1,y-12),str(mask)+state[:2],fill='#241f2e');image.alpha_composite(sprite,(x+12,y))
            image.save(review/f'{family}-joins.png');image.resize((960,708),Image.Resampling.NEAREST).save(review/f'{family}-joins-3x.png')
        image=Image.new('RGBA',(216,64),'#e8e0cf');d=ImageDraw.Draw(image)
        for i,e in enumerate([e for e in out if e['barrier_family'] in ('barricade','mine')]):
            d.text((i*36,2),e['barrier_state'][:5],fill='#241f2e');image.alpha_composite(images[e['id']],(i*36+8,20))
        image.save(review/'traps.png');image.resize((648,192),Image.Resampling.NEAREST).save(review/'traps-3x.png')
        print('Previewed 84 source-owned barrier/trap outputs; runtime not replaced')
        return
    manifest=json.loads(import_art.MANIFEST.read_text());ownership=ROOT/'assets/art_source/ownership.json';owners=json.loads(ownership.read_text())
    replace={e['id']:e for e in out};old={e['id'] for e in manifest['assets']}
    manifest['assets']=[replace.get(e['id'],e) for e in manifest['assets']]+[e for e in out if e['id'] not in old]
    by_output={e['output']:e for e in owners['outputs']}
    for e in out:by_output[e['output']]=dict(output=e['output'],owner='raster')
    owners['outputs']=[by_output[p] for p in sorted(by_output)]
    import_art.MANIFEST.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8',newline='\n')
    ownership.write_text(json.dumps(owners,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(f'Installed {len(out)} source-owned outputs: 64 occupancy joins, 12 source modules, two ruins, three barricade and three mine states')

if __name__=='__main__':main()
