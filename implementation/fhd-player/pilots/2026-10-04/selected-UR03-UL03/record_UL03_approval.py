"""Freeze the explicitly approved UL03 review cycle without runtime promotion."""
from pathlib import Path
import hashlib
import json

HERE = Path(__file__).resolve().parent
paths = list((HERE / 'UL03/frames').glob('*.png'))
assert len(paths) == 8
hashes = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(paths)}
approval = {'date': '2026-10-05', 'user_feedback': 'UL03 aprovado',
            'status': 'approved', 'candidate': 'UL03/frames',
            'frame_sha256': hashes, 'runtime_integrated': False}
(HERE / 'UL03-approval.json').write_text(json.dumps(approval, indent=2) + '\n')
path = HERE.parent / 'directions-status.json'
status = json.loads(path.read_text())
ul = status['walk_up_left']
ul.update(status='approved', date='2026-10-05', approval_date='2026-10-05',
          candidate='selected-UR03-UL03/UL03/frames',
          preview='selected-UR03-UL03/index.html', user_feedback='UL03 aprovado',
          review_limit='User approved the exact selected UL03 cycle with local frames5/6 corrections.')
ul['selected_archive_review'].update(status='approved', user_feedback='UL03 aprovado',
                                      approved_frame_sha256=hashes)
status['walk_up_right'].update(user_feedback='Frame7 lifted foot remains malformed; UL03 approved.',
                               status='awaiting_approval')
status['walk_up_right']['selected_archive_review'].update(status='frame7_rejected',
    user_feedback='Frame7 foot remains malformed; rebuild the boot silhouette.')
path.write_text(json.dumps(status, indent=2) + '\n')
print('Recorded explicit UL03 approval; exact eight-frame hashes frozen.')
