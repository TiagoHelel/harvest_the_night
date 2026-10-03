"""Identify the reported production pose and measure anatomy against idle."""
from pathlib import Path
from io import BytesIO
import json
import subprocess
import numpy as np
from PIL import Image
import build_review

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
BASELINE = '9c2e51ec'


def correlate(image, kernel):
    size = (image.shape[0] + kernel.shape[0] - 1,
            image.shape[1] + kernel.shape[1] - 1)
    convolution = np.fft.irfft2(np.fft.rfft2(image, size)
                              * np.fft.rfft2(kernel[::-1, ::-1], size), size)
    return convolution[kernel.shape[0]-1:image.shape[0],
                       kernel.shape[1]-1:image.shape[1]]


def anatomy(image):
    return {**build_review.head_dimensions(image),
            **build_review.upper_body_dimensions(image)}


def main():
    frames = json.loads(subprocess.check_output(['git','show',BASELINE+
        ':implementation/fhd-player/directional/review-contract.json'], cwd=ROOT))['frames']
    native_images = {frame['id']:Image.open(BytesIO(subprocess.check_output(
        ['git','show',BASELINE+':'+frame['output']],cwd=ROOT))).convert('RGBA')
        for frame in frames if frame['animation'].startswith(('idle_','walk_','run_'))}
    references = [
        ('idle', 'C:/Users/Helel/AppData/Local/Temp/codex-clipboard-42ec778d-4151-43c9-bb3c-cc0153cbc2f5.png'),
        ('movement', 'C:/Users/Helel/AppData/Local/Temp/codex-clipboard-75cb4644-f779-4663-a785-c8ba80205c2f.png')]
    report = {'baseline_commit':BASELINE}
    for label, path in references:
        saved = HERE/'review-stills'/('reported-size-'+label+'.png')
        picture = Image.open(saved if saved.exists() else path).convert('RGB')
        scene = np.asarray(picture).astype(float)
        candidates = []
        for frame in frames:
            if not frame['animation'].startswith(('idle_', 'walk_', 'run_')):
                continue
            native = native_images[frame['id']]
            sprite = np.array(native.crop(native.getbbox()).resize(
                (2*(native.getbbox()[2]-native.getbbox()[0]),
                 2*(native.getbbox()[3]-native.getbbox()[1])), Image.Resampling.NEAREST)).astype(float)
            mask = (sprite[:, :, 3] > 0).astype(float)
            costs = correlate((scene**2).sum(2), mask)
            costs += (sprite[:, :, :3]**2 * mask[:, :, None]).sum()
            for channel in range(3):
                costs -= 2*correlate(scene[:, :, channel], sprite[:, :, channel]*mask)
            y, x = np.unravel_index(costs.argmin(), costs.shape)
            candidates.append({'id':frame['id'], 'mean_squared_error':float(costs[y,x]/mask.sum()),
                               'screen_xy':[int(x), int(y)], 'native':anatomy(native)})
        report[label] = sorted(candidates, key=lambda c:c['mean_squared_error'])[:3]
        picture.save(HERE/'review-stills'/('reported-size-'+label+'.png'))
    (HERE/'reported-size-diagnostic.json').write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
