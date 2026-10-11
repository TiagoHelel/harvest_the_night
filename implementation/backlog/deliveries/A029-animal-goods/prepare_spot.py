"""Prepare the soil prop only after the truffle icon's material was inspected."""
from pathlib import Path
import json,re
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
book=(ROOT/'implementation/sprites/generation/PROMPTS.md').read_text(encoding='utf-8');base=re.search(r'## BASE\s+```text\s+(.*?)```',book,re.S).group(1)
values={'specific object or animation, asset ID, required states':'ONE props/truffle_spot static resource prop','Image 1: approved style reference; Image 2: identity/shape master;\nImage 3 if applicable: edit target. Specify each role explicitly.':'Image1 world reference is STYLE ONLY. Image2 rock raw is prop CAMERA, LIGHT and OUTLINE only, never draw a rock. Image3 accepted truffle raw is TRUFFLE MATERIAL ONLY, never its cut half.','width':'16','height':'16','x':'8','y':'14','true transparent background for isolated sprites, or fully\nopaque edge-to-edge material for terrain':'true transparent alpha around the isolated heap'}
for token,value in values.items():base=base.replace('{'+token+'}',value)
prompt=base+'''\n\nCreate a truffle dig spot: a SMALL RAISED heap of freshly turned soil clods with ONLY the knobby dark TOP of one truffle poking out. About12native pixels wide and8tall, centredx8,lowestopaque row13, native16x16canvas,pivot8,14. Natural3quarterfarmprop litupperleft, same prop contrast and coloured outline as the rock reference but clearly smaller and softer. Soil_dark/soil/soil_light tops; dark brown truffle wood_dark/soil_dark. Two or three simple joined angular earth masses, tiny but recognizable raised heap. No cut half, leaves, grass, flat dirt disc, hole painted into ground, ground tile, ground shadow, halo, extra objects, numbers or labels. One joined unclipped silhouette, generous transparent margins. Flat deliberate square pixels, no gradients or fine speckle.\n'''
args={'prompt':prompt,'referenced_image_paths':[str(ROOT/'docs/reference-sheet.png'),str(ROOT/'assets/art_source/props/rock.png'),str(HERE/'raw/truffle-r1.png')],'transparent_background':True};stem='truffle_spot-r1'
for suffix,data in [('.request.json',json.dumps(args,indent=2)+'\n'),('.prompt.txt',prompt)]:
    path=HERE/f'raw/{stem}{suffix}';assert not path.exists();path.write_text(data,encoding='utf-8')
(HERE/'spot-job.json').write_text(json.dumps({'stem':stem,'revision':1,'folder':HERE.name,'args':args},indent=2)+'\n')
