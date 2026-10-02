"""Migrate the complete icon family; keep established UI surfaces code-owned."""
from pathlib import Path
import json,sys
ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'tools'))
from sprite_maps import SPRITES


def main():
    plan=json.loads((HERE/'0018-plan.json').read_text(encoding='utf-8'))
    assert len(plan)==15
    fresh=[]
    for spec in plan:
        call=json.loads((HERE/f'0018-{spec["id"]}-call.json').read_text(encoding='utf-8'))
        assert len(call['entries'])==2 and call['source']==f'assets/art_source/ui/{spec["id"]}.png'
        fresh.extend(call['entries'])
    p=ROOT/'assets/art_source/manifest.json';manifest=json.loads(p.read_text(encoding='utf-8'))
    manifest['assets']=[e for e in manifest['assets'] if e.get('generation_task')!='0018']+fresh
    p.write_text(json.dumps(manifest,indent=2)+'\n',newline='\n')
    p=ROOT/'assets/art_source/ownership.json';owners=json.loads(p.read_text(encoding='utf-8'))
    by={e['output']:e for e in owners['outputs']}
    for ident in SPRITES:
        if ident.startswith('ui/') and f'sprites/{ident}.png' not in by:
            by[f'sprites/{ident}.png']=dict(output=f'sprites/{ident}.png',owner='ascii')
    for entry in fresh:by[entry['output']]=dict(output=entry['output'],owner='raster')
    owners['outputs']=[by[k] for k in sorted(by)]
    p.write_text(json.dumps(owners,indent=2)+'\n',newline='\n')
    print(f'Installed complete 15-icon family: 30 raster outputs, {len(manifest["assets"])} raster entries')

if __name__=='__main__':main()
