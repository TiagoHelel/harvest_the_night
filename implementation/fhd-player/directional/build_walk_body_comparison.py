"""Compare actual FHD production crops: approved idle, reported walk, revision."""
from io import BytesIO
from pathlib import Path
import subprocess
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
BASELINE = '9c2e51ec'


def main():
    old = Image.open(BytesIO(subprocess.check_output(['git','show',BASELINE+
        ':implementation/fhd-player/directional/review-stills/runtime-horizontal.gif'])))
    before, clock = [], 0
    for index in range(old.n_frames):
        old.seek(index)
        clock += old.info.get('duration',40)
        before.append((clock, old.convert('RGB').copy()))
    rows = []
    for lighting, offset in (('day',0),('night',192)):
        for frame in range(96):
            stamp = (offset+96+frame%48)*40
            prior = next(image for end,image in before if end > stamp).crop((0,24,256,232))
            with Image.open(HERE/'runtime-captures'/f'{lighting}_idle_south_{frame:03d}.png') as idle, \
                 Image.open(HERE/'runtime-captures'/f'{lighting}_walk_south_{frame%48:03d}.png') as after:
                row = Image.new('RGB',(768,232),'#17151c')
                draw = ImageDraw.Draw(row)
                for column,(image,label) in enumerate(((idle,'IDLE'),(prior,'BEFORE WALK'),(after,'AFTER WALK'))):
                    row.paste(image.convert('RGB'),(column*256,24))
                    draw.text((column*256+8,6),lighting.upper()+' / '+label,fill='#ece3d3')
                rows.append(row)
    folder = HERE/'review-stills'
    rows[0].save(folder/'walk-body-comparison.gif',save_all=True,append_images=rows[1:],
                 duration=40,loop=0,optimize=False,disposal=2)
    rows[8].save(folder/'walk-body-comparison.png')
    rows[8].resize((2304,696),Image.Resampling.NEAREST).save(folder/'walk-body-comparison-3x.png')
    print('WALK BODY COMPARISON: actual day/night FHD idle/before/after crops, 192 frames at 25fps, no scaling.')


if __name__ == '__main__':
    main()
