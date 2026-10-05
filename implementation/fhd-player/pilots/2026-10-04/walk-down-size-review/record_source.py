"""Record the exact tool inputs and saved raw output without modifying artwork."""
from pathlib import Path
import hashlib
import json
import sys
from PIL import Image

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[4]
SOURCE = REPO / 'assets/art_source/player-fhd/pilots/2026-10-04/walk-down-size-review'

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def record(stem, original):
    args=json.loads((HERE/f'{stem}.prompt.json').read_text(encoding='utf-8'))
    saved=SOURCE/f'{stem}.png'
    data={'date':'2026-10-05','mode':'built-in image_gen.imagegen; identity-preserve edit',
          'arguments':args,'original_output_path':original,
          'saved_source':str(saved.relative_to(REPO)).replace('\\','/'),
          'source_sha256':digest(saved),'dimensions':Image.open(saved).size,
          'references':[{'path':p,'sha256':digest(Path(p))} for p in args['referenced_image_paths']],
          'status':'not selected; visual review pending','runtime_integrated':False}
    (HERE/f'{stem}.call.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')

if __name__=='__main__':
    record(sys.argv[1],sys.argv[2])
