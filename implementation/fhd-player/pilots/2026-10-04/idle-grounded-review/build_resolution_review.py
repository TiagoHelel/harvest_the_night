"""Compare deterministic pixel sampling, preserving renderer frames and timing."""
from pathlib import Path
import json
from PIL import Image, ImageDraw
from build_preview import gif, label

HERE=Path(__file__).resolve().parent
DEST=HERE/'resolution-review'

def build():
    DEST.mkdir(exist_ok=True)
    frames=[]
    for phase in range(24):
        sheet=Image.new('RGB',(1440,1605),'#20292c');draw=ImageDraw.Draw(sheet)
        for level,factor in enumerate([1,2,4]):
            top=level*535
            label(draw,(12,top+10),f'{64//factor}px CHARACTER / {factor}x COARSER PIXELS / SAME SCREEN SIZE',20)
            for row,light in enumerate(['day','night']):
                y=top+45+row*240
                label(draw,(12,y),f'GODOT {light.upper()} / '+('IDLE' if phase<4 or phase>=20 else 'WALK'),16)
                for i,suffix in enumerate(['south','east','north','west','south_east','north_east','north_west','south_west']):
                    image=Image.open(HERE/f'runtime-captures/{light}_{suffix}_{phase:02}.png').convert('RGB').crop((38,0,218,208))
                    if factor>1:
                        image=image.resize((180//factor,208//factor),Image.Resampling.NEAREST).resize((180,208),Image.Resampling.NEAREST)
                    sheet.paste(image,(i*180,y+25))
        frames.append(sheet)
    gif(frames,DEST/'day-night-pixel-density.gif',100)
    frames[0].save(DEST/'poster.png')
    for factor in [2,4]:
        scaled=[]
        for frame in frames:
            scaled.append(frame.crop((0,[1,2].index({2:1,4:2}[factor])*535+535,1440,[1,2].index({2:1,4:2}[factor])*535+1070)))
        gif(scaled,DEST/f'coarse-{factor}x.gif',100)
    (DEST/'contract.json').write_text(json.dumps({'native_character_height_px':[64,32,16],
       'physical_display_height_px':128,'sampling':'NEAREST downsample of actual FHD crop by2/4 then NEAREST restore',
       'frame_count':24,'milliseconds_per_frame':100,'runtime_sprites_changed':False},indent=2)+'\n')
    print('Resolution review saved:64/32/16px detail at identical screen size,24x100ms day/night.')

if __name__=='__main__':build()
