"""Compare approved down and proposed up at identical integer display scales."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parent
DOWN=ROOT.parent/'walk-down'
def font(size):
    return ImageFont.truetype('C:/Windows/Fonts/consola.ttf',size)
frames=[]
for i in range(8):
    down=Image.open(DOWN/f'frames/walk-down-{i+1:02}.png').convert('RGBA')
    up=Image.open(ROOT/f'frames/walk-up-{i+1:02}.png').convert('RGBA')
    canvas=Image.new('RGBA',(1040,420),'#20292c')
    d=ImageDraw.Draw(canvas)
    d.text((22,16),'APPROVED DOWN / WALK UP / 8 FRAMES / 10 FPS',font=font(19),fill='#e9e3cf')
    for label,x in [('DOWN | FHD 1x',20),('UP | FHD 1x',195),('DOWN | DETAIL 2x',390),('UP | DETAIL 2x',720)]:
        d.text((x,66),label,font=font(15),fill='#e9e3cf')
    for x,im,size in [(20,down,160),(195,up,160),(365,down,320),(700,up,320)]:
        canvas.alpha_composite(im.resize((size,size),Image.Resampling.NEAREST),(x,90 if size==160 else 75))
    d.text((22,292),'Same display scale',font=font(15),fill='#aac2bd')
    d.text((22,320),'Compare height and leg volume',font=font(15),fill='#aac2bd')
    d.text((22,370),f'Frame {i+1:02} / 08  |  awaiting approval',font=font(14),fill='#e9e3cf')
    frames.append(canvas.convert('RGB'))
atlas=Image.new('RGB',(1040*8,420))
for i,f in enumerate(frames):atlas.paste(f,(i*1040,0))
palette=atlas.quantize(colors=256)
quantized=[f.quantize(palette=palette,dither=Image.Dither.NONE) for f in frames]
quantized[0].save(ROOT/'down-up-comparison.gif',save_all=True,append_images=quantized[1:],duration=100,loop=0,disposal=2,optimize=False)
with Image.open(ROOT/'down-up-comparison.gif') as saved:
    assert saved.n_frames == 8
    for i in range(8):
        saved.seek(i)
        assert saved.info['duration'] == 100
frames[0].save(ROOT/'comparison-poster.png')
print(ROOT/'down-up-comparison.gif')
