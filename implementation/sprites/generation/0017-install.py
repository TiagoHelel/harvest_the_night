"""Install source-owned small FX without modifying any finished sprite family."""
from pathlib import Path
import json
import sys
ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'tools'))
import import_art

def entries():
    out=[]
    for plan in json.loads((HERE/'0017-plan.json').read_text()):
        name=plan['id']
        c=json.loads((HERE/f'0017-{name}-strip-call.json').read_text())
        measures=c['measurements']
        scale=min(plan['visible_height']/max(m['crop_xywh'][3] for m in measures),
                  (plan['canvas'][0]-2)/max(m['crop_xywh'][2] for m in measures))
        for frame,m in enumerate(measures):
            w,h=[max(1,round(n*scale)) for n in m['crop_xywh'][2:]]
            ident=f'effects/{name}_{frame}'
            e=dict(id=ident,owner='raster',source=c['source'],source_sha256=c['source_sha256'],
                   crop_xywh=m['crop_xywh'],sheet_cell_xywh=m['sheet_cell_xywh'],gutter_xy=[0,0],
                   canvas_wh=plan['canvas'],pivot_xy=plan['pivot'],content_scale=scale,
                   content_anchor_xy=[w//2,h//2 if plan['anchor']=='center' else h],
                   alpha_threshold=128,palette='tools/palette.py:COLOURS',animation='effects/'+name,
                   frame=frame,seconds=plan['seconds'],loop=False,output='sprites/'+ident+'.png',
                   prompt=c['prompt'],prompt_sha256=c['prompt_sha256'],
                   references=[dict(path=p,sha256=c['reference_hashes'][p],role='As indexed in exact submitted prompt') for p in c['references']],
                   tool='built-in ImageGen',generation_task='0017',revision=c['revision'],fx_family=name,
                   fx_origin=plan['anchor'],scale_reference=dict(visible_height=plan['visible_height'],max_raw_height=max(m['crop_xywh'][3] for m in measures)))
            if frame:e['variant_of']=f'effects/{name}_0'
            e['output_sha256']=import_art.sha(import_art.png(import_art.render_source(e)))
            out.append(e)
    return out

def main():
    fresh=entries()
    p=ROOT/'assets/art_source/manifest.json';data=json.loads(p.read_text())
    data['assets']=[e for e in data['assets'] if e.get('generation_task')!='0017']+fresh
    p.write_text(json.dumps(data,indent=2)+'\n',newline='\n')
    p=ROOT/'assets/art_source/ownership.json';owners=json.loads(p.read_text())
    by={e['output']:e for e in owners['outputs']}
    for e in fresh:by[e['output']]=dict(output=e['output'],owner='raster')
    owners['outputs']=[by[k] for k in sorted(by)]
    p.write_text(json.dumps(owners,indent=2)+'\n',newline='\n')
    print(f'Installed {len(fresh)} FX frames; {len(data["assets"])} raster entries')

if __name__=='__main__':main()
