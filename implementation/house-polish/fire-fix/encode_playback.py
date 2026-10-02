"""Encode unmodified native gameplay captures; shared palette prevents flicker."""
from pathlib import Path
from PIL import Image

FOLDER = Path(__file__).resolve().parent
frames = [Image.open(path).convert('RGB') for path in sorted(FOLDER.glob('flame_*.png'))]
palette = frames[0].quantize(colors=256)
encoded = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in frames]
encoded[0].save(FOLDER / 'hearth-playback.gif', save_all=True,
                append_images=encoded[1:], duration=125, loop=0, optimize=False)
sheet = Image.new('RGB', (192, 256), (30, 24, 28))
for index, frame in enumerate(frames[::3][:4]):
    crop = frame.crop((240, 54, 288, 118)).resize((96, 128), Image.Resampling.NEAREST)
    sheet.paste(crop, ((index % 2) * 96, (index // 2) * 128))
sheet.save(FOLDER / 'motion-review.png')
print(f'{len(frames)} native frames encoded at 8fps')
