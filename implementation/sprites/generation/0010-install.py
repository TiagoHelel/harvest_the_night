"""Install fourteen measured source-owned growth/soil outputs."""
from pathlib import Path
import json
import sys
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'tools'))
import import_art

def main():
    calls=[json.loads(p.read_text(encoding='utf-8')) for p in sorted(HERE.glob('0010-*-call.json'))]
    assert {c['id'] for c in calls}=={'wheat','corn','carrot','tilled','tilled_wet'}
    manifest=json.loads(import_art.MANIFEST.read_text(encoding='utf-8'))
    owner_path=ROOT/'assets/art_source/ownership.json'
    owners=json.loads(owner_path.read_text(encoding='utf-8'))
    by_output={e['output']:e for e in owners['outputs']}
    entries=[];measurements=[]
    for call in calls:
        assert (ROOT/call['source']).read_bytes()==Path(call['returned_file']).read_bytes()
        prompt='implementation/sprites/generation/0010-'+call['id']+'.prompt.txt'
        for frame,recipe in enumerate(call['measured_recipes']):
            e=dict(recipe);im=import_art.render_source(e)
            e.update(owner='raster',source_sha256=call['source_sha256'],output='sprites/'+e['id']+'.png',output_sha256=import_art.sha(import_art.png(im)),palette='tools/palette.py:COLOURS',animation='crops/'+call['id'],frame=frame,seconds=0.55,loop=False,prompt=prompt,prompt_sha256=import_art.sha((ROOT/prompt).read_bytes()),references=[dict(path=p,sha256=import_art.sha((ROOT/p).read_bytes()),role='reference/edit target as indexed explicitly in exact saved prompt') for p in call['references']],tool='built-in ImageGen',generation_task='0010',revision=0)
            entries.append(e);by_output[e['output']]=dict(output=e['output'],owner='raster')
            measurements.append(dict(recipe=e,native_bbox=im.getbbox(),native_rgba_sha256=import_art.sha(im.tobytes())))
    assert len(entries)==14
    ids={e['id'] for e in entries}
    manifest['assets']=[e for e in manifest['assets'] if e['id'] not in ids]+entries
    owners['outputs']=[by_output[p] for p in sorted(by_output)]
    import_art.MANIFEST.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8',newline='\n')
    owner_path.write_text(json.dumps(owners,indent=2)+'\n',encoding='utf-8',newline='\n')
    (ROOT/'implementation/sprites/reviews/0010/measured-contract.json').write_text(json.dumps(measurements,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('Installed 12 stages and 2 soil recipes; all fourteen existing filenames preserved')

if __name__=='__main__':main()
