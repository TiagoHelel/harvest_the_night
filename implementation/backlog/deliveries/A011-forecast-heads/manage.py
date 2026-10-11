"""Register visually inspected paired icon crops without owner approval."""
from pathlib import Path
import json,sys
HERE=Path(__file__).resolve().parent;stem=sys.argv[1]
pair=json.loads((HERE/f'preview/{stem}-recipes.json').read_text());path=HERE/'recipes.json'
recipes=json.loads(path.read_text()) if path.exists() else [];recipes=[r for r in recipes if r['asset']!=pair[0]['asset']]+pair
path.write_text(json.dumps(recipes,indent=2)+'\n');path=HERE/f'raw/{stem}.call.json';call=json.loads(path.read_text());call.update(decision='accepted',inspection='True alpha and both native cuts inspected. Owner final approval pending.');path.write_text(json.dumps(call,indent=2)+'\n')
