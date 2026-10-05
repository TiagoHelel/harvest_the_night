"""Copy built-in generated masters and retain exact input/output provenance."""
from pathlib import Path
import hashlib
import json
import shutil
import sys
from PIL import Image

HERE = Path(__file__).resolve().parent
PILOT = HERE.parent
REPO = PILOT.parents[3]
SOURCE = REPO / 'assets/art_source/player-fhd/pilots/2026-10-04/walk-down-left'

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def record(name, original, review):
    arguments = json.loads((HERE / f'{name}.prompt.json').read_text())
    destination = SOURCE / f'{name}.png'
    shutil.copyfile(original, destination)
    report = {'date': '2026-10-05', 'mode': 'built-in image_gen',
              'original_output': str(original), 'workspace_source': str(destination),
              'arguments': arguments, 'sha256': digest(destination),
              'dimensions': Image.open(destination).size,
              'references': [{'path': p, 'sha256': digest(Path(p))}
                             for p in arguments.get('referenced_image_paths', [])],
              'review': review, 'runtime_integrated': False}
    (HERE / f'{name}.call.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'source': str(destination), 'sha256': report['sha256'],
                      'dimensions': report['dimensions']}))

if __name__ == '__main__':
    record(sys.argv[1], Path(sys.argv[2]), sys.argv[3])
