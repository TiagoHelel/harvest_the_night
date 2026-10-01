"""Install full station states and exact source-owned compatibility quarters."""
from pathlib import Path
import json
import sys

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'tools'))
import import_art

# Measured on the accepted native furnace/exhaust/indicator pixels.
EMITTERS={'workshop':([32,35],[33,13]),'kitchen':([28,34],[34,10]),'generator':([8,30],[39,15])}

def main():
    manifest=json.loads(import_art.MANIFEST.read_text(encoding='utf-8'))
    owner_path=ROOT/'assets/art_source/ownership.json'
    owners=json.loads(owner_path.read_text(encoding='utf-8'))
    by_output={e['output']:e for e in owners['outputs']}
    entries=[]
    for plan in json.loads((HERE/'0012-plan.json').read_text()):
        ident=plan['id'];kind='master' if ident in ('shop','well') else 'states'
        call=json.loads((HERE/('0012-'+ident+'-'+kind+'-call.json')).read_text())
        assert (ROOT/call['source']).read_bytes()==Path(call['returned_file']).read_bytes()
        meta=dict(owner='raster',palette='tools/palette.py:COLOURS',seconds=0.55,loop=True,frame=0,prompt=call['prompt'],prompt_sha256=call['prompt_sha256'],references=[dict(path=p,sha256=import_art.sha((ROOT/p).read_bytes()),role='Identity master/style reference as indexed in exact saved prompt') for p in call['references']],tool='built-in ImageGen',generation_task='0012',revision=0)
        for recipe in call['measured_recipes']:
            e=dict(recipe);name=e['id'].split('/')[-1]
            e.update(meta,source_sha256=call['source_sha256'],output='sprites/'+e['id']+'.png',animation=e['id'],cell_offset_xy=[-8,-12] if kind=='states' else ([-8,-20] if ident=='shop' else [-4,-14]))
            if name!=ident:e['variant_of']=plan['folder']+'/'+ident
            if ident in EMITTERS:e.update(light_xy=EMITTERS[ident][0],smoke_xy=EMITTERS[ident][1])
            image=import_art.render_source(e);e['output_sha256']=import_art.sha(import_art.png(image))
            entries.append(e)
            if name==ident and kind=='states':
                for x in range(2):
                    for y in range(2):
                        q=ident+'_%d_%d'%(x,y);box=[24*x,24*y,24,24]
                        piece=image.crop((24*x,24*y,24*x+24,24*y+24))
                        entries.append(dict(meta,id=plan['folder']+'/'+q,input=e['id'],operation='slice',canvas_wh=[24,24],pivot_xy=[12,24],animation=plan['folder']+'/'+q,output='sprites/'+plan['folder']+'/'+q+'.png',output_sha256=import_art.sha(import_art.png(piece)),slice_xywh=box,cell_offset_xy=[-8 if x==0 else 0,-12 if y==0 else 0]))
    replacements={e['id']:e for e in entries}
    existing={e['id'] for e in manifest['assets']}
    manifest['assets']=[replacements.get(e['id'],e) for e in manifest['assets']]+[e for e in entries if e['id'] not in existing]
    for e in entries:by_output[e['output']]=dict(output=e['output'],owner='raster')
    owners['outputs']=[by_output[p] for p in sorted(by_output)]
    import_art.MANIFEST.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8',newline='\n')
    owner_path.write_text(json.dumps(owners,indent=2)+'\n',encoding='utf-8',newline='\n')
    (ROOT/'implementation/sprites/reviews/0012/measured-contract.json').write_text(json.dumps(entries,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('Installed 14 full states/fixtures and 16 exact compatibility quarters')

if __name__=='__main__':main()
