"""Assemble source-native sheets for visual review; no artwork is altered."""
from pathlib import Path
import json
from PIL import Image

HERE = Path(__file__).resolve().parent
OUT = HERE/'contact-overviews'
OUT.mkdir(exist_ok=True)
(OUT/'.gdignore').write_bytes(b'')
for group in json.loads((HERE/'playback.json').read_text())['groups']:
    action = group['action']
    sheets = [Image.open(HERE/'contacts'/(action+'_'+d+'.png'))
              for d in ('south','west','north','east')]
    page = Image.new('RGB',(sheets[0].width,sheets[0].height*4))
    for n,sheet in enumerate(sheets):
        page.paste(sheet,(0,n*sheet.height))
    page.save(OUT/(action+'.png'))
print('Sixteen complete four-direction source-native contact overviews.')
