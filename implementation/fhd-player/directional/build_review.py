"""Source-owned directional farmer cuts and horizontal validation GIFs.

The only pixel operations are source crops, nearest reduction and the existing
project palette recipe. This preview never replaces sprites/actors or core code.
"""
from pathlib import Path
import argparse
import json
import sys
import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
ART = ROOT / "assets/art_source/player-fhd/directional"
OUT = ART / "frames"
sys.path.insert(0, str(ROOT / "tools"))
import import_art
from palette import COLOURS

DIRECTIONS = ["south", "west", "north", "east"]
REVISIONS = {"walk_west": "walk_west-r2", "walk_east": "walk_east-r3",
             "run_north": "run_north-r1", "run_east": "run_east-r1", "plant": "plant-r1",
             "repair_west": "repair_west-r1", "chop_north": "chop_north-r1",
             "mine_north": "mine_north-r1"}
OVERRIDES = ["repair_west", "chop_north", "mine_north"]
KEYS = ["ink", "ink_soft", "soil_dark", "wood_dark", "wood", "wood_light",
        "gold_dark", "gold", "gold_light", "skin_dark", "skin", "skin_light",
        "bone", "bone_dark", "cloth_dark", "cloth", "cloth_light", "stone_dark",
        "stone", "stone_light", "water_dark", "water", "water_light",
        "leaf_dark", "leaf", "leaf_light", "roof_dark", "roof", "roof_light"]
LABELS = {"idle": "IDLE", "walk": "WALK - 8 FRAMES", "run": "RUN - 8 FRAMES",
          "chop": "CHOP WOOD", "mine": "MINE", "till": "TILL SOIL",
          "plant": "PLANT", "harvest": "HARVEST", "water": "WATER",
          "fish": "CAST / WAIT", "reel": "REEL IN",
          "collect": "COLLECT", "craft": "CRAFT", "trade": "TRADE",
          "repair": "REPAIR", "carry": "CARRY"}


def bounds(mask, count, axis):
    """Find transparent gutters near regular grid boundaries, without painting."""
    totals = mask.sum(axis=1 if axis == 0 else 0)
    length = len(totals)
    result = [0]
    for n in range(1, count):
        center = length * n / count
        margin = length / count * .19
        lo, hi = round(center - margin), round(center + margin)
        options = np.flatnonzero(totals[lo:hi] == totals[lo:hi].min()) + lo
        # Nearest equally empty gutter keeps the requested sheet layout.
        result.append(int(min(options, key=lambda v: abs(v - center))))
    return result + [length]


def components(mask):
    """Run-length connected-component bounds, used only to select source crops."""
    parents, runs = [], []
    previous = []
    def find(n):
        while parents[n] != n:
            parents[n] = parents[parents[n]]
            n = parents[n]
        return n
    for y,line in enumerate(mask):
        edges = np.diff(np.r_[False,line,False].astype(np.int8))
        starts,ends = np.flatnonzero(edges == 1),np.flatnonzero(edges == -1)
        current = []
        for left,right in zip(starts,ends):
            n = len(parents)
            parents.append(n)
            for pl,pr,pn in previous:
                if pr >= left and pl <= right:
                    parents[find(pn)] = find(n)
            current.append((int(left),int(right),n))
            runs.append((y,int(left),int(right),n))
        previous = current
    result = {}
    for y,left,right,n in runs:
        key = find(n)
        area,box = result.get(key,(0,[left,y,right,y+1]))
        result[key] = (area+right-left,[min(box[0],left),min(box[1],y),max(box[2],right),max(box[3],y+1)])
    memberships = {}
    for y,left,right,n in runs:
        memberships.setdefault(find(n),[]).append((y,left,right))
    return sorted([(area,box,memberships[key]) for key,(area,box) in result.items()],key=lambda v:v[0],reverse=True)


