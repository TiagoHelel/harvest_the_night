"""Pair every actual viewport with its exact 3x nearest enlargement, labels outside."""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
shots=ROOT/'implementation/shots/sprites/0015'
files=sorted((shots/'enemies').glob('*.png'))+sorted(shots.glob('*.png'))
assert files, 'Capture the Godot fixtures first'
captures=[]
for i in range(0,len(files),2):
    page=Image.new('RGB',(1940,1680),'#24212c');d=ImageDraw.Draw(page)
    for row,path in enumerate(files[i:i+2]):
        raw=Image.open(path).convert('RGB')
        assert raw.size==(480,270),path
        y=row*840
        d.text((8,y+2),str(path.relative_to(ROOT)),fill='#e8e0cf')
        page.paste(raw,(8,y+22))
        page.paste(raw.resize((1440,810),Image.Resampling.NEAREST),(496,y+22))
        captures.append(dict(path=path.relative_to(ROOT).as_posix(),sha256=hashlib.sha256(path.read_bytes()).hexdigest(),page=f'captures-{i//2:02d}.png',native_wh=[480,270],nearest_scale=3))
    page.save(HERE/f'captures-{i//2:02d}.png')
(HERE/'captures.json').write_text(json.dumps(captures,indent=2)+'\n',newline='\n')
print(f'{len(files)} native captures paired on {(len(files)+1)//2} original-size review pages')
