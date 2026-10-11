"""Pack-specific review compositions, provenance and checks; no generated art is painted."""
from pathlib import Path
import json,hashlib
from PIL import Image,ImageDraw

def enrich(here,root,frames,recipes,outputs,contract,checks,add,night):
    pack=here.name[:4];parts=[]
    def strip(label,entries):
        width=sum(im.width+12 for name,im in entries)+8;height=max([frame.height for name,frame in entries]+[16]);im=Image.new('RGBA',(max(8,width),height+42),(26,24,48,255));draw=ImageDraw.Draw(im);x=4
        for name,frame in entries:
            im.alpha_composite(frame,(x,8));draw.text((x,height+16),name[:5],fill=(230,221,197));x+=frame.width+12
        add('preview/'+label+'.png',im)
        parts.append('<section><h2>'+label.replace('-',' ')+'</h2><img src="preview/'+label+'.png"><br><img src="preview/'+label+'.png" width="'+str(im.width*4)+'"></section>')
    def selected(names,prefix='icon'):
        result=[]
        for name in names:
            key=prefix+'_'+name
            if key in frames:result.append((name,frames[key]))
            elif (root/f'sprites/ui/{key}.png').exists():result.append((name,Image.open(root/f'sprites/ui/{key}.png').convert('RGBA')))
        return result
    # Verify every source and the exact request record, and include every input image.
    valid=True;transparent=True;unclipped=True;input_refs=list(contract['references'])
    for stem in sorted({r['stem'] for r in recipes}):
        source=here/f'raw/{stem}.png';call=json.loads((here/f'raw/{stem}.call.json').read_text());request=json.loads((here/f'raw/{stem}.request.json').read_text())
        valid &= call['arguments']==request and call['raw_sha256']==hashlib.sha256(source.read_bytes()).hexdigest() and call['arguments']['prompt']==(here/f'raw/{stem}.prompt.txt').read_text(encoding='utf-8')
        im=Image.open(source).convert('RGBA');transparent &= im.getchannel('A').getextrema()==(0,255)
        box=im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox();unclipped &= box is not None and box[0]>0 and box[1]>0 and box[2]<im.width and box[3]<im.height
        for ref in call['input_images']:
            path=Path(ref.get('retained_copy_path',ref['path']));path=path if path.is_absolute() else here/path
            valid &= path.exists() and hashlib.sha256(path.read_bytes()).hexdigest()==ref['sha256']
            try:normalized=path.relative_to(root).as_posix()
            except ValueError:normalized=str(path)
            input_refs.append({'path':normalized,'sha256':ref['sha256'],'role':ref['role']})
    contract['references']=list({(r['path'],r['sha256']):r for r in input_refs}.values())
    checks.update(provenance_hashes_match=bool(recipes) and bool(valid),raw_has_real_alpha=bool(recipes) and bool(transparent),source_objects_unclipped=bool(recipes) and bool(unclipped))
    sizes={s:[im for im in frames.values() if im.size==(s,s)] for s in [10,16]}
    if pack!='A011':
        checks['ui_density_and_colour']=bool(frames) and all(sum(p[3]>0 for p in im.getdata())>(24 if im.width==16 else 7) and len({p[:3] for p in im.getdata() if p[3]})>=2 for key,im in frames.items() if key!='truffle_spot')
    checks['all_same_size_outputs_distinct']=bool(frames) and all(len({im.tobytes() for im in group})==len(group) for group in sizes.values())
    for file in contract['files']:
        file['runtime_name']='sprites/'+('props/' if file['anim']=='truffle_spot' else 'ui/')+file['anim']+'.png'
    if pack=='A005':
        towers=[frames.get('hud_'+n) for n in ['gun_tower','auto_crossbow','flame_tower','mortar']]
        checks['four_weapon_silhouettes_distinct']=all(t is not None for t in towers) and len({t.getchannel('A').tobytes() for t in towers if t is not None})==4
    elif pack=='A010':
        strip('seasons',selected(['spring','summer','autumn','winter']))
        moons=selected(['full_moon','boss_night','calm_night'])
        dawn=root/'implementation/backlog/deliveries/A005-night-icons/native/icon_dawn_moon/none/01.png'
        if dawn.exists():moons.append(('dawn',Image.open(dawn).convert('RGBA')))
        strip('night-marks-and-dawn',moons)
        strip('mock-forecast',selected(['spring','full_moon','boss_night']))
        shapes=[frames.get('hud_'+n) for n in ['spring','summer','autumn','winter']]
        checks['season_silhouettes_distinct']=all(t is not None for t in shapes) and len({t.getchannel('A').tobytes() for t in shapes if t is not None})==4
        marks=[frames.get('hud_'+n) for n in ['full_moon','boss_night','calm_night']]
        checks['night_marks_distinct']=all(t is not None for t in marks) and len({t.getchannel('A').tobytes() for t in marks if t is not None})==3
        strip('calendar-resource-style',selected(['wood','tech','energy','carrot','wheat']))
    elif pack=='A011':
        strip('forecast-heads',[(n.replace('head_',''),im) for n,im in frames.items()])
        baseline=all(im.getbbox()[3]==15 for im in frames.values());checks['bust_baseline_row14']=bool(frames) and baseline
        giant=frames.get('head_giant');tank=frames.get('head_tank')
        checks['giant_visible14x14']=giant is not None and giant.getbbox()[2]-giant.getbbox()[0]==14 and giant.getbbox()[3]-giant.getbbox()[1]==14
        checks['tank_visible_width13']=tank is not None and tank.getbbox()[2]-tank.getbbox()[0]==13
        pairs=[]
        for kind in ['walker','runner','tank','breaker','giant']:
            head=frames.get('head_'+kind)
            if head:pairs.append((kind,head))
            body=root/f'sprites/enemies/{kind}_walk_0.png'
            if body.exists():pairs.append(('body',Image.open(body).convert('RGBA')))
        strip('forecast-body-identity',pairs)
        contract['exemptions']['grounded_on_pivot']='UI busts do not have feet; their cut shoulders must end on row14, checked separately.'
    elif pack=='A020':
        for label,names in [('ingots',['copper','gold','iron']),('gold-vs-coins',['gold','money']),('coal-vs-powder-stone',['coal','gunpowder','stone']),('hardwood-vs-wood',['hardwood','wood']),('hay-straw-wheat',['hay','straw','wheat'])]:
            for prefix in ['icon','hud']:strip(label+'-'+prefix,selected(names,prefix))
        gold=frames.get('icon_gold');compact=frames.get('hud_coal');coal=frames.get('icon_coal');steel={(110,108,120),(140,138,150)}
        checks['gold_uses_no_flame_orange']=gold is not None and not any(p[:3]==(242,160,60) for p in gold.getdata() if p[3])
        checks['coal_facets_readable']=coal is not None and compact is not None and sum(p[:3] in steel and p[3]>0 for p in coal.getdata())>=3 and sum(p[:3] in steel and p[3]>0 for p in compact.getdata())>=1
        ingots=[frames.get('icon_'+n) for n in ['copper','gold']];checks['ingot_size_matches_iron']=all(t is not None for t in ingots) and all(t.getbbox()[2]-t.getbbox()[0]==14 and abs(t.getbbox()[3]-t.getbbox()[1]-11)<=1 for t in ingots if t is not None)
    elif pack=='A029':
        for prefix in ['icon','hud']:strip('animal-product-style-'+prefix,selected(['egg','milk','wool','truffle','meat','food','stone','gunpowder'],prefix))
        spot=frames.get('truffle_spot');checks['truffle_spot_bounds']=spot is not None and 11<=spot.getbbox()[2]-spot.getbbox()[0]<=13 and 7<=spot.getbbox()[3]-spot.getbbox()[1]<=9 and spot.getbbox()[3]==14 and abs((spot.getbbox()[0]+spot.getbbox()[2])/2-8)<=1
        if spot:
            for key in ['day','world-night','metadata']:
                parts.append('<figure>truffle spot '+key+'<br><img src="preview/truffle_spot-'+key+'.png" width="64"></figure>')
            scene=Image.new('RGBA',(160,80));grass=Image.open(root/'sprites/terrain/grass.png').convert('RGBA')
            for y in range(0,80,16):
                for x in range(0,160,16):scene.alpha_composite(grass,(x,y))
            scene.alpha_composite(spot,(96,34))
            for x,name in [(112,'rock'),(128,'stump')]:scene.alpha_composite(Image.open(root/f'sprites/props/{name}.png').convert('RGBA'),(x,34))
            scene.alpha_composite(Image.open(root/'sprites/crops/tilled.png').convert('RGBA'),(80,32));scene.alpha_composite(Image.open(root/'implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png').convert('RGBA'),(40,12))
            add('preview/truffle-ground-day.png',scene);add('preview/truffle-ground-night.png',night(scene))
            parts.append('<section><h2>Truffle spot next to farmer and current resources</h2><img src="preview/truffle-ground-day.png" width="640"><img src="preview/truffle-ground-night.png" width="640"></section>')
    return ''.join(parts)