def measure(cell, action):
    px = np.array(cell).astype(np.int32)
    alpha = px[:, :, 3] >= 128
    parts = components(alpha)
    main = parts[0][1]
    body = np.zeros_like(alpha)
    for y,left,right in parts[0][2]:
        body[y,left:right] = True
    ys, xs = np.nonzero(body)
    assert len(xs), "Empty source cell"
    rgb = px[:, :, :3]
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    gold = body & (r > 165) & (g > 95) & (g > b * 1.6) & (r > g)
    counts = gold.sum(axis=1)
    peak = int(counts.argmax())
    assert counts[peak] > cell.width * .08, "Cannot locate straw hat"
    eligible = counts >= counts[peak] * .12
    hat_top = peak
    while hat_top > 0 and (eligible[hat_top - 1] or
                          (hat_top > 1 and eligible[hat_top - 2])):
        hat_top -= 1
    hat_bottom = peak + 1
    while hat_bottom < len(counts) and (eligible[hat_bottom] or
                                     (hat_bottom + 1 < len(counts) and eligible[hat_bottom + 1])):
        hat_bottom += 1
    hy, hx = np.nonzero(gold[hat_top:hat_bottom])
    hat_left, hat_right = int(hx.min()), int(hx.max()) + 1
    center = (hat_left + hat_right) / 2
    width = hat_right - hat_left
    yy, xx = np.indices(alpha.shape)
    # A full brown band disconnects the north-facing crown from the brim.
    # Search bright straw above the brim instead of stopping at that band;
    # otherwise a 60px brim-to-boot measurement makes the back view too tall.
    crown = gold & (r > 200) & (yy <= peak) & (yy > peak - cell.height * .42) & (abs(xx-center) < width*.40)
    cy,cx = np.nonzero(crown)
    assert len(cx), "Cannot locate straw crown above brim"
    hat_top = int(cy.min())
    brown = body & (r > 60) & (r < 190) & (g > 25) & (g < 135) & (b < 100) & (r > g * 1.2)
    boots = brown & (yy > hat_bottom + (hat_bottom - hat_top) * .9) & (abs(xx - center) < width * .55)
    by, bx = np.nonzero(boots)
    assert len(bx), "Cannot locate brown boots"
    ground = int(by.max()) + 1
    lower = boots & (yy > ground - (ground - hat_top) * .16)
    ly, lx = np.nonzero(lower)
    boot_center = (int(lx.min()) + int(lx.max()) + 1) / 2
    crop = list(main)
    selection = body.copy()
    # Seeds and water drops intentionally detach from hands; neighboring atlas
    # tool fragments do not belong in a source crop for other action families.
    if action in ('plant','water'):
        for area,box,runs in parts[1:]:
            if area < parts[0][0]*.03 and box[1] >= hat_bottom and box[3] <= ground+(ground-hat_top)*.15:
                crop = [min(crop[0],box[0]),min(crop[1],box[1]),max(crop[2],box[2]),max(crop[3],box[3])]
                for y,left,right in runs:
                    selection[y,left:right] = True
    return {"crop": crop,
            "hat_top": hat_top, "hat_center": center, "boot_center": boot_center,
            "ground": ground, "body_height": ground - hat_top,
            "selection_sha256":import_art.sha(selection.tobytes()),"selection":selection}


