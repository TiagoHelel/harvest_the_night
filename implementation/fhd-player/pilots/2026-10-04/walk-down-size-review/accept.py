"""Freeze the exact eight DOWN files explicitly approved by the user."""
from pathlib import Path
import hashlib
import json

HERE=Path(__file__).resolve().parent
PILOT=HERE.parent
def save(path, data):
    path.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
request=json.loads((HERE/'request.json').read_text())
frames=HERE/request['candidate']
hashes={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(frames.glob('*.png'))}
assert len(hashes)==8 and hashes==request['candidate_frame_sha256']
approval={'date':'2026-10-05','status':'approved','user_feedback':'lindo',
    'candidate':request['candidate'],'approved_frame_sha256':hashes,'runtime_integrated':False}
save(HERE/'approval.json',approval)
request.update({'status':'approved','approval_date':'2026-10-05','user_feedback':'lindo',
    'palette_harmonization':'Next user request: shared RIGHT palette and three variants.'})
save(HERE/'request.json',request)
for path in [HERE/'validation.json',HERE/'down-r3/validation.json',HERE/'down-r3.call.json']:
    data=json.loads(path.read_text())
    data.update({'status':'approved','approval_date':'2026-10-05','user_feedback':'lindo',
        'approved_frame_sha256':hashes})
    if 'visual_review' in data:
        data['visual_review']['limits']='User approved the exact R3 size and animation review. Front arms remain subtle; no runtime promotion.'
    save(path,data)
status_path=PILOT/'directions-status.json'
status=json.loads(status_path.read_text())
status['walk_down']['size_refinement_review'].update(approval)
status['walk_down']['size_refinement_review']['candidate']='walk-down-size-review/'+request['candidate']
status['walk_down']['size_refinement_review']['palette_harmonization']='Requested as next separate review.'
status['pending_reviews']=[s for s in status['pending_reviews'] if s!='down-size-refinement']
save(status_path,status)
print('Approved: eight exact DOWN files frozen; other direction approval states retained.')
