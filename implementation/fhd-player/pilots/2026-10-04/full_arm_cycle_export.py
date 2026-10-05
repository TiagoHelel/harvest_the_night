"""Uniform native sampling and observable color-motion diagnostics."""
from pathlib import Path
import hashlib
import json
import math
import statistics
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parents[3]/'assets/art_source/player-fhd/pilots/2026-10-04'

def clean(im):
    im=im.convert('RGBA')
    im.putalpha(im.getchannel('A').point(lambda a:255 if a>=128 else 0))
    return im

def sample(direction,source_name,stage):
    image=clean(Image.open(SOURCE/f'walk-{direction}'/source_name))
    cols=[round(i*image.width/4) for i in range(5)]
    blank=[y for y in range(round(image.height*.4),round(image.height*.6))
           if image.getchannel('A').crop((0,y,image.width,y+1)).getbbox() is None]
    assert blank,'No transparent row gutter: inspect source before sampling.'
    rows=[0,round(statistics.median(blank)),image.height]
    cells=[image.crop((cols[c],rows[r],cols[c+1],rows[r+1])) for r in range(2) for c in range(4)]
    widths=[]; centers=[]
    for cell in cells:
        b=cell.getbbox(); assert b is not None
        h=cell.crop((0,b[1],cell.width,b[1]+round((b[3]-b[1])*.22))).getbbox()
        widths.append(h[2]-h[0]); centers.append((h[0]+h[2])/2)
    scale=32/statistics.median(widths)
    frames=[]; metrics=[]
    folder=ROOT/f'walk-{direction}'/stage; folder.mkdir(exist_ok=True)
    sheet=Image.new('RGBA',(320,160)); strip=Image.new('RGBA',(640,80))
    for i,(cell,center) in enumerate(zip(cells,centers)):
        small=cell.resize((round(cell.width*scale),round(cell.height*scale)),Image.Resampling.NEAREST)
        frame=Image.new('RGBA',(80,80))
        frame.alpha_composite(small,(round(40-center*scale),8-small.getbbox()[1]))
        b=frame.getbbox(); assert b[0]>1 and b[2]<79 and b[3]<78,b
        assert set(frame.getchannel('A').tobytes()) <= {0,255}
        frame.save(folder/f'walk-{direction}-{i+1:02}.png')
        sheet.alpha_composite(frame,((i%4)*80,(i//4)*80)); strip.alpha_composite(frame,(i*80,0))
        h=frame.crop((0,8,80,22)).getbbox()
        metrics.append({'frame':i+1,'bbox':b,'height':b[3]-b[1],'hat_region_width':h[2]-h[0],
                        'sha256':hashlib.sha256(frame.tobytes()).hexdigest()})
        frames.append(frame)
    assert len({f['sha256'] for f in metrics})==8
    sheet.save(ROOT/f'walk-{direction}'/f'{stage}-native.png')
    if stage=='frames': strip.save(ROOT/f'walk-{direction}'/f'walk-{direction}-strip.png')
    state={'selected_source':source_name,'source_size':list(image.size),'source_row_cuts':rows,
           'source_col_cuts':cols,'common_source_scale':scale,'native_canvas':[80,80],
           'hat_calibration':32,'source_alpha_threshold':128,'resample':'nearest',
           'anchor':'hat center and fixed top8px','frames_metrics':metrics}
    (ROOT/f'walk-{direction}'/f'{stage}-sampling.json').write_text(json.dumps(state,indent=2)+'\n')
    return frames,state

def color_motion(direction,frames):
    results={arm:[] for arm in ['left','right']}
    for frame in frames:
        for arm in results:
            points=[]; mask=[]
            for y in range(27,57):
                for x in range(10,70):
                    r,g,b,a=frame.getpixel((x,y))
                    cyan=a==255 and g>80 and b>70 and g>r*1.5 and b>r*1.5 and g>b*.8 and b>g*.65
                    pink=a==255 and r>110 and b>70 and r>g*1.35 and b>g*1.35
                    if cyan if arm=='left' else pink:
                        points.append((x,y)); mask.append((x,y,r,g,b))
            assert len(points)>=8,(direction,arm,'arm identity missing')
            low=max(y for x,y in points)
            min_y=min(y for x,y in points)
            distal=[(x,y) for x,y in points if y>=low-max(1,round((low-min_y)*.25))]
            results[arm].append({'area':len(points),'bbox':[min(x for x,y in points),min_y,
                  max(x for x,y in points)+1,low+1], 'lower_extent_y':low,
                  'distal_centroid':[statistics.mean(x for x,y in distal),statistics.mean(y for x,y in distal)],
                  'mask_hash':hashlib.sha256(str(mask).encode()).hexdigest()})
    gates={}
    for arm,poses in results.items():
        extents=[p['lower_extent_y'] for p in poses]
        repeats=[i+1 for i in range(8) if poses[i]['mask_hash']==poses[(i+1)%8]['mask_hash']]
        gates[arm]={'lower_extent_range_px':max(extents)-min(extents),
                    'consecutive_identical_color_masks':repeats,
                    'pass':max(extents)-min(extents)>=6 and not repeats}
    passed=all(g['pass'] for g in gates.values())
    report={'direction':direction,'status':'PASS' if passed else 'FAIL','arms':results,'gates':gates,
        'limits':'Colored lower extents/changed masks check visible motion amplitude, not anatomy, wrist landmarks or user approval.'}
    (ROOT/f'walk-{direction}'/'arm-color-motion.json').write_text(json.dumps(report,indent=2)+'\n')
    return report

def export_direction(direction):
    normal,state=sample(direction,'full-arm-materials-r13.png','frames')
    tracking,tracking_state=sample(direction,'full-arm-tracking-r12.png','arm-tracking-frames')
    report=color_motion(direction,tracking)
    state['tracking_sampling']=tracking_state
    state['color_motion_status']=report['status']
    return normal,tracking,state

if __name__=='__main__':
    import sys
    direction=sys.argv[1]
    stage=sys.argv[2] if len(sys.argv)>2 else 'tracking'
    if stage=='tracking':
        frames,state=sample(direction,'full-arm-tracking-r12.png','arm-tracking-frames')
        report=color_motion(direction,frames)
        print(json.dumps({'direction':direction,'status':report['status'],'gates':report['gates']},indent=2))
        sheet=Image.open(ROOT/f'walk-{direction}'/'arm-tracking-frames-native.png')
        sheet.resize((1920,960),Image.Resampling.NEAREST).save(SOURCE/f'walk-{direction}'/'full-arm-tracking-native-reference.png')
    else:
        normal,tracking,state=export_direction(direction)
        print(json.dumps(state,indent=2))
