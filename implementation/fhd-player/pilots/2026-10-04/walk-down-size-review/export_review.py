"""Cut a regenerated DOWN candidate uniformly and render equal-scale reviews."""
from pathlib import Path
import hashlib
import json
import statistics
import sys
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
PILOT = HERE.parent
REPO = PILOT.parents[3]
SOURCE = REPO / 'assets/art_source/player-fhd/pilots/2026-10-04/walk-down-size-review'
sys.path.insert(0, str(PILOT))
from build_hand_rebuild_review import caption, save_gif

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def export(source_name):
    approval_path=HERE/'approval.json'
    approval=json.loads(approval_path.read_text()) if approval_path.exists() else None
    previous_report=json.loads((HERE/'validation.json').read_text()) if (HERE/'validation.json').exists() else {}
    approved=bool(approval and approval['candidate']==Path(source_name).stem+'/frames')
    image = Image.open(SOURCE / source_name).convert('RGBA')
    image.putalpha(image.getchannel('A').point(lambda value: 255 if value >= 128 else 0))
    cols = [round(i * image.width / 4) for i in range(5)]
    alpha = image.getchannel('A')
    blank = [y for y in range(round(image.height*.4),round(image.height*.6))
             if alpha.crop((0,y,image.width,y+1)).getbbox() is None]
    assert blank, 'Inspect source: no transparent row gutter.'
    rows = [0, round(statistics.median(blank)), image.height]
    cells = [image.crop((cols[c],rows[r],cols[c+1],rows[r+1])) for r in range(2) for c in range(4)]
    boxes = [cell.getbbox() for cell in cells]
    assert all(boxes)
    scale = 64 / statistics.median(box[3]-box[1] for box in boxes)
    frame_dir = HERE / Path(source_name).stem / 'frames'
    frame_dir.mkdir(parents=True, exist_ok=True)
    frames, metrics = [], []
    for i, (cell, box) in enumerate(zip(cells, boxes)):
        hat = cell.crop((0,box[1],cell.width,box[1]+round((box[3]-box[1])*.23))).getbbox()
        center = (hat[0]+hat[2])/2
        small = cell.resize((round(cell.width*scale),round(cell.height*scale)), Image.Resampling.NEAREST)
        frame = Image.new('RGBA', (80,80))
        frame.alpha_composite(small, (round(40-center*scale),8-small.getbbox()[1]))
        b = frame.getbbox(); assert b[0]>1 and b[2]<79 and b[3]<78, b
        path = frame_dir / f'walk-down-{i+1:02}.png'
        if approved:
            assert digest(path)==approval['approved_frame_sha256'][path.name]
            frame=Image.open(path).convert('RGBA')
            b=frame.getbbox()
        else:
            frame.save(path)
        h = frame.crop((0,8,80,23)).getbbox()
        metrics.append({'frame':i+1,'bbox':b,'height':b[3]-b[1],'hat_width':h[2]-h[0],
                        'sha256':digest(path),'torso_and_arms_width':frame.crop((0,30,80,49)).getbbox()[2]-frame.crop((0,30,80,49)).getbbox()[0]})
        frames.append(frame)
    if approved:
        assert {p.name:digest(p) for p in frame_dir.glob('*.png')}==approval['approved_frame_sha256']
    assert len({m['sha256'] for m in metrics}) == 8
    selected = json.loads((PILOT / 'walk-down-left/aggregate-selection.json').read_text())
    old = [Image.open(PILOT / item['path']).convert('RGBA') for item in selected['down']]
    right = [Image.open(PILOT / item['path']).convert('RGBA') for item in selected['right']]
    normal, slow = [], []
    for i, frame in enumerate(frames):
        canvas = Image.new('RGBA',(990,440),'#20292c'); draw=ImageDraw.Draw(canvas)
        caption(draw,(20,17),'WALK DOWN / SIZE & PROPORTION REVIEW / 8 FRAMES / 10 FPS',20)
        for x,im,size,label in [(20,old[i],160,'OLD DOWN | 1x'),(220,frame,160,'NEW DOWN | 1x'),
                                 (420,right[i],160,'RIGHT | 1x'),(645,frame,320,'DETAIL | 2x')]:
            caption(draw,(x,69),label,15)
            canvas.alpha_composite(im.resize((size,size),Image.Resampling.NEAREST),(x,105 if size==160 else 87))
            if size==160:
                draw.line((x,254,x+160,254),fill='#4b6661')
        caption(draw,(20,305),'Same 80px cells / integer 2x normal display',15)
        caption(draw,(20,340),'New DOWN candidate / pants recoloring comes later',15)
        caption(draw,(20,386),f'Frame {i+1:02} / 08 / '+('APPROVED' if approved else 'awaiting your approval'),15)
        normal.append(canvas.convert('RGB'))
        detail=Image.new('RGBA',(1040,390),'#20292c'); sd=ImageDraw.Draw(detail)
        for x,im,label in [(10,old[i],'OLD DOWN'),(360,frame,'NEW DOWN'),(710,right[i],'RIGHT REFERENCE')]:
            caption(sd,(x,13),label,17)
            detail.alpha_composite(im.resize((320,320),Image.Resampling.NEAREST),(x,45))
        caption(sd,(10,369),f'Frame {i+1}/8 / integer4x / slow comparison',14)
        slow.append(detail.convert('RGB'))
    save_gif(normal,HERE/'walk-down-size-review.gif',100)
    save_gif(slow,HERE/'walk-down-size-slow.gif',200)
    normal[0].save(HERE/'poster.png')
    contact=Image.new('RGBA',(1280,400),'#303a3e')
    for i,frame in enumerate(frames):
        for y,im,label in [(30,old[i],'OLD'),(225,frame,'NEW')]:
            caption(ImageDraw.Draw(contact),(i*160+8,y-22),f'{i+1} / {label}',14)
            contact.alpha_composite(im.resize((160,160),Image.Resampling.NEAREST),(i*160,y))
    contact.convert('RGB').save(HERE/'contact-sheet.png')
    combined=[]
    for i in range(8):
        canvas=Image.new('RGBA',(1440,280),'#20292c'); draw=ImageDraw.Draw(canvas)
        caption(draw,(20,12),'EIGHT WALK DIRECTIONS / NEW DOWN CANDIDATE / 10 FPS',20)
        for j,(direction,items) in enumerate(selected.items()):
            im=frames[i] if direction=='down' else Image.open(PILOT/items[i]['path']).convert('RGBA')
            caption(draw,(j*180+12,55),direction.upper(),16)
            canvas.alpha_composite(im.resize((160,160),Image.Resampling.NEAREST),(j*180,82))
            caption(draw,(j*180+12,245),('APPROVED DOWN' if approved else 'NEW CANDIDATE') if direction=='down' else 'REFERENCE',12)
        combined.append(canvas.convert('RGB'))
    save_gif(combined,HERE/'all-eight-with-new-down.gif',100)
    combined[0].save(HERE/'all-eight-poster.png')
    baseline=json.loads((HERE/'baseline.json').read_text())
    assert len(baseline)==64 and all(digest(PILOT/name)==value for name,value in baseline.items())
    report={'date':'2026-10-05','status':'approved' if approved else 'awaiting_approval','source':source_name,'source_sha256':digest(SOURCE/source_name),
        'source_size':image.size,'source_col_cuts':cols,'source_row_cuts':rows,'common_source_scale':scale,
        'native_canvas':[80,80],'target_height':64,'normal_display_scale':2,'detail_display_scale':4,
        'alpha_threshold':128,'sampling':'nearest, common scale across all8 poses, hat-center/top8 anchor',
        'candidate_frames':str(frame_dir.relative_to(HERE)).replace('\\','/'),'frames_metrics':metrics,
        'existing_selected_frames_unchanged':64,'normal_ms':100,'slow_ms':200,'loop':0,
        'runtime_integrated':False,'palette_harmonization':'deferred by user',
        'limits':'Native geometry/format checks do not prove gait coherence or user approval.'}
    if approved:
        report.update({k:v for k,v in previous_report.items() if k in ['visual_review','engine_verification']})
        report.update({'approval_date':approval['date'],'user_feedback':approval['user_feedback'],
                       'approved_frame_sha256':approval['approved_frame_sha256']})
    (HERE/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
    (frame_dir.parent/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
    (HERE/'selection.json').write_text(json.dumps({'source':source_name,'frames':report['candidate_frames']},indent=2)+'\n')
    html='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>New DOWN size review</title><style>body{background:#182426;color:#e9e3cf;font:17px Consolas,monospace;margin:20px}
h1{font-size:23px}a{color:#98dcd6}img{image-rendering:pixelated}.overflow{overflow-x:auto;margin:20px 0}.frames{display:flex;gap:20px}
.frames img{width:320px;height:320px;background:#303a3e}summary{cursor:pointer}details{margin:25px 0}
button{background:#344b48;color:#e9e3cf;border:1px solid #75958d;padding:12px;font:inherit;margin:16px 8px 16px 0}</style>
<h1>Regenerated WALK DOWN — size and body proportions</h1><p>OLD DOWN, NEW DOWN and approved RIGHT shown at the same integer 2x scale. Eight frames at 10 FPS.</p>
<div class="overflow"><img src="walk-down-size-review.gif?v=SOURCE" width="990" height="440" alt="Old and new down compared with right"></div>
<details><summary>Inspect individual frames</summary><button id="previous">Previous</button><button id="next">Next</button><span id="number">Frame 1 / 8</span>
<div class="overflow frames"><div>OLD DOWN<br><img id="old" src="../walk-down/frames/walk-down-01.png"></div><div>NEW DOWN<br><img id="new" src="FRAMES/walk-down-01.png"></div><div>RIGHT<br><img id="right" src="../walk-right/frames/walk-right-01.png"></div></div></details>
<details><summary>Slow before-and-after comparison</summary><div class="overflow"><img src="walk-down-size-slow.gif?v=SOURCE" width="1040" height="390"></div></details>
<details><summary>All eight with the new down</summary><div class="overflow"><img src="all-eight-with-new-down.gif?v=SOURCE" width="1440" height="280"></div></details>
<details><summary>Eight-frame contact sheet</summary><div class="overflow"><img src="contact-sheet.png" width="1280" height="400"></div></details>
<p>Awaiting your approval. Pants palette harmonization is the next separate step.</p>
<p><a href="validation.json">Measurements and source</a> · <a href="down-r1.prompt.json">Generation prompt</a></p>
<script>let i=0;function show(d){i=(i+d+8)%8;const n=String(i+1).padStart(2,'0');document.getElementById('number').textContent=`Frame ${i+1} / 8`;
document.getElementById('old').src=`../walk-down/frames/walk-down-${n}.png`;document.getElementById('new').src=`FRAMES/walk-down-${n}.png`;
document.getElementById('right').src=`../walk-right/frames/walk-right-${n}.png`;}
document.getElementById('previous').onclick=()=>show(-1);document.getElementById('next').onclick=()=>show(1);</script></html>'''
    html=html.replace('SOURCE',Path(source_name).stem).replace('FRAMES',report['candidate_frames'])
    html=html.replace('down-r1.prompt.json',Path(source_name).stem+'.prompt.json')
    if approved:
        html=html.replace('Awaiting your approval. Pants palette harmonization is the next separate step.',
                          'DOWN approved. Garment color harmonization is the next separate review.')
    (HERE/'index.html').write_text(html,encoding='utf-8')
    print(json.dumps({'source':source_name,'heights':[m['height'] for m in metrics],'hat_widths':[m['hat_width'] for m in metrics],'existing_unchanged':64}))

if __name__=='__main__':
    export(sys.argv[1])
