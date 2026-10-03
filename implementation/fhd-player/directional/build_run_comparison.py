"""Compare actual old/new Godot playback at the same clock; no sprite painting."""
from io import BytesIO
from pathlib import Path
import subprocess
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
BASELINE = '80d269e6'

def main():
    old = Image.open(BytesIO(subprocess.check_output([
        'git','show',BASELINE + ':implementation/fhd-player/directional/gifs/run-horizontal.gif'])))
    previous, end = [], 0
    for index in range(old.n_frames):
        old.seek(index)
        end += old.info.get('duration',40)
        previous.append((end,old.convert('RGB').copy()))
    frames, old_index = [], 0
    for number in range(192):
        while old_index + 1 < len(previous) and previous[old_index][0] <= number * 40:
            old_index += 1
        before = previous[old_index][1]
        with Image.open(HERE/'captures/run'/f'frame-{number:03d}.png') as png:
            after = png.convert('RGB')
        row = Image.new('RGB',(1040,312),'#17151c')
        draw = ImageDraw.Draw(row)
        for column,(image,source,label) in enumerate(((before,1,'BEFORE LEFT'),
                (after,1,'AFTER LEFT'),(before,3,'BEFORE RIGHT'),(after,3,'AFTER RIGHT'))):
            row.paste(image.crop((source*260,0,(source+1)*260,288)),(column*260,24))
            draw.text((column*260+12,6),label,fill='#ece3d3')
        frames.append(row)
    frames[0].save(HERE/'review-stills/run-two-leg-comparison.gif',save_all=True,
                  append_images=frames[1:],duration=40,loop=0,optimize=False,disposal=2)
    frames[0].save(HERE/'review-stills/run-two-leg-comparison-slow.gif',save_all=True,
                  append_images=frames[1:],duration=80,loop=0,optimize=False,disposal=2)
    frames[8].save(HERE/'review-stills/run-two-leg-comparison.png')
    print('Actual Godot comparison: old/new left, old/new right, 7.68s at 25fps.')

if __name__ == '__main__':
    main()
