"""Prepare measured-reference inspection and small isolated icon requests."""
from pathlib import Path
import json,hashlib,re,shutil
from PIL import Image,ImageDraw
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
for d in ['raw','native','preview','rejected']:(HERE/d).mkdir(parents=True,exist_ok=True)
ids=['gun_tower','auto_crossbow','flame_tower','mortar','mine','fence','wall','barricade','flare','start','speed','dawn_moon']
objects={
'gun_tower':'The dark iron gun barrel on its timber turret head and a stub of the trestle, barrel angled to the upper right as in the identity master. Show the weapon head, not the whole tall tower.',
'auto_crossbow':'The crossbow seen from front-left: wide wooden limbs, string and one bold bolt pointing upper right. Show the bow mechanism, not a whole tower.',
'flame_tower':'The squat RED fuel tank with one brass nozzle pipe pointing upper right, one small local orange flame tongue at its nozzle tip, no glow.',
'mortar':'Squat black iron mortar tube on its wooden carriage, open mouth tilted upper right. Broad tube silhouette, not a thin gun.',
'mine':'Round GREY metal mine disc with its RED pressure button, seen from above at three-quarter. Button bold enough to remain visible at8pixels.',
'fence':'Two warm timber posts with iron bands joined by two horizontal rails.',
'wall':'A short grey stone block wall, three courses, broad light top plane.',
'barricade':'Crossed timber logs braced by a plank as on the identity master.',
'flare':'Hand-held red signal flare tube tilted45degrees, burning pale-yellow/orange head and only2or3 chunky attached spark pixels, no glow.',
'start':'One curved pale-bone signal horn with a gold band, wide bell toward upper right. No START text.',
'speed':'TWO solid right-pointing fast-forward chevrons in pale gold with dark ink outline. Point EAST; do not mirror. No text or numerals.',
'dawn_moon':'A pale moon half sunk behind a straight dark1pixel horizon line: SETTING MOON, flat horizontal lower cut, upper semicircle. Distinct from a crescent or full disc.'}
paths=[ROOT/'assets/art_source/ui/wood.png',ROOT/'docs/reference-sheet.png']
for name in ['wood','iron','incendiary','money']:paths += [ROOT/f'sprites/ui/icon_{name}.png',ROOT/f'sprites/ui/hud_{name}.png']
for asset in ids[:8]:
    paths += [ROOT/f'assets/art_source/defences/{asset}/{"whole" if asset in ["fence","wall"] else "master"}.png',ROOT/f'sprites/buildings/{asset+"_join_10" if asset in ["fence","wall"] else asset}.png']
paths += [ROOT/'sprites/effects/flare_1.png',ROOT/'sprites/ui/panel.png',ROOT/'sprites/ui/button_normal.png',ROOT/'implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png']
refs=[]
for i in range(0,len(paths),5):
    sheet=Image.new('RGBA',(1000,5*220),(29,39,42,255));d=ImageDraw.Draw(sheet)
    for j,p in enumerate(paths[i:i+5]):
        im=Image.open(p).convert('RGBA');d.text((8,j*220+5),p.relative_to(ROOT).as_posix()+' '+str(im.size),fill=(230,220,197))
        if im.width<=80:
            sheet.alpha_composite(im,(8,j*220+28));sheet.alpha_composite(im.resize((im.width*4,im.height*4),Image.Resampling.NEAREST),(125,j*220+28))
        else:
            scaled=im.copy();scaled.thumbnail((970,180),Image.Resampling.NEAREST);sheet.alpha_composite(scaled,(8,j*220+28))
        refs.append({'path':p.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'role':'Existing UI style or defence identity / scale reference'})
    sheet.save(HERE/f'preview/references-{i//5+1:02}.png')
(HERE/'references.json').write_text(json.dumps(refs,indent=2)+'\n')
text=(ROOT/'implementation/sprites/generation/PROMPTS.md').read_text(encoding='utf-8')
base=re.search(r'## BASE\s+```text\s+(.*?)```',text,re.S).group(1)
base=base.replace('{specific object or animation, asset ID, required states}','ONE isolated compact inventory icon, one static pose').replace('{Image 1: approved style reference; Image 2: identity/shape master;\nImage 3 if applicable: edit target. Specify each role explicitly.}','Image1 approved wood icon STYLE only; Image2 when supplied defence IDENTITY; last image approved GAME STYLE only').replace('{width}','16').replace('{height}','16').replace('{x}','8').replace('{y}','8').replace('{true transparent background for isolated sprites, or fully\nopaque edge-to-edge material for terrain}','true transparent background around the complete isolated icon')
jobs=[]
for asset in ids:
    references=[str(ROOT/'assets/art_source/ui/wood.png')]
    if asset in ids[:8]:references.append(str(ROOT/f'assets/art_source/defences/{asset}/{"whole" if asset in ["fence","wall"] else "master"}.png'))
    elif asset=='flare':references.append(str(ROOT/'sprites/effects/flare_1.png'))
    references.append(str(ROOT/'docs/reference-sheet.png'))
    prompt=base+'\nICON: Create ONE '+asset+' icon. '+objects[asset]+'''\nReadable at actual tiny HUD scale, coloured1pixel outline and only2or3 material planes. No labels, numbers, enclosing panel, ground shadow or unrelated objects.
Native contract: one centred complete object with generous transparent outer space. Import targets16x16(maximum visible14) and separate10x10(maximum visible8) compactHUD. SAME source and SAME crop for both. Bold simple silhouette, few joined colour clusters, only2or3 material planes. Compact features must survive at EIGHT visible pixels. No hatching, scattered crumbs, distant fragments, floor, cast shadow, glow, labels, lettering, numerals, backdrop or extra objects. Approximately square source framing; never clip the silhouette.\n'''
    stem=asset+'-r1';args={'prompt':prompt,'referenced_image_paths':references,'transparent_background':True}
    for suffix,data in [('.prompt.txt',prompt),('.request.json',json.dumps(args,indent=2)+'\n')]:
        target=HERE/f'raw/{stem}{suffix}';assert not target.exists();target.write_text(data,encoding='utf-8')
    jobs.append({'stem':stem,'revision':1,'asset':asset,'args':args})
(HERE/'generation-jobs.json').write_text(json.dumps(jobs,indent=2)+'\n')
shutil.copyfile(ROOT/'implementation/backlog/deliveries/A001-farmer-bed/ingest.py',HERE/'ingest.py')
(HERE/'review-log.txt').write_text('2026-10-07 | Owner requested all packs without intermediate approvals. Final review pending.\nGun tower first for an internally inspected identity/style master. Each item gets a single raw source for both cuts.\n')
(HERE/'contract.json').write_text(json.dumps({'pack':'A005','slug':HERE.name,'title':'Night hotbar and HUD icons','date':'2026-10-07','status':'generating','palette_mode':'A','runtime_integrated':False,'frames_expected':24,'planned_files':[{'anim':prefix+'_'+asset,'dir':'none','frames':1,'poses':[objects[asset]],'canvas_wh':[size,size],'pivot_xy':[size//2,size//2],'draw_scale':1,'frame_seconds':1,'loop':False,'mirror':'none','runtime_name':prefix+'_'+asset,'points':{}} for asset in ids for prefix,size in [('icon',16),('hud',10)]]},indent=2)+'\n')
