"""Assemble actual FHD runtime crops; never redraw or rescale character pixels."""
from pathlib import Path
import json
import shutil
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
DIRECTIONS = ('south', 'west', 'north', 'east')


def main():
    report = json.loads((HERE / 'runtime-capture-report.json').read_text())
    assert report['failures'] == 0 and len(report['sequences']) == 24
    frames = []
    for lighting in ('day', 'night'):
        for motion, count in (('idle', 96), ('walk', 48), ('run', 48)):
            for number in range(count):
                row = Image.new('RGB', (1024, 232), '#17151c')
                draw = ImageDraw.Draw(row)
                for column, direction in enumerate(DIRECTIONS):
                    source = HERE / 'runtime-captures' / f'{lighting}_{motion}_{direction}_{number:03d}.png'
                    with Image.open(source) as picture:
                        assert picture.size == (256, 208)
                        row.paste(picture.convert('RGB'), (column * 256, 24))
                    draw.text((column * 256 + 10, 6), f'{lighting.upper()} / {motion.upper()} / {direction.upper()}', fill='#ece3d3')
                frames.append(row)
    target = HERE / 'review-stills' / 'runtime-horizontal.gif'
    frames[0].save(target, save_all=True, append_images=frames[1:], duration=40, loop=0, optimize=False, disposal=2)
    for lighting in ('day', 'night'):
        for motion in ('walk', 'run'):
            name = f'{lighting}_{motion}_east_fhd.png'
            shutil.copyfile(HERE / 'runtime-captures' / name, HERE / 'review-stills' / ('runtime_' + name))
        sheet = Image.new('RGB', (2048, 464), '#17151c')
        draw = ImageDraw.Draw(sheet)
        for row, direction in enumerate(('east','west')):
            for phase in range(8):
                with Image.open(HERE/'runtime-captures'/f'{lighting}_run_{direction}_{phase*2:03d}.png') as picture:
                    sheet.paste(picture.convert('RGB'), (phase*256,row*232+24))
                draw.text((phase*256+8,row*232+6),f'{lighting} {direction} frame {phase*2}',fill='#ece3d3')
        sheet.save(HERE/'review-stills'/f'runtime-{lighting}-run-phases.png')
        with Image.open(HERE/'runtime-captures'/f'{lighting}_run_east_008.png') as picture:
            picture.resize((768,624),Image.Resampling.NEAREST).save(HERE/'review-stills'/f'runtime-{lighting}-3x.png')
        heads = Image.new('RGB', (2048, 464), '#17151c')
        draw = ImageDraw.Draw(heads)
        for row, direction in enumerate(('south', 'north')):
            for phase in range(8):
                with Image.open(HERE/'runtime-captures'/f'{lighting}_walk_{direction}_{phase*3:03d}.png') as picture:
                    heads.paste(picture.convert('RGB'), (phase*256, row*232+24))
                draw.text((phase*256+8, row*232+6), f'{lighting} walk {direction} phase {phase}', fill='#ece3d3')
            with Image.open(HERE/'runtime-captures'/f'{lighting}_walk_{direction}_008.png') as picture:
                picture.resize((768,624),Image.Resampling.NEAREST).save(
                    HERE/'review-stills'/f'runtime-{lighting}-walk-{direction}-3x.png')
        heads.save(HERE/'review-stills'/f'runtime-{lighting}-walk-head-phases.png')
    print('Actual runtime GIF: 384 frames / 25fps / 1024x232, day/night and all four directions.')


if __name__ == '__main__':
    main()