def recipes(partial=False):
    jobs = json.loads((HERE / "jobs.json").read_text())['jobs']
    for name in OVERRIDES:
        action,direction = name.split('_')
        jobs.append({"id":name,"action":action,"direction":direction,
                     "columns":4,"rows":1,"count":4,"seconds":.16})
    entries = []
    front = json.loads((HERE.parent / "locomotion-contract.json").read_text())["frames"]
    for previous in front:
        entry = dict(previous)
        entry["review_source"] = "previously user-approved front locomotion"
        entries.append(entry)
    for job in jobs:
        source_id = job.get('source_id', REVISIONS.get(job['id'], job['id']))
        source = ART / (source_id + '.png')
        if not source.exists() and partial:
            continue
        image = Image.open(source).convert('RGBA')
        opaque = np.array(image)[:, :, 3] >= 128
        assert opaque.mean() < .82, (job['id'], "opaque background")
        ys = bounds(opaque, job['rows'], 0)
        global_xs = bounds(opaque,job['columns'],1)
        groups = {}
        for row in range(job['rows']):
            top, bottom = ys[row:row+2]
            xs = bounds(opaque[top:bottom], job['columns'], 1)
            for col in range(job['columns']):
                if job['direction'] == 'all':
                    left,right = global_xs[col:col+2]
                    # Tool tips need different vertical gutters in each column.
                    local_ys = bounds(opaque[:,left:right],job['rows'],0)
                    cell_top,cell_bottom = local_ys[row:row+2]
                else:
                    left,right = xs[col:col+2]
                    cell_top,cell_bottom = top,bottom
                measured = measure(image.crop((left,cell_top,right,cell_bottom)),job['action'])
                if job['direction'] == 'all':
                    name = job['action'] + '_' + DIRECTIONS[row]
                    frame = col
                else:
                    name = job.get('animation', job['id'])
                    source_frame = row * job['columns'] + col
                    if 'frame_map' in job and str(source_frame) not in job['frame_map']:
                        continue
                    frame = job.get('frame_map', {}).get(str(source_frame), source_frame + job.get('frame_start', 0))
                measured.update(name=name, frame=frame, left=left, top=cell_top,
                                row=row, cell=[left,cell_top,right-left,cell_bottom-cell_top])
                groups.setdefault(name, []).append(measured)
        for name, group in groups.items():
            if job['direction'] == 'all' and name in OVERRIDES:
                continue  # Focused direction revisions own these four frames.
            locomotion = job['action'] in ('idle','walk','run')
            row_ground = {r: max(m['crop'][3] if locomotion else m['ground'] for m in group if m['row'] == r)
                          for r in {m['row'] for m in group}}
            body_height = max(row_ground[m['row']]-m['crop'][1] for m in group) if locomotion \
                          else max(m['body_height'] for m in group)
            scale = 60 / body_height
            # Match the already-approved body material subset. Red prop colors
            # belong to the mushroom, not the hat band or leather boots.
            material_keys = KEYS[:17]
            if job['action'] in ('chop','mine','till','water','fish','reel','repair'):
                material_keys += ['stone_dark','stone','stone_light']
            if job['action'] == 'water':
                material_keys += ['water_dark','water','water_light']
            if job['action'] == 'harvest':
                material_keys += ['leaf_dark','leaf','leaf_light']
            if job['action'] == 'collect':
                material_keys += ['roof_dark','roof','roof_light']
            for m in group:
                x0,y0,x1,y1 = m['crop']
                center = m['hat_center'] if locomotion or job['action'] == 'carry' else m['boot_center']
                ground = row_ground[m['row']] if locomotion else m['ground']
                # Work tools need clearance below boots and above the hat.
                canvas, pivot = ([96,96],[48,88]) if locomotion else ([128,128],[64,108])
                entry = {"id": name + '_' + str(m['frame']), "animation": name,
                         "frame": m['frame'], "source": source.relative_to(ROOT).as_posix(),
                         "source_sha256": import_art.sha(source.read_bytes()),
                         "crop_xywh": [m['left']+x0,m['top']+y0,x1-x0,y1-y0],
                         "sheet_cell_xywh": m['cell'], "content_scale": scale,
                         "source_selection":"connected-farmer-and-particles-v1",
                         "source_selection_sha256":m['selection_sha256'],
                         "action":job['action'],
                         "content_anchor_xy": [round((center-x0)*scale),round((ground-y0)*scale)],
                         "canvas_wh": canvas, "pivot_xy": pivot, "draw_scale": .5,
                         "body_reference_height": body_height,
                         "feet_source_xy": [m['left']+center,m['top']+ground],
                         "alpha_threshold": 128, "palette": "tools/palette.py:COLOURS",
                         "palette_keys": material_keys, "seconds": job['seconds'], "loop": True,
                         "material_ramp_rule":"saturated-red-prop" if job['action']=='collect' else
                             "lateral-boot-materials" if source_id.startswith('creator-walk-right-transitions') else "action-subset",
                         "prompt": 'implementation/fhd-player/directional/prompts/' + source_id + '.prompt.txt',
                         "output": (OUT / (name + '_' + str(m['frame']) + '.png')).relative_to(ROOT).as_posix()}
                entry['prompt_sha256'] = import_art.sha((ROOT / entry['prompt']).read_bytes())
                if job.get('flip_horizontal'):
                    # Match the creator repo's right-to-left mirror workflow;
                    # reflect the full generated pose, including its foot pivot.
                    entry['source_canvas_pivot_xy'] = list(pivot)
                    entry['pivot_xy'] = [canvas[0] - 1 - pivot[0], pivot[1]]
                    entry['flip_horizontal'] = True
                entries.append(entry)
    return entries


