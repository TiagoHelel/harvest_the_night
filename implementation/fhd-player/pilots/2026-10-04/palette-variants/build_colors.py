"""Palette-only recoloring, used only with the user's explicit code-paint choice."""
from bisect import bisect_left
from collections import Counter
from pathlib import Path
import hashlib
import json
import sys
from PIL import Image, ImageDraw

HERE=Path(__file__).resolve().parent
PILOT=HERE.parent
sys.path.insert(0,str(PILOT))
from build_hand_rebuild_review import caption, save_gif

def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def luminance(rgb):return .2126*rgb[0]+.7152*rgb[1]+.0722*rgb[2]
def closest(rgb,palette):
    return min(range(len(palette)),key=lambda i:sum((rgb[k]-palette[i][k])**2 for k in range(3)))

def extract_reference(records):
    colors=[]
    for item in records['right']:
        im=Image.open(PILOT/item['path']).convert('RGBA')
        mask=Image.open(HERE/item['mask'])
        colors.extend(im.getpixel((x,y))[:3] for y in range(80) for x in range(80) if mask.getpixel((x,y)))
    raw=Image.new('RGB',(len(colors),1));raw.putdata(colors)
    quantized=raw.quantize(colors=12,method=Image.Quantize.MEDIANCUT)
    values=Counter(colors); table=quantized.getpalette(); medoids=[]
    for index,_ in Counter(quantized.get_flattened_data()).items():
        target=tuple(table[index*3:index*3+3])
        medoids.append(min(values,key=lambda p:(sum((p[k]-target[k])**2 for k in range(3)),-values[p],p)))
    palette=sorted(set(medoids),key=luminance)
    assert len(palette)==12
    return palette,colors

def variation_palette(base,hue,saturation):
    # Keep reference luminance ordering, use a fixed hue family; quantize once.
    import colorsys
    colors=[]
    for rgb in base:
        tone=luminance(rgb)
        unit=colorsys.hsv_to_rgb(hue,saturation,1)
        factor=tone/luminance(tuple(v*255 for v in unit))
        colors.append(tuple(max(0,min(255,round(v*255*factor))) for v in unit))
    assert len(set(colors))==12
    return colors

def recolor():
    authorization=HERE/'authorization.json'
    assert authorization.exists(), 'Explicit user choice for code recoloring is required.'
    assert json.loads(authorization.read_text())['method']=='deterministic palette mapping'
    selected=json.loads((HERE/'selection.json').read_text())
    base,reference_colors=extract_reference(selected)
    variants={'blue':base,'olive':variation_palette(base,80/360,.67),
              'brown':variation_palette(base,26/360,.72),'wine':variation_palette(base,340/360,.72)}
    ref_bins=Counter(closest(rgb,base) for rgb in reference_colors)
    cumulative=[]; total=sum(ref_bins.values()); so_far=0
    for i in range(12):
        so_far+=ref_bins[i];cumulative.append(so_far/total)
    rendered={name:{} for name in variants}; report={}
    for direction,items in selected.items():
        color_counts=Counter()
        originals=[]; masks=[]
        for item in items:
            path=PILOT/item['path']; assert digest(path)==item['sha256']
            im=Image.open(path).convert('RGBA'); mask=Image.open(HERE/item['mask'])
            assert digest(HERE/item['mask'])==item['mask_sha256']
            originals.append(im); masks.append(mask)
            color_counts.update(im.getpixel((x,y))[:3] for y in range(80) for x in range(80) if mask.getpixel((x,y)))
        # A single temporal-family map preserves shade identities across all8 frames.
        tones=Counter()
        for rgb,n in color_counts.items():tones[luminance(rgb)]+=n
        count=sum(tones.values()); accumulated=0; ranks={}
        for tone,n in sorted(tones.items()):
            ranks[tone]=(accumulated+n/2)/count; accumulated+=n
        indices={rgb:(closest(rgb,base) if direction=='right' else min(11,bisect_left(cumulative,ranks[luminance(rgb)])))
                 for rgb in color_counts}
        direction_report={'inputs':items,'tone_map_size':len(indices),'variants':{}}
        for name,palette in variants.items():
            frames=[]; stats=[]; used=set()
            folder=HERE/name/'frames'/direction;folder.mkdir(parents=True,exist_ok=True)
            for i,(original,mask) in enumerate(zip(originals,masks)):
                out=original.copy(); changed=0; tones_used=Counter()
                for y in range(80):
                    for x in range(80):
                        old=original.getpixel((x,y))
                        if mask.getpixel((x,y)):
                            index=indices[old[:3]];new=(*palette[index],old[3])
                            out.putpixel((x,y),new); changed+=new!=old
                            used.add(new[:3]);tones_used[index]+=1
                        else:assert out.getpixel((x,y))==old
                assert out.getchannel('A').tobytes()==original.getchannel('A').tobytes()
                assert out.getbbox()==original.getbbox()
                path=folder/f'{i+1:02}.png';out.save(path)
                stats.append({'frame':i+1,'path':str(path.relative_to(HERE)).replace('\\','/'),
                              'sha256':digest(path),'changed_rgb_pixels':changed,'tone_counts':dict(tones_used)})
                frames.append(out)
            assert used==set(palette), (direction,name,used)
            rendered[name][direction]=frames
            direction_report['variants'][name]={'frames':stats,'garment_unique_colors':len(used),
                'alpha_geometry_and_unmasked_rgba_unchanged':True}
        report[direction]=direction_report
    for name,by_direction in rendered.items():
        gif_frames=[]
        for i in range(8):
            canvas=Image.new('RGBA',(1440,280),'#20292c');draw=ImageDraw.Draw(canvas)
            caption(draw,(20,12),f'ALL EIGHT / {name.upper()} / 8 FRAMES / 10 FPS',20)
            for j,(direction,frames) in enumerate(by_direction.items()):
                caption(draw,(j*180+12,55),direction.upper(),16)
                canvas.alpha_composite(frames[i].resize((160,160),Image.Resampling.NEAREST),(j*180,82))
                caption(draw,(j*180+12,245),'COLOR REVIEW',12)
            gif_frames.append(canvas.convert('RGB'))
        save_gif(gif_frames,HERE/name/'all-eight.gif',100)
        gif_frames[0].save(HERE/name/'poster.png')
        # Nearest2x atlas preserves native palette exactly (GIF is a preview format).
        sheet=Image.new('RGBA',(1280,1280))
        for row,frames in enumerate(by_direction.values()):
            for col,frame in enumerate(frames):sheet.alpha_composite(frame.resize((160,160),Image.Resampling.NEAREST),(col*160,row*160))
        sheet.save(HERE/name/'all-frames.png')
    palette_doc={'date':'2026-10-05','status':'awaiting_palette_review','reference':'approved RIGHT native frames',
        'method':'12 weighted median-cut medoids from actual RIGHT garment pixels; one monotonic CDF shade map per eight-frame direction; RIGHT uses nearest original RGB shade.',
        'variants':{name:[{'rgb':rgb,'hex':'#%02x%02x%02x'%rgb} for rgb in colors] for name,colors in variants.items()},
        'garment_mask':'y>=28, HSV hue185..270, saturation>=.3, B>=6; manually inspected mask-audit.png',
        'scope':'Garment only (trousers, bib and straps); 256 sibling native files,64 original selected inputs retained.',
        'runtime_integrated':False,'directions':report,'normal_scale':2,'gif_frames':8,'gif_duration_ms':100,'loop':0}
    (HERE/'validation.json').write_text(json.dumps(palette_doc,indent=2)+'\n')
    draw_swatches(variants)
    write_html(variants)
    print('PASS:256 palette-only native outputs, four All eight GIFs; geometry/alpha/non-garment RGBA preserved.')

