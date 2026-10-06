"""Verify the candidate's export geometry, preserved approved frames, and review playback."""
from pathlib import Path
import hashlib,json
from PIL import Image

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[4]
BASE=HERE.parent/'walk-mirror-review'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

doc=json.loads((HERE/'contract.json').read_text())
preserved=0; edited=0; heights=[]
for entry in doc['assets']:
    name=f"walk/{entry['direction']}/{entry['frame']:02}.png"
    small=Image.open(HERE/'native-40'/name).convert('RGBA')
    large=Image.open(HERE/'runtime-80'/name).convert('RGBA')
    assert small.size==(40,40) and large.size==(80,80)
    assert small.resize((80,80),Image.Resampling.NEAREST).tobytes()==large.tobytes()
    assert set(small.getchannel('A').get_flattened_data())<={0,255}
    assert sha(BASE/'native-40'/name)==entry['before_sha256']
    for folder,output in entry['outputs'].items():
        assert sha(ROOT/output['path'])==output['sha256']
        if not entry['edited']:assert sha(HERE/folder/name)==sha(BASE/folder/name)
    preserved+=not entry['edited'];edited+=entry['edited']
    if entry['direction']=='up-right':
        box=small.getbbox(); old=Image.open(BASE/'native-40'/name).getbbox()
        assert abs((box[3]-box[1])-(old[3]-old[1]))<=1,(name,box,old)
        assert abs(box[1]-old[1])<=1,(name,box,old)
        heights.append({'frame':entry['frame'],'candidate_bbox':box,'before_bbox':old})
assert (edited,preserved)==(6,58)
playback=[]
for p in sorted(HERE.glob('*.gif')):
    with Image.open(p) as im:
        assert im.n_frames==8,p
        durations=[]
        for i in range(8):im.seek(i);durations.append(im.info['duration'])
        assert durations==[100]*8,p
        playback.append({'name':p.name,'size':im.size,'frames':im.n_frames,'duration_ms':durations})
assert len(playback)==4
renderer=json.loads((HERE/'renderer-report.json').read_text())
assert renderer['failures']==0 and len(renderer['captures'])==144
assert len({tuple(c['contact']) for c in renderer['captures']})==1
report={'edited_frames':edited,'preserved_frames':preserved,'preserved_approved_directions':7,
        'source_hashes_preserved':64,'png_exports':128,'binary_alpha':True,'integer_scale_exact':True,
        'up_right_scale':heights,'playback':playback,'godot_checks':renderer['checks'],
        'godot_failures':renderer['failures'],'fixed_contact':renderer['captures'][0]['contact'],
        'visual_motion_approval':'pending; automated checks do not establish motion quality'}
(HERE/'checks.json').write_text(json.dumps(report,indent=2)+'\n')
print('Verified 58 byte-identical phases, 6 targeted edits, 128 integer PNG exports, 4 eight-frame GIFs and 144 FHD crops.')