def render_selected(entry):
    """Cut the selected original alpha component; never paint replacement art."""
    raw = Image.open(ROOT/entry['source']).convert('RGBA')
    left,top,width,height = entry['sheet_cell_xywh']
    cell = raw.crop((left,top,left+width,top+height))
    selected = measure(cell,entry['action'])
    assert selected['selection_sha256'] == entry['source_selection_sha256']
    pixels = np.array(cell)
    pixels[:,:,3][~selected['selection']] = 0
    cell = Image.fromarray(pixels)
    x,y,w,h = entry['crop_xywh']
    crop = cell.crop((x-left,y-top,x-left+w,y-top+h))
    size = tuple(max(1,round(v*entry['content_scale'])) for v in crop.size)
    crop = crop.resize(size,Image.Resampling.NEAREST)
    colors = tuple(import_art.palette.COLOURS[k] for k in entry['palette_keys'])
    cache,reduced = {},[]
    for sample_index, (r,g,b,a) in enumerate(import_art.samples(crop)):
        if a < entry['alpha_threshold']:
            reduced.append((0,0,0,0))
        else:
            rgb = (r,g,b)
            allowed = colors
            boot_material = (entry['material_ramp_rule'] == 'lateral-boot-materials'
                             and sample_index // size[0] >= entry['content_anchor_xy'][1] - 14
                             and r > 75 and g > 45 and r > b*1.5 and g > b*.9)
            if boot_material:
                # Keep warm generated leather in the project's brown ramp;
                # unrestricted nearest-color mapping can otherwise choose hat gold.
                allowed = tuple(COLOURS[k] for k in ('soil_dark','wood_dark','wood','wood_light'))
            elif entry['material_ramp_rule'] == 'saturated-red-prop' and not (r > g*2.5 and r > b*2.5):
                allowed = colors[:-3]
            cache_key = (rgb, boot_material)
            if cache_key not in cache:
                cache[cache_key] = min(allowed,key=lambda c:sum((c[i]-rgb[i])**2 for i in range(3)))
            reduced.append((*cache[cache_key],255))
    crop.putdata(reduced)
    canvas = Image.new('RGBA',tuple(entry['canvas_wh']))
    cut_pivot = entry.get('source_canvas_pivot_xy', entry['pivot_xy'])
    offset = tuple(cut_pivot[i]-entry['content_anchor_xy'][i] for i in range(2))
    assert all(offset[i] >= 0 and offset[i]+size[i] <= canvas.size[i] for i in range(2)),entry['id']
    canvas.alpha_composite(crop,offset)
    if entry.get('flip_horizontal'):
        canvas = canvas.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    return canvas


