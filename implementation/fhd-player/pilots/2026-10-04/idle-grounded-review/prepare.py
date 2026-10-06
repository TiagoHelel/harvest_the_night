"""Freeze the accepted walk before replacing its held-frame idle stand-ins."""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
PALETTE = HERE.parent / 'palette-variants'
DIRS = {'down':'south','right':'east','up':'north','left':'west',
        'down-right':'south_east','up-right':'north_east',
        'up-left':'north_west','down-left':'south_west'}

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    manifest = json.loads((ROOT/'assets/art_source/manifest.json').read_text())
    entries = {e['id']:e for e in manifest['assets']}
    before = {}; old = Image.new('RGBA',(1920,960))
    refs = Image.new('RGBA',(1920,960))
    diagnostic = Image.new('RGB',(960,600),'#20292c')
    draw = ImageDraw.Draw(diagnostic)
    for j,(direction,suffix) in enumerate(DIRS.items()):
        pose = Image.open(ROOT/f'sprites/actors/idle_{suffix}_0.png').convert('RGBA')
        old.alpha_composite(pose.resize((480,480),Image.Resampling.NEAREST),((j%4)*480,(j//4)*480))
        # A style reference only. Foot placement must be newly authored.
        ref = Image.open(PALETTE/f'blue/frames/{direction}/01.png').convert('RGBA')
        refs.alpha_composite(ref.resize((480,480),Image.Resampling.NEAREST),((j%4)*480,(j//4)*480))
        diagnostic.paste(pose.resize((240,240),Image.Resampling.NEAREST),((j%4)*240,(j//4)*300+35),pose.resize((240,240),Image.Resampling.NEAREST))
        draw.text(((j%4)*240+12,(j//4)*300+10),direction.upper(),fill='#e9e3cf')
        for i in range(8):
            e=entries[f'actors/walk_{suffix}_{i}']
            for key in ('source','output'):
                path=ROOT/e[key];before[e[key]]=digest(path)
            path=PALETTE/f'blue/frames/{direction}/{i+1:02}.png'
            before[path.relative_to(ROOT).as_posix()]=digest(path)
        for i in range(3):
            path=ROOT/f'sprites/actors/idle_{suffix}_{i}.png'
            target=HERE/f'before/{direction}/{i:02}.png'
            target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(path.read_bytes())
    (HERE/'walk-baseline.json').write_text(json.dumps(before,indent=2)+'\n')
    refs.save(HERE/'approved-walk-reference.png');old.save(HERE/'raised-foot-edit-target.png')
    diagnostic.save(HERE/'before-idle.png')
    print('Frozen 192 walk review/source/runtime hashes; retained 24 old idle sprites.')

if __name__=='__main__':main()
