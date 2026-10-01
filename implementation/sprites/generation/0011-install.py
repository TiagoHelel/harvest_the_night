"""Install full house states and exact compatibility slices from raw masters."""
from pathlib import Path
import json
import sys

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'tools'))
import import_art

WINDOWS=[[32,33],[19,45],[41,45],[30,45],[52,46]]
GLASS=[[31,32,3,3],[18,44,3,3],[40,44,3,3],[29,43,3,4],[52,44,2,4]]

def main():
    manifest=json.loads(import_art.MANIFEST.read_text(encoding='utf-8'))
    owner_path=ROOT/'assets/art_source/ownership.json'
    owners=json.loads(owner_path.read_text(encoding='utf-8'))
    by_output={e['output']:e for e in owners['outputs']}
    entries=[]
    for ident in ('house','house_hurt'):
        call=json.loads((HERE/('0011-'+ident+'-call.json')).read_text(encoding='utf-8'))
        assert (ROOT/call['source']).read_bytes()==Path(call['returned_file']).read_bytes()
        prompt='implementation/sprites/generation/0011-'+ident+'.prompt.txt'
        meta=dict(owner='raster',palette='tools/palette.py:COLOURS',seconds=0.55,loop=True,frame=0,prompt=prompt,prompt_sha256=import_art.sha((ROOT/prompt).read_bytes()),references=[dict(path=p,sha256=import_art.sha((ROOT/p).read_bytes()),role='edit target/reference as indexed in exact saved prompt') for p in call['references']],tool='built-in ImageGen',generation_task='0011',revision=0)
        e=dict(call['measured_recipe']);e.update(meta,source_sha256=call['source_sha256'],output='sprites/buildings/'+ident+'.png',animation='buildings/'+ident,cell_offset_xy=[-8,-12],light_xy=WINDOWS[1],smoke_xy=[51,12],windows_xy=WINDOWS,window_rects_xywh=GLASS)
        if ident=='house_hurt':e['variant_of']='buildings/house'
        image=import_art.render_source(e);e['output_sha256']=import_art.sha(import_art.png(image))
        entries.append(e)
        xs,ys=[0,24,40,64],[0,28,44,64]
        for x in range(3):
            for y in range(3):
                name='house_%d_%d'%(x,y)+('_hurt' if ident.endswith('hurt') else '')
                box=[xs[x],ys[y],xs[x+1]-xs[x],ys[y+1]-ys[y]]
                piece=image.crop((xs[x],ys[y],xs[x+1],ys[y+1]))
                entry=dict(meta,id='buildings/'+name,input=e['id'],operation='slice',canvas_wh=box[2:],pivot_xy=[box[2]//2,box[3]],animation='buildings/'+name,output='sprites/buildings/'+name+'.png',output_sha256=import_art.sha(import_art.png(piece)),slice_xywh=box,cell_offset_xy=[-8 if x==0 else 0,-12 if y==0 else 0])
                entries.append(entry)
    ids={e['id'] for e in entries}
    manifest['assets']=[e for e in manifest['assets'] if e['id'] not in ids]+entries
    for e in entries:by_output[e['output']]=dict(output=e['output'],owner='raster')
    owners['outputs']=[by_output[p] for p in sorted(by_output)]
    import_art.MANIFEST.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8',newline='\n')
    owner_path.write_text(json.dumps(owners,indent=2)+'\n',encoding='utf-8',newline='\n')
    (ROOT/'implementation/sprites/reviews/0011/measured-contract.json').write_text(json.dumps(entries,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('Installed two raw states, five measured glass lamps and eighteen compatibility slices')

if __name__=='__main__':main()
