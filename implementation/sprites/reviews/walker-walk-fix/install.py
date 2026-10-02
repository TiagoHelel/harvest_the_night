"""Install only the four reviewed walk frames; preserve all other source art."""
from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / 'tools'))
import import_art

HERE = Path(__file__).resolve().parent
data = json.loads(import_art.MANIFEST.read_text())
replacements = {e['id']: e for e in json.loads((HERE / 'candidate-entries.json').read_text())}
assert set(replacements) == {'enemies/walker_walk_' + str(i) for i in range(4)}
data['assets'] = [replacements.get(e['id'], e) for e in data['assets']]
import_art.MANIFEST.write_text(json.dumps(data, indent=2)+'\n', encoding='utf-8', newline='\n')
print('Installed four walker walk recipes; existing compatibility alias follows frame 2')
