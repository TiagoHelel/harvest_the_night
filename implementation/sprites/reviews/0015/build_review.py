"""Compose complete native/3x source-owned motion reviews; never edit source art."""
from pathlib import Path
import json
from PIL import Image,ImageDraw
ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent

def main():
    data = json.loads((ROOT/'assets/art_source/manifest.json').read_text())
    entries = [e for e in data['assets'] if e.get('generation_task')=='0015' and 'source' in e]
    for family in ('walker','runner','tank','breaker'):
        page = Image.new('RGBA',(384,264),(218,213,183,255))
        d = ImageDraw.Draw(page)
        for row,motion in enumerate(('master','walk','attack','death')):
            d.text((2,row*66+1), family+' '+motion,fill=(26,24,32,255))
            for e in [x for x in entries if x['enemy_family']==family and x['enemy_motion']==motion]:
                image = Image.open(ROOT/e['output']).convert('RGBA')
                x,y = e['frame']*80+30,row*66+16
                page.alpha_composite(image,(x,y))
                d.line((x+20,y+44,x+44,y+44),fill=(174,151,120,255))
        page.save(HERE/f'{family}-motions-native.png')
        page.resize((1152,792),Image.Resampling.NEAREST).save(HERE/f'{family}-motions-3x.png')
    silhouette = Image.new('RGBA',(320,110),(218,213,183,255));d=ImageDraw.Draw(silhouette)
    for i,family in enumerate(('walker','runner','tank','breaker')):
        image = Image.open(ROOT/f'sprites/enemies/{family}.png').convert('RGBA')
        black=Image.new('RGBA',image.size,(0,0,0,255));black.putalpha(image.getchannel('A'))
        silhouette.alpha_composite(image,(i*80+8,10));silhouette.alpha_composite(black,(i*80+8,60))
        d.text((i*80+10,0),family,fill=(26,24,32,255))
    silhouette.save(HERE/'silhouettes-native.png')
    silhouette.resize((960,330),Image.Resampling.NEAREST).save(HERE/'silhouettes-3x.png')
    (HERE/'measured-contract.json').write_text(json.dumps(entries,indent=2)+'\n',newline='\n')

if __name__=='__main__': main()
