"""Inventory existing non-character runtime art and show it at shared FHD density."""
from pathlib import Path
from collections import Counter
import hashlib
import html
import json
from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
GROUPS = ['buildings', 'props', 'interior', 'crops', 'terrain', 'effects', 'ui']
TITLES = {'buildings':'Buildings and defenses', 'props':'Trees, animals and objects',
          'interior':'House interior and furniture', 'crops':'Crops and growth stages',
          'terrain':'Terrain and water', 'effects':'Effects', 'ui':'Interface'}
PRIORITY = {'buildings':['house','workshop','kitchen','gun_tower','auto_crossbow','flame_tower','mortar','fence','wall','barricade','mine'],
            'props':['tree','tree_b','chicken','cow','well','shop','generator','press','ore','rock','stump'],
            'interior':['bed','nightstand','storage','fireplace','kitchen','table','rug','plant','wall','floor']}


def build():
    manifest = json.loads((ROOT/'assets/art_source/manifest.json').read_text())
    recipes = {entry['output']:entry for entry in manifest['assets']}
    entries = []
    for group in GROUPS:
        priority=PRIORITY.get(group,[])
        paths = sorted((ROOT/'sprites'/group).rglob('*.png'),key=lambda p:(priority.index(p.stem) if p.stem in priority else len(priority),p.as_posix()))
        if group == 'effects':
            paths += [ROOT/'sprites/actors/shadow.png']
        for path in paths:
            name = path.relative_to(ROOT).as_posix()
            recipe = recipes.get(name, {})
            with Image.open(path) as image:
                width, height = image.size
                bounds = image.convert('RGBA').getbbox()
            entries.append({'path':name, 'name':path.stem, 'group':group,
                            'canvas_wh':[width,height], 'content_xyxy':bounds,
                            'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
                            'source':recipe.get('source'), 'source_sha256':recipe.get('source_sha256'),
                            'manifest_draw_scale':recipe.get('draw_scale',1),
                            'animation':recipe.get('animation'), 'frame':recipe.get('frame'),
                            'seconds':recipe.get('seconds'), 'loop':recipe.get('loop')})
    assert len({e['path'] for e in entries}) == len(entries)
    assert not any(e['path'].startswith('sprites/enemies/') for e in entries)
    assert not any(e['path'].startswith('sprites/actors/') and e['name']!='shadow' for e in entries)
    assert all(e['manifest_draw_scale']==1 for e in entries)
    counts = dict(Counter(e['group'] for e in entries))
    contract = {'date':'2026-10-06', 'status':'review only', 'runtime_integrated':False,
                'method':'Display unchanged runtime PNGs with nearest pixel scaling; no resampling or recoloring',
                'basis':'32px farmer detail occupies4 physical FHD pixels per detail pixel; current world art uses the same density',
                'logical_tile_size':16, 'FHD_screen_tile_size':64,
                'display_modes':{'FHD':4, 'overview':2, 'native':1},
                'every_asset_forced_into_32x32':False, 'excluded':['farmer poses','all enemies'],
                'count':len(entries), 'groups':counts, 'entries':entries}
    (HERE/'contract.json').write_text(json.dumps(contract,indent=2)+'\n',encoding='utf-8')
    sections=[]
    for group in GROUPS:
        cards=[]
        for e in entries:
            if e['group']!=group:
                continue
            path=html.escape('/'+e['path'],quote=True)
            w,h=e['canvas_wh']
            label=e['path'].removeprefix('sprites/').removesuffix('.png')
            cards.append(f'''<article class="card" data-group="{group}" data-name="{html.escape(label,quote=True)}">
<h3>{html.escape(e['name'].replace('_',' '))}</h3><div class="art"><img loading="lazy" decoding="async" src="{path}" width="{w*4}" height="{h*4}" data-w="{w}" data-h="{h}" alt="{html.escape(label,quote=True)}"></div>
<p class="meta">{w}×{h} native · <span class="screen">{w*4}×{h*4}</span> screen</p>
<a class="source" href="{path}" target="_blank" rel="noopener">{html.escape(label)}</a></article>''')
        sections.append(f'<section id="{group}" data-group="{group}"><h2>{TITLES[group]} <span>({counts[group]})</span></h2><div class="grid">'+''.join(cards)+'</div></section>')
    options=''.join(f'<option value="{group}">{TITLES[group]} ({counts[group]})</option>' for group in GROUPS)
    page='''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>All other assets —32px farmer density</title>
<style>
:root{color-scheme:dark}*{box-sizing:border-box}body{margin:0;background:#182426;color:#e9e3cf;font:16px Consolas,monospace}main{padding:24px;max-width:1600px;margin:auto}h1{font-size:27px;margin:0 0 12px}h2{font-size:23px;color:#e8d8ab;margin:30px 0 14px}h2 span{font-size:16px;color:#9ebcb6}p{max-width:1100px;line-height:1.5}.toolbar{position:sticky;top:0;z-index:2;display:flex;gap:12px;flex-wrap:wrap;align-items:center;padding:14px 24px;background:#203032;border-bottom:1px solid #52746c}button,select,input{font:inherit;background:#344b48;color:#e9e3cf;border:1px solid #75958d;padding:9px}input{min-width:210px;flex:1}button[aria-pressed=true]{background:#a7c8ad;color:#172725}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(285px,1fr));gap:14px}.card{min-width:0;border:1px solid #455f58;padding:12px;background:#202c2e;border-radius:4px}h3{font-size:17px;margin:0 0 10px;text-transform:capitalize;color:#e8d8ab}.art{height:316px;display:flex;align-items:center;justify-content:flex-start;overflow:auto;background-color:#303a3e;background-image:linear-gradient(45deg,#394446 25%,transparent 25%),linear-gradient(-45deg,#394446 25%,transparent 25%),linear-gradient(45deg,transparent 75%,#394446 75%),linear-gradient(-45deg,transparent 75%,#394446 75%);background-size:24px 24px;background-position:0 0,0 12px,12px -12px,-12px 0}.art img{display:block;flex:none;image-rendering:pixelated;margin:auto}.meta{font-size:13px;color:#b0c4bd;margin:10px 0 6px}a{color:#98dcd6}.source{font-size:12px;overflow-wrap:anywhere}[hidden]{display:none!important}.note{border-left:3px solid #a7c8ad;padding-left:14px}.empty{display:none}section{scroll-margin-top:110px}@media(max-width:600px){main{padding:16px}.toolbar{padding:12px}.grid{grid-template-columns:1fr}}
</style></head><body><main><h1>All other assets —32px farmer density</h1>
<p>__COUNT__ transparent PNGs: buildings, defenses, trees, animals, objects, furniture, crops, terrain, effects and interface. Includes upgrades, damaged/destroyed states, connected wall/fence pieces and building slices. Farmer and enemies are excluded; the separate contact shadow is included.</p>
<p class="note">32px refers to the selected farmer's artwork detail, not a32×32 box for every object. These existing assets already use the matching density: one native pixel becomes4 screen pixels at FHD1920×1080. A16px tile becomes64px on screen. Furniture and trees retain their larger proportions. This page displays the original PNGs unchanged.</p>
<p>All frames and states are shown individually. Trees/animals and fireplace motion use shaders in the game; this gallery shows their source art. Terrain atlas and building slices are supporting assets. This is an unlit asset gallery, not a screenshot of the game.</p>
</main><div class="toolbar"><label for="group">Category</label><select id="group"><option value="all">All categories</option>__OPTIONS__</select><input id="search" aria-label="Search assets" placeholder="Search: tree, bed, house…"><button id="fhd" aria-pressed="true">FHD scale4×</button><button id="overview" aria-pressed="false">Overview2×</button><button id="native" aria-pressed="false">Native1×</button><span id="count">__COUNT__ / __COUNT__ files</span></div>
<main>__SECTIONS__<p id="empty" hidden>No assets match this search.</p><p><a href="contract.json">Full inventory and source hashes</a> · <a href="../../../../fhd-enemies/pilots/2026-10-05/16px-review/index.html?v=z16-r6#farmer32-walk">Farmer and zombie comparison</a></p></main>
<script>
const cards=[...document.querySelectorAll('.card')],sections=[...document.querySelectorAll('section')];const search=document.getElementById('search'),group=document.getElementById('group');
function filter(){const q=search.value.trim().toLowerCase();let count=0;for(const card of cards){card.hidden=!(group.value==='all'||card.dataset.group===group.value)||!card.dataset.name.toLowerCase().includes(q);if(!card.hidden)count++}for(const section of sections)section.hidden=![...section.querySelectorAll('.card')].some(card=>!card.hidden);document.getElementById('count').textContent=`${count} / ${cards.length} files`;document.getElementById('empty').hidden=count>0}search.addEventListener('input',filter);group.addEventListener('change',filter);
function scale(value){for(const im of document.querySelectorAll('.art img')){im.width=Number(im.dataset.w)*value;im.height=Number(im.dataset.h)*value;im.closest('.card').querySelector('.screen').textContent=`${im.width}×${im.height}`}for(const [id,n] of [['fhd',4],['overview',2],['native',1]])document.getElementById(id).setAttribute('aria-pressed',String(value===n))}document.getElementById('fhd').onclick=()=>scale(4);document.getElementById('overview').onclick=()=>scale(2);document.getElementById('native').onclick=()=>scale(1);
</script></body></html>'''
    page=page.replace('__COUNT__',str(len(entries))).replace('__OPTIONS__',options).replace('__SECTIONS__',''.join(sections))
    (HERE/'index.html').write_text(page,encoding='utf-8')
    print(json.dumps({'files':len(entries),'groups':counts,'source_pixels_changed':False}))


if __name__ == '__main__':
    build()
