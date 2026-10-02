"""Catalogue every committed runtime image and compose review-only contact sheets."""
from pathlib import Path
import collections, hashlib, json, subprocess, sys
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'tools'))
import art_ownership, import_art

def sha(path):
    return hashlib.sha256((ROOT/path).read_bytes()).hexdigest()

def main():
    data = import_art.load_manifest()
    import_art.validate_coverage(data)
    entries = {e['id']: e for e in data['assets']}
    outputs = {e['output']: e for e in entries.values()}
    owners = art_ownership.registry()
    def lineage(entry):
        if 'source' in entry:
            return [dict(source=entry['source'],source_sha256=entry['source_sha256'],prompt=entry['prompt'],prompt_sha256=entry['prompt_sha256'])]
        parents = [entry['input']] + [part['input'] for part in entry.get('parts',[]) if part['input'] != entry['input']]
        leaves = {}
        for parent in parents:
            for leaf in lineage(entries[parent]):
                leaves[leaf['source']] = leaf
        return sorted(leaves.values(), key=lambda leaf:leaf['source'])
    rows, aliases = [], []
    for path, owner in sorted(owners.items()):
        im = Image.open(ROOT/path).convert('RGBA')
        entry = outputs.get(path)
        row = dict(output=path,owner=owner,canvas_wh=list(im.size),visible_xywh=None,sha256=sha(path))
        box = im.getbbox()
        if box:
            row['visible_xywh'] = [box[0],box[1],box[2]-box[0],box[3]-box[1]]
        assert box is not None, 'Empty runtime texture: '+path
        if entry:
            assert row['sha256']==entry['output_sha256']
            row.update({k:entry[k] for k in ('id','pivot_xy','animation','frame','seconds','loop','generation_task')})
            row['sources'] = lineage(entry)
            row['operation'] = entry.get('operation','source')
            for key in ('alias_of','variant_of','input','parts','muzzle_xy','muzzles_xy','windows_xy','light_xy','smoke_xy','bubble_xywh'):
                if key in entry:
                    row[key] = entry[key]
            assert set(im.getchannel('A').tobytes()) <= {0,255}, 'Alpha halo: '+path
            if 'alias_of' in entry:
                canonical = entries[entry['alias_of']]
                assert (ROOT/path).read_bytes()==(ROOT/canonical['output']).read_bytes(), 'Alias is not byte-exact'
                aliases.append(dict(alias=path,canonical=canonical['output'],reason='Reviewed legacy compatibility name; canonical authored frame is used for playback'))
        else:
            placement='UI top-left/nine-patch'
            if path=='sprites/terrain/atlas.png':
                placement='Source-exact TileSet lookup assembled from accepted raster tiles'
            elif path=='sprites/actors/placeholder.png':
                placement='Unused legacy ASCII output; no src/ or scenes/ reference; preserved rather than deleting accepted files'
                row['unused_legacy_placeholder']=True
            row.update(id=path.removeprefix('sprites/').removesuffix('.png'),pivot_xy=None,animation=None,frame=None,seconds=None,loop=False,sources=[dict(source='tools/gen_sprites.py',source_sha256=sha('tools/gen_sprites.py'))],placement=placement)
        rows.append(row)
    assert len(rows)==468 and sum(r['owner']=='raster' for r in rows)==447
    groups = collections.defaultdict(list)
    for row in rows:
        groups[row['id'].split('/')[0]].append(row)
    pages=[]
    for family, items in sorted(groups.items()):
        regular=[r for r in items if r['canvas_wh'][0]<=96 and r['canvas_wh'][1]<=64]
        oversized=[r for r in items if r not in regular]
        for number,start in enumerate(range(0,len(regular),30)):
            selected=regular[start:start+30]
            page=Image.new('RGBA',(720,540),(36,34,44,255))
            draw=ImageDraw.Draw(page)
            for i,row in enumerate(selected):
                x,y=(i%6)*120,(i//6)*108
                for yy in range(y+18,y+92,8):
                    for xx in range(x,x+116,8):
                        if ((xx-x)+(yy-y-18))//8%2==0:
                            draw.rectangle((xx,yy,xx+7,yy+7),fill=(102,101,110,255))
                name=row['id'].split('/',1)[-1]
                draw.text((x+2,y+2),name[:19],fill=(239,232,205,255))
                im=Image.open(ROOT/row['output']).convert('RGBA')
                page.alpha_composite(im,(x+(116-im.width)//2,y+20))
                pivot=row['pivot_xy']
                label=f'{im.width}x{im.height} p{pivot}' if pivot else f'{im.width}x{im.height} '+('unused' if row.get('unused_legacy_placeholder') else 'UI')
                draw.text((x+2,y+96),label,fill=(239,232,205,255))
            native=f'contacts-{family}-{number:02}-native.png'
            zoom=f'contacts-{family}-{number:02}-3x.png'
            page.save(HERE/native)
            page.resize((2160,1620),Image.Resampling.NEAREST).save(HERE/zoom)
            pages.append(dict(native=native,nearest_3x=zoom,outputs=[r['output'] for r in selected]))
        for number,row in enumerate(oversized):
            im=Image.open(ROOT/row['output']).convert('RGBA')
            native=f'contacts-{family}-large{number}-native.png';zoom=f'contacts-{family}-large{number}-3x.png'
            im.save(HERE/native);im.resize((im.width*3,im.height*3),Image.Resampling.NEAREST).save(HERE/zoom)
            pages.append(dict(native=native,nearest_3x=zoom,outputs=[row['output']]))
    assert {output for page in pages for output in page['outputs']} == set(owners)
    (HERE/'catalogue.json').write_text(json.dumps(dict(owners=dict(collections.Counter(owners.values())),outputs=rows,aliases=aliases,contact_pages=pages),indent=2)+'\n',encoding='utf-8',newline='\n')
    print(f'PASS: {len(rows)} registered outputs, {len(aliases)} exact aliases, {len(pages)} native/3x contact pages')

if __name__=='__main__':
    main()