def build(check=False, partial=False):
    OUT.mkdir(parents=True, exist_ok=True)
    entries = recipes(partial)
    groups = {}
    for entry in entries:
        if 'review_source' in entry:
            content = (ROOT / entry['output']).read_bytes()
            assert import_art.sha(content) == entry['output_sha256']
        else:
            image = render_selected(entry)
            assert image.getchannel('A').getextrema() == (0,255)
            content = import_art.png(image)
            entry['output_sha256'] = import_art.sha(content)
            path = ROOT / entry['output']
            if check:
                assert path.read_bytes() == content, path
            else:
                path.write_bytes(content)
        groups.setdefault(entry['animation'], []).append(entry)
    for name, group in groups.items():
        expected = 3 if name.startswith('idle_') else 8 if name.startswith(('walk_','run_')) else 4
        assert sorted(e['frame'] for e in group) == list(range(expected)), name
        if expected != 3:
            assert len({e['output_sha256'] for e in group}) == expected, (name,'duplicate poses')
        if name.startswith(('walk_','run_')):
            assert len({import_art.sha(Image.open(ROOT/e['output']).crop((18,66,78,94)).tobytes())
                        for e in group}) == 8, (name,'duplicate leg phases')
        if name in ('walk_west', 'walk_east'):
            # Regression: the two contact halves must exchange which boot leads.
            # Eight distinct PNGs alone previously passed with the same leg ahead.
            direction_sign = -1 if name.endswith('west') else 1
            for phase, forward_sign in ((0, direction_sign), (1, direction_sign),
                                        (3, -direction_sign), (4, -direction_sign),
                                        (5, -direction_sign), (7, direction_sign)):
                entry = next(e for e in group if e['frame'] == phase)
                pixels = np.array(Image.open(ROOT / entry['output']))
                yy, xx = np.indices(pixels.shape[:2])
                leather = np.zeros(pixels.shape[:2], dtype=bool)
                for material in ('soil_dark','wood_dark','wood','wood_light'):
                    leather |= (pixels[:, :, :3] == COLOURS[material]).all(2)
                # Include raised heels; compare full material shading rather
                # than assigning every medium-brown highlight to the near foot.
                foot_region = leather & (yy >= 72) & (pixels[:, :, 3] > 0)
                left = foot_region & (xx < pixels.shape[1] / 2)
                right = foot_region & (xx >= pixels.shape[1] / 2)
                assert left.any() and right.any(), (name, phase, 'missing left/right boot materials')
                luminance = pixels[:, :, :3].astype(np.int32).sum(2)
                separation = float(luminance[right].mean() - luminance[left].mean())
                assert separation * forward_sign > 0, (name, phase, 'same leg leads both contact halves')
        # Inspect actual full silhouette too: disconnected hat colors must not
        # create a larger back-view farmer despite a valid numeric recipe.
        if name.startswith(('idle_','walk_','run_')):
            heights = [Image.open(ROOT/e['output']).getbbox()[3]-Image.open(ROOT/e['output']).getbbox()[1]
                       for e in group]
            assert max(heights) <= 61, (name,'full native silhouette scale drift',heights)
    if not partial:
        assert len(entries) == 284 and len(groups) == 64, (len(entries),len(groups))
    manifest = {"version":1,"integration":"preview only; awaiting user validation",
                "native_body_height":60,"fhd_body_height":120,"frames":entries}
    data = (json.dumps(manifest,indent=2)+'\n').encode()
    target = HERE / 'review-contract.json'
    if check:
        assert target.read_bytes() == data, 'Source/measurement contract drift'
    else:
        target.write_bytes(data)
    spec = {"groups": []}
    for action in LABELS:
        animations = [action+'_'+d for d in DIRECTIONS]
        if not all(a in groups for a in animations):
            continue
        spec['groups'].append({"action":action,"label":LABELS[action],"columns":[
            {"direction":d,"frames":[{"path":"res://"+e['output'],"pivot":e['pivot_xy']}
              for e in sorted(groups[a],key=lambda e:e['frame'])]} for d,a in zip(DIRECTIONS,animations)],
            "seconds":groups[animations[0]][0]['seconds']})
    if not check:
        (HERE/'playback.json').write_bytes((json.dumps(spec,indent=2)+'\n').encode())
        contacts(groups)
    print('SOURCE CHECK:',len(entries),'frames,',len(groups),'directional animations; source hashes, native alpha, unique poses and legs checked')
    return spec


