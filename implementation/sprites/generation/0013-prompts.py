"""Save exact built-in tower identity briefs and fixed runtime contracts."""
from pathlib import Path
import json
import re

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
TEXT=(HERE/'PROMPTS.md').read_text(encoding='utf-8')

def brief(name):return re.search(r'## '+name+r'\s+```text\n(.*?)```',TEXT,re.S).group(1).strip()

SPECS={
 'gun_tower':dict(subject='A compact farm gun tower: tall cross-braced timber legs on a small stone footing, a small metal turntable and one clearly visible long horizontal gun barrel pointing upper-right. No operator, roof or enclosed cabin.',levels=['simple timber trestle with one modest iron gun barrel','stronger diagonal timber braces, iron corner straps and a visibly heavier gun receiver','compact reinforced stone/iron lower pedestal, stronger mechanical turntable and two parallel gun barrels; a different construction and weapon silhouette, not stacked posts'],body_wh=[[22,29],[24,34],[26,39]]),
 'flame_tower':dict(subject='A compact farm flamethrower tower: squat reinforced timber support, one conspicuous copper fuel tank, a clearly joined curved dark-metal pipe and short wide nozzle pointing upper-right. Idle nozzle is dark; no permanent flame.',levels=['single rounded copper tank, simple pipe and short dark nozzle on timber supports','iron-strapped copper tank, thicker visible supply pipe and reinforced nozzle mount','armored copper fuel housing, strong metal pump mechanism and a wider heavy burner nozzle on stone/iron footing'],body_wh=[[22,25],[24,30],[26,35]]),
 'mortar':dict(subject='A LOW, squat farm mortar: a broad small stone/timber base with a short heavy dark-metal tube tilted steeply upward toward upper-right and a clearly open round barrel mouth. It sits near the ground, not on a lookout tower.',levels=['simple broad timber carriage and one short thick upward-tilted tube','iron-strapped carriage, visible elevation wheel and heavier banded tube','compact stone/iron carriage, large elevation mechanism and broad armored mortar tube with reinforced collar; remain visibly low'],body_wh=[[24,20],[26,24],[28,28]]),
 'auto_crossbow':dict(subject='An automatic farm crossbow on a timber stand: very obvious broad wooden bow limbs, taut string, central metal bolt rail aimed upper-right and a visible small mechanical loading gear. It must read as a bow, never a gun or a roofed building.',levels=['simple timber stand, single broad wooden bow and visible bolt rail','iron-strapped braced stand, heavier bow limbs and conspicuous geared bolt feeder','reinforced compact stone/iron footing, broad laminated bow limbs and large gear-driven automatic bolt magazine; a stronger distinct bow mechanism'],body_wh=[[25,29],[26,34],[28,39]])}

def assemble(ident,level,request,roles):
 spec=SPECS[ident]
 base=brief('BASE')
 substitutions={
  '{specific object or animation, asset ID, required states}':request,
  '{Image 1: approved style reference; Image 2: identity/shape master;\nImage 3 if applicable: edit target. Specify each role explicitly.}':roles,
  '{width}':'32','{height}':'48','{x}':'16','{y}':'44',
  '{true transparent background for isolated sprites, or fully\nopaque edge-to-edge material for terrain}':'true transparent background'}
 for key,value in substitutions.items():base=base.replace(key,value)
 family=brief('TOWER').replace('{gun tower/flame tower/mortar/automatic crossbow}',ident.replace('_',' ')).replace('{1/2/3}',str(level)).replace('{whole/hurt/fire/wreck}','the explicitly requested state(s) below')
 return base+'\n\nFamily contract:\n'+family+'\n\nExact family: '+spec['subject']+'\nLevel '+str(level)+': '+spec['levels'][level-1]+'.\nNative intact body target approximately '+str(spec['body_wh'][level-1])+' pixels, on a 32x48 canvas; ground base centered at (16,44). Extra native space is for the weapon and its short localized firing cue. No baked ground shadows, grass, ground tile, labels, loose decorative objects, glow halos or smoke clouds. Keep a compact stable base and the upper-right weapon direction.\n'

if __name__=='__main__':
 plans=[]
 for ident,spec in SPECS.items():
  prompt=assemble(ident,1,'One isolated LEVEL 1 intact idle identity master for buildings/'+ident+'. Draw only this one complete stationary machine.','Image 1: original reference sheet, only the four defence icons for silhouette/function and farm materials, ignore text/scenery/other objects. Image 2: accepted farmhouse material, upper-left light and orthographic camera reference only; do not give this machine a roof.')
  path=HERE/('0013-'+ident+'-master.prompt.txt')
  if not path.exists() or not (HERE/('0013-'+ident+'-master-call.json')).exists():
   path.write_text(prompt.strip(),encoding='utf-8',newline='\n')
  plans.append(dict(id=ident,canvas_wh=[32,48],pivot_xy=[16,44],cell_offset_xy=[-8,-28],**spec,prompt=path.relative_to(ROOT).as_posix(),references=['docs/reference-sheet.png','assets/art_source/buildings/house/whole.png']))
 (HERE/'0013-plan.json').write_text(json.dumps(plans,indent=2)+'\n',encoding='utf-8',newline='\n')
 cues={'gun_tower':'a small attached amber muzzle flash at the gun tip; level 3 shows both barrels',
       'flame_tower':'a short compact orange/yellow flame attached directly to the nozzle; no large plume',
       'mortar':'a tiny attached warm firing puff at the open mortar mouth; retain the tube silhouette',
       'auto_crossbow':'the string released forward and one short bolt leaving the end of the rail; no gun flame or smoke'}
 for ident in SPECS:
  for level in (1,2,3):
   prompt=assemble(ident,level,'One compact 2 by 2 four-state sheet for LEVEL '+str(level)+' '+ident+', exactly FOUR complete separately spaced copies of the same machine. Top row: WHOLE idle, HURT. Bottom row: FIRE, WRECK. All four are authored drawings at identical camera, magnification and planted-base coordinates in their respective cells.','Image 1: accepted level 1 '+ident+' identity master; retain its materials, weapon direction, construction language and family identity while applying the specified level. Image 2: accepted farmhouse, warm timber/metal palette, upper-left light and orthographic camera only.')
   prompt+='\nFour-state sheet contract: Four isolated objects in a TWO ROW, TWO COLUMN square layout with large completely transparent horizontal AND vertical gutters. Every complete object including the flash stays inside its own cell, with at least 15 percent transparent side clearance. Keep an identical base center and bottom baseline in each virtual cell. WHOLE: the complete idle machine of the specified level, no flash. HURT: the same machine and base with deliberate broken support boards, exposed mechanism and local metal wear; preserve the barrel/bow identity and at least one sound planted support. FIRE: same complete WHOLE machine, with '+cues[ident]+'. WRECK: a low collapsed broken version of this exact level at the same ground base, identifiable weapon parts among the broken base, no standing full machine. Wreck must stay inside the intact machine width; no scattering across gutters. Keep whole/hurt/fire body proportions and planted supports constant. The tiny firing cue must fit inside the native 32x48 clearance; never enlarge every machine to accommodate a huge flash. Native reduction must preserve a clear weapon mechanism. No checkerboard, background glow, ground tile, shadow, labels or text.\n'
   path=HERE/('0013-'+ident+'-level-'+str(level)+'.prompt.txt')
   # Exact prompts of completed calls are immutable provenance.
   if not path.exists() or not (HERE/(path.name.replace('.prompt.txt','-call.json'))).exists():
    path.write_text(prompt.strip(),encoding='utf-8',newline='\n')
 print('Saved four identity prompts and twelve four-state level prompts')
