"""Verify saved recolored files against frozen sources and masks."""
from pathlib import Path
import hashlib
import json
import subprocess
import sys
from PIL import Image

HERE=Path(__file__).resolve().parent
PILOT=HERE.parent
def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def check():
    historical=json.loads((PILOT/'walk-down-size-review/baseline.json').read_text())
    assert len(historical)==64 and all(digest(PILOT/p)==sha for p,sha in historical.items())
    report=json.loads((HERE/'validation.json').read_text())
    count=0; outside=0; changed=0; output_hashes={};gif_checks={}
    for name,colors in report['variants'].items():
        palette={tuple(c['rgb']) for c in colors}
        for direction,data in report['directions'].items():
            used=set()
            for item,output in zip(data['inputs'],data['variants'][name]['frames']):
                source=PILOT/item['path'];path=HERE/output['path'];mask_path=HERE/item['mask']
                assert digest(source)==item['sha256'] and digest(mask_path)==item['mask_sha256']
                assert digest(path)==output['sha256']
                before=Image.open(source).convert('RGBA');after=Image.open(path).convert('RGBA')
                mask=Image.open(mask_path)
                assert before.size==after.size==(80,80)
                assert before.getchannel('A').tobytes()==after.getchannel('A').tobytes()
                assert before.getbbox()==after.getbbox()
                for y in range(80):
                    for x in range(80):
                        b=before.getpixel((x,y));a=after.getpixel((x,y))
                        if mask.getpixel((x,y)):
                            assert a[:3] in palette;used.add(a[:3]);changed+=a!=b
                        else:assert a==b;outside+=1
                count+=1;output_hashes[output['path']]=digest(path)
            assert used==palette
        path=HERE/name/'all-eight.gif';gif=Image.open(path)
        assert gif.size==(1440,280) and gif.n_frames==8 and gif.info['loop']==0
        for n in range(8):gif.seek(n);assert gif.info['duration']==100
        gif_checks[name]={'path':str(path.relative_to(HERE)).replace('\\','/'),'sha256':digest(path),
                          'frames':8,'duration_ms':100,'dimensions':[1440,280],'loop':0}
    assert count==256
    result={'date':'2026-10-05','status':'PASS','native_outputs':count,'source_frames_unchanged':64,
        'exact_unmasked_rgba_comparisons':outside,'changed_garment_rgb_pixels':changed,
        'alpha_geometry_and_non_garment_pixels_preserved':True,
        'every_direction_has_identical_12_color_garment_palette':True,'gifs':gif_checks,'output_hashes':output_hashes,
        'limits':'Native PNGs carry exact palette RGB; GIF previews use a shared256-color display palette. Existing gait geometry is preserved, not redesigned.'}
    (HERE/'checks.json').write_text(json.dumps(result,indent=2)+'\n')
    print(f'PASS: {count} native files, {outside} unmasked RGBA comparisons, four timed GIFs,64 unchanged source hashes.')
    return result

if __name__=='__main__':
    before=json.loads((HERE/'checks.json').read_text()) if '--rebuild' in sys.argv else None
    if before:subprocess.run([sys.executable,str(HERE/'build_colors.py')],check=True)
    result=check()
    if before:
        assert result['output_hashes']==before['output_hashes']
        assert {n:v['sha256'] for n,v in result['gifs'].items()}=={n:v['sha256'] for n,v in before['gifs'].items()}
        result['rebuild_identical_native_png_and_gif_bytes']=True
        (HERE/'checks.json').write_text(json.dumps(result,indent=2)+'\n')
        print('PASS: rebuild produced identical256 native PNG and four GIF file hashes.')
