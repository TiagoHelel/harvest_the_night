"""Supplement the completed corruption run with a count-preserving lamp fault.

No runtime/source writes: the temporary manifest is outside the checkout.
The full suite contains this extra probe on future runs.
"""
from pathlib import Path
import json
import sys
import tempfile

ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'tools'))
import import_art

data=import_art.load_manifest()
house=next(e for e in data['assets'] if e['id']=='buildings/house')
house['windows_xy'][0]=[99,99]
with tempfile.TemporaryDirectory(prefix='harvest-house-lamp-') as folder:
    path=Path(folder)/'manifest.json'
    path.write_text(json.dumps(data),encoding='utf-8')
    try:import_art.load_manifest(path)
    except ValueError as error:
        assert 'outside its glass' in str(error),error
        detail=str(error)
    else:raise AssertionError('Out-of-canvas lamp accepted with five valid glass regions')
(HERE/'window-probe.json').write_text(json.dumps(dict(passed=True,window_count=5,glass_count=5,deliberate_window=[99,99],rejection=detail),indent=2)+'\n',encoding='utf-8',newline='\n')
print('PASS: count-preserving out-of-canvas house lamp rejected; no repository corruption')
