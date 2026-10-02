"""Index final captures, prove exact prior-review reuse and compose changed views."""
from pathlib import Path
import hashlib, json
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
FOLDER=ROOT/'implementation/shots/sprites/0020'
PREVIOUS={'placement':('0003','showcase'),'locomotion':('0004','locomotion'),'work':('0005','work'),'reactions':('0006','reactions'),'terrain':('0007','terrain'),'water':('0008','water'),'props':('0009','props'),'crops':('0010','crops'),'house':('0011','house'),'stations':('0012','stations'),'towers':('0013','towers'),'barriers':('0014','barriers'),'enemies':('0015','enemies'),'giant':('0016','giant'),'effects':('0019','effects'),'ui':('0018','ui'),'atmosphere':('0019','atmosphere')}

def main():
    rows=[]
    for path in sorted(FOLDER.rglob('*.png')):
        relative=path.relative_to(FOLDER)
        family=relative.parts[0] if len(relative.parts)>1 else 'standard'
        image=Image.open(path).convert('RGBA')
        assert image.size==(480,270),path
        old=None
        if family in PREVIOUS:
            task,group=PREVIOUS[family]
            candidate=ROOT/f'implementation/shots/sprites/{task}/{group}'/path.name
            if candidate.exists():old=candidate
        else:
            for task in ['0019','0018']:
                candidate=ROOT/f'implementation/shots/sprites/{task}'/path.name
                if candidate.exists():old=candidate;break
        identical=bool(old and Image.open(old).convert('RGBA').tobytes()==image.tobytes())
        rows.append(dict(capture=path.relative_to(ROOT).as_posix(),family=family,sha256=hashlib.sha256(path.read_bytes()).hexdigest(),prior_capture=old.relative_to(ROOT).as_posix() if old else None,prior_pixels_identical=identical))
    # Every current capture is indexed, even when its prior accepted review can
    # be reused. New/changed images each get an exact native and 3x review page.
    groups={}
    for row in rows:
        if not row['prior_pixels_identical']:
            groups.setdefault(row['family'],[]).append(row)
    pages=[]
    for family,items in groups.items():
        for start in range(0,len(items),4):
            selected=items[start:start+4]
            page=Image.new('RGBA',(2880,2160),(24,22,30,255))
            for i,row in enumerate(selected):
                x,y=(i%2)*1440,(i//2)*1080
                art=Image.open(ROOT/row['capture']).convert('RGBA')
                page.alpha_composite(art,(x,y))
                ImageDraw.Draw(page).text((x+500,y+20),Path(row['capture']).name+' / native above; nearest 3x below',fill=(239,232,205,255))
                page.alpha_composite(art.resize((1440,810),Image.Resampling.NEAREST),(x,y+270))
            name=f'captures-{family}-{start//4:03}.png'
            page.save(HERE/name)
            pages.append(dict(review=name,captures=[r['capture'] for r in selected]))
    report=dict(total_captures=len(rows),exact_prior_pixels=sum(r['prior_pixels_identical'] for r in rows),new_or_changed=len(rows)-sum(r['prior_pixels_identical'] for r in rows),captures=rows,pages=pages)
    (HERE/'capture-index.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(f"PASS: {len(rows)} current native captures; {report['exact_prior_pixels']} exact prior-review images; {report['new_or_changed']} new/changed images on {len(pages)} native/3x pages")

if __name__=='__main__':main()