def contacts(groups):
    target = HERE/'contacts'
    target.mkdir(exist_ok=True)
    for name, group in groups.items():
        group = sorted(group,key=lambda e:e['frame'])
        page = Image.new('RGB',(len(group)*260,284),(54,49,61))
        draw = ImageDraw.Draw(page)
        for n,e in enumerate(group):
            im = Image.open(ROOT/e['output']).convert('RGBA').resize(tuple(v*2 for v in e['canvas_wh']),Image.Resampling.NEAREST)
            at = (n*260+130-e['pivot_xy'][0]*2,244-e['pivot_xy'][1]*2)
            page.paste(im,at,im)
            draw.text((n*260+8,8),name+' '+str(e['frame']),fill=(232,224,207))
            draw.line((n*260+12,244,n*260+248,244),fill=(112,96,76))
        page.save(target/(name+'.png'))


def encode():
    target = HERE/'gifs'
    target.mkdir(exist_ok=True)
    spec = json.loads((HERE/'playback.json').read_text())
    overview = []
    for group in spec['groups']:
        action = group['action']
        paths = sorted((HERE/'captures'/action).glob('frame-*.png'))
        assert len(paths) == 192, (action,'actual renderer captures missing')
        frames = [Image.open(p).convert('RGB') for p in paths]
        overview.extend(frames[:96])
        assert all(im.size == (1040,288) for im in frames)
        sample = Image.new('RGB',(1040,288*24))
        for n in range(24):
            sample.paste(frames[n*8],(0,n*288))
        palette = sample.quantize(colors=128,dither=Image.Dither.NONE)
        indexed = [im.quantize(palette=palette,dither=Image.Dither.NONE) for im in frames]
        path = target/(action+'-horizontal.gif')
        indexed[0].save(path,save_all=True,append_images=indexed[1:],duration=40,loop=0,disposal=2,optimize=False)
        with Image.open(path) as gif:
            total = 0
            for n in range(gif.n_frames):
                gif.seek(n)
                total += gif.info['duration']
            assert total == 7680, (action,total)
        print('GIF:',action,'4 directions, 1040x288, 7.68 seconds')
    # One horizontal gallery clip cycles through all sixteen categories.
    samples = Image.new('RGB',(1040,288*len(spec['groups'])*4))
    for n,group in enumerate(spec['groups']):
        for phase in range(4):
            samples.paste(overview[n*96+phase*12],(0,(n*4+phase)*288))
    palette = samples.quantize(colors=128,dither=Image.Dither.NONE)
    indexed = [im.quantize(palette=palette,dither=Image.Dither.NONE) for im in overview]
    indexed[0].save(HERE/'todas-animacoes-horizontal.gif',save_all=True,append_images=indexed[1:],
                    duration=40,loop=0,disposal=2,optimize=False)
    print('OVERVIEW GIF:',len(overview)*40,'ms; all groups in one horizontal four-direction playback')