def draw_swatches(variants):
    chart=Image.new('RGB',(1000,220),'#20292c'); draw=ImageDraw.Draw(chart)
    for row,(name,colors) in enumerate(variants.items()):
        caption(draw,(12,row*55+16),name.upper(),18)
        for i,rgb in enumerate(colors):draw.rectangle((150+i*68,row*55+8,210+i*68,row*55+43),fill=rgb)
    chart.save(HERE/'palettes.png')

def write_html(variants):
    html='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Four garment palettes — all eight directions</title><style>body{background:#182426;color:#e9e3cf;font:17px Consolas,monospace;margin:20px}h1{font-size:24px}h2{font-size:20px}a{color:#98dcd6}img{image-rendering:pixelated}.overflow{overflow-x:auto;margin:20px 0}button{background:#344b48;color:#e9e3cf;border:1px solid #75958d;padding:12px;font:inherit;margin:16px 8px 16px 0}summary{cursor:pointer}details{margin:24px 0}</style>
<h1>Same farmer, four garment palettes</h1><p>RIGHT blue standard plus olive, brown and wine. Newly approved DOWN included. The same 64 poses; only garment pixels change.</p><nav>'''
    html+=' · '.join(f'<a href="#{name}">{name.upper()}</a>' for name in variants)+'</nav>'
    html+='<p>Native 80px cells, eight frames at 10 FPS. Choose 1x to compare all directions together, or 2x for the game display size.</p><button id="scale">Show all eight at native 1x</button>'
    for name in variants:
        html+=f'<section id="{name}"><h2>{name.upper()}'+(' — RIGHT reference standard' if name=='blue' else ' — variation')+f'</h2><div class="overflow"><img class="cycle" src="{name}/all-eight.gif?v=palette-r1" width="1440" height="280" alt="Eight directions in {name}"></div></section>'
    html+='''<details><summary>Compare a single frame across all colors</summary><button id="previous">Previous</button><button id="next">Next</button><span id="number">Frame1/8</span><div id="comparison"></div></details>'''
    html+='<details><summary>Exact garment palettes</summary><img src="palettes.png" width="1000" height="220"></details><details><summary>Garment-mask audit</summary><div class="overflow"><img src="mask-audit.png" width="1280" height="1480"></div></details>'
    html+='<p>Awaiting color approval; preview-only outputs. All original source frames retained. <a href="validation.json">Pixel invariance and palette report</a></p>'
    html+='''<script>let i=0;const variants=['blue','olive','brown','wine'];const dirs=['down','right','up','left','down-right','up-right','up-left','down-left'];function show(d){i=(i+d+8)%8;const n=String(i+1).padStart(2,'0');document.getElementById('number').textContent=`Frame ${i+1}/8`;document.getElementById('comparison').innerHTML=variants.map(c=>`<h2>${c.toUpperCase()}</h2><div class="overflow" style="display:flex;width:100%;gap:20px">`+dirs.map(t=>`<div>${t}<br><img src="${c}/frames/${t}/${n}.png" width="160" height="160"></div>`).join('')+'</div>').join('');}document.getElementById('previous').onclick=()=>show(-1);document.getElementById('next').onclick=()=>show(1);show(0);let native=false;document.getElementById('scale').onclick=()=>{native=!native;document.querySelectorAll('.cycle').forEach(img=>{img.width=native?720:1440;img.height=native?140:280;});document.getElementById('scale').textContent=native?'Show game display at 2x':'Show all eight at native 1x';};</script></html>'''
    (HERE/'index.html').write_text(html,encoding='utf-8')

if __name__=='__main__':recolor()
