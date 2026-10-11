"""Persist snow-cap variants from the inspected rock-cap master and leaf-only revisions."""
from pathlib import Path
import json
from PIL import Image,ImageDraw
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];jobs=[]
def save(stem,prompt,refs,revision):
    a={'prompt':prompt,'referenced_image_paths':[str(x) for x in refs],'transparent_background':True};(HERE/f'raw/{stem}.request.json').write_text(json.dumps(a,indent=2)+'\n',encoding='utf-8');(HERE/f'raw/{stem}.prompt.txt').write_text(prompt,encoding='utf-8');jobs.append({'folder':HERE.name,'stem':stem,'revision':revision,'args':a})
for stem,target,revision in [('tree_autumn-r4','tree_autumn-r3',4),('tree_b_autumn-r2','tree_b_autumn-r1',2)]:
    save(stem,'Use case: precise-object-edit. Image1 EXACT autumn tree target. ONE leaf-colour correction ONLY. Replace EVERY pale bright yellow/cream foliage highlight with DARKER subdued mustard-gold, RGB214,186,96 (#d6ba60) or darker. No leaf pixel can use flame_hot RGB246217122, no cream or pale yellow foliage remains. Restrained gold_light21418696 highlights ONLY, shadowsunchanged. Trunkandrootcolours stayexactlyunchanged. Keep exact1024x1536source canvas, all transparentmargins, position, size, outlines, branch/root geometry and all colouredclusters unchanged. Nevercrop,recenter,scale,add/removeleaves. NO fireorange, glow, particle, scene, background, shadow or lettering. True transparentalpha.\n',[HERE/f'raw/{target}.png'],revision)
for name,hosts in [('stump_snow',['stump']),('rock_b_snow',['rock_b']),('ore_snow',['ore']),('ore_b_snow',['ore_b']),('seam_snow',['seam']),('seam_b_snow',['seam_b']),('snow_cap',['ore','rock']),('snow_cap_2x2',['stump'])]:
    big=name=='snow_cap_2x2';refs=[ROOT/f'assets/art_source/props/{h}.png' for h in hosts]+[HERE/'raw/rock_snow-r1.png']
    prompt='Use case: stylized-concept. ONE isolated settled-snow cap only. '+''.join(f'Image{i+1} is {h} FIT reference only: neverdraw the host object, its colours, outline or ground. ' for i,h in enumerate(hosts))+f'Image{len(hosts)+1} is accepted snowcap STYLE reference. '
    prompt+='Just a LOW BROAD lumpy cushion of snow shaped to rest on the host summit. '+('Wider cap for the2x2hardwoodstump standin: finalnative32square, cap about19x5pixels, no tall mound. ' if big else 'Finalnative16square, cap about9x3pixels, no tall mound. ')
    prompt+='Aboutfourtimeswiderthantall, singlejoined8connectedform, lowthickpixelclusters, creamRGB232224207 top, palemoonRGB207214255 highlights, mutedcreamRGB184174154 underside, tiny stone_light140138150/night261848 edging. Noothercolours, holes, detachedflake/droplet, particles, hostbody, lettering, UI, scenery, groundshadow or glow. Sameorthographicthreequartertopdowncamera, neutralupperleftlight. No antialiasing, smoothgradient orsoftbrushtexture. Completeunclippedcapwithgeneroustrue-transparentmargins. Capmustcoveronlytopsurface, neverhangdownobjectside.\n'
    save(name+'-r1',prompt,refs,1)
recipes=json.loads((HERE/'recipes.json').read_text())
for stem in ['tree_spring-r1','tree_winter-r1','tree_b_spring-r1','tree_b_autumn-r1','tree_b_winter-r1','rock_snow-r1']:
    r=json.loads((HERE/f'preview/{stem}-recipe.json').read_text());recipes=[q for q in recipes if q['anim']!=r['anim']]+[r]
(HERE/'recipes.json').write_text(json.dumps(recipes,indent=2)+'\n');(HERE/'caps-and-foliage-jobs.json').write_text(json.dumps(jobs,indent=2)+'\n')
sheet=Image.new('RGBA',(len(jobs[2:])*150,280),(29,39,42,255));dr=ImageDraw.Draw(sheet)
for i,(name,hosts) in enumerate([('stump_snow',['stump']),('rock_b_snow',['rock_b']),('ore_snow',['ore']),('ore_b_snow',['ore_b']),('seam_snow',['seam']),('seam_b_snow',['seam_b']),('snow_cap',['ore','rock']),('snow_cap_2x2',['stump'])]):
    dr.text((i*150+4,4),name,fill=(232,224,207))
    for j,h in enumerate(hosts):
        im=Image.open(ROOT/f'assets/art_source/props/{h}.png').convert('RGBA');im.thumbnail((140,140),Image.Resampling.NEAREST);sheet.alpha_composite(im,(i*150+4,20+j*130))
sheet.save(HERE/'preview/cap-host-raw-reference-sheet.png');print(json.dumps({'jobs':len(jobs)}))