def gallery():
    """A local review page loads only one GIF at a time and keeps physical size."""
    spec = json.loads((HERE/'playback.json').read_text())
    groups = spec['groups']
    data = json.dumps([{**g,'count':len(g['columns'][0]['frames']),
                       'version':import_art.sha((HERE/'gifs'/(g['action']+'-horizontal.gif')).read_bytes())[:12]}
                      for g in groups],ensure_ascii=False)
    page = '''<!doctype html><html lang="pt-BR"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Farmer — validação de animações</title>
<style>body{margin:0;background:#17151c;color:#ece3d3;font:16px system-ui,sans-serif}main{max-width:1120px;margin:auto;padding:36px 24px}h1{font-size:30px;margin:8px 0}p{color:#c2b5a1;line-height:1.6}nav{display:flex;gap:8px;flex-wrap:wrap;margin:22px 0}button,a.download{background:#35303e;color:#ece3d3;border:1px solid #51485b;padding:10px 14px;border-radius:8px;cursor:pointer;text-decoration:none}button[aria-pressed=true]{background:#b88c42;color:#19151a;border-color:#b88c42}.preview{overflow:auto;background:#29252f;border-radius:12px;padding:18px 0}img{display:block;margin:auto;image-rendering:pixelated;max-width:none}.tools{display:flex;gap:12px;align-items:center;margin:18px 0;flex-wrap:wrap}small{color:#c2b5a1}#contact{display:flex;gap:12px;flex-wrap:wrap}#contact a{color:#dbb875}footer{border-top:1px solid #3f3748;margin-top:30px;padding-top:16px}</style>
<main><small>PERSONAGEM APROVADO · PRÉVIA PARA VALIDAÇÃO</small><h1>Todas as direções. Todas as atividades.</h1>
<p>Frente, esquerda, costas e direita lado a lado. Caminhada e corrida têm oito quadros por direção; cada atividade tem quatro poses. Estes arquivos aguardam sua validação antes de entrar no jogo.</p>
<nav id="choices"></nav><h2 id="title"></h2><div class="preview"><img id="animation" width="1040" height="288" alt="Animações nas quatro direções"></div>
<div class="tools"><button id="size" aria-pressed="true">Tamanho previsto em FHD: 120 px de altura</button><a id="download" class="download" download>Baixar este GIF</a><small id="details"></small></div>
<p>Os pixels são ampliados exatamente em 2×, sem suavização. Você pode alternar para a escala nativa de 60 px. Em telas menores, role a prévia para os lados para conservar o tamanho dos pixels.</p>
<div id="contact"></div><footer><a class="download" href="todas-animacoes-horizontal.gif" download>Baixar GIF geral</a><p>O GIF geral percorre as 16 categorias. Os GIFs individuais repetem a atividade escolhida. Fontes, prompts e receitas estão guardados nesta pasta e em assets/art_source/player-fhd/directional.</p></footer></main>
<script>const groups=__DATA__;const names={south:'Frente',west:'Esquerda',north:'Costas',east:'Direita'};const choices=document.querySelector('#choices'),image=document.querySelector('#animation');function select(g){document.querySelector('#title').textContent=g.label;image.src='gifs/'+g.action+'-horizontal.gif?v='+g.version;document.querySelector('#download').href=image.src;document.querySelector('#details').textContent=g.count+' quadros por direção · 4 direções';document.querySelectorAll('nav button').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.action===g.action)));document.querySelector('#contact').replaceChildren(...g.columns.map(c=>{const a=document.createElement('a');a.href='contacts/'+g.action+'_'+c.direction+'.png?v='+g.version;a.textContent='Ver quadros: '+names[c.direction];a.target='_blank';return a}));}for(const g of groups){const b=document.createElement('button');b.textContent=g.label;b.dataset.action=g.action;b.setAttribute('aria-pressed','false');b.onclick=()=>select(g);choices.append(b);}document.querySelector('#size').onclick=function(){const large=this.getAttribute('aria-pressed')==='true';this.setAttribute('aria-pressed',String(!large));image.width=large?520:1040;image.height=large?144:288;this.textContent=large?'Escala nativa: 60 px de altura':'Tamanho previsto em FHD: 120 px de altura';};select(groups[0]);</script></html>'''
    (HERE/'index.html').write_bytes(page.replace('__DATA__',data).encode('utf-8'))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--check',action='store_true')
    parser.add_argument('--partial',action='store_true')
    parser.add_argument('--encode',action='store_true')
    flags = parser.parse_args()
    build(flags.check,flags.partial)
    if flags.encode:
        encode()
        gallery()
