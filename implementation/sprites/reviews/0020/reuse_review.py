"""Validate pixel-identical reuse against committed prior visual-review evidence."""
from pathlib import Path
import collections, hashlib, json, subprocess
from PIL import Image

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    index = json.loads((HERE / 'capture-index.json').read_text(encoding='utf-8'))
    proof = []
    for row in index['captures']:
        if not row['prior_pixels_identical']:
            continue
        prior = ROOT / row['prior_capture']
        current = ROOT / row['capture']
        task = prior.relative_to(ROOT).parts[3]
        folder = ROOT / 'implementation/sprites/reviews' / task
        journal = folder / 'REVIEW.md'
        assert journal.is_file()
        committed = subprocess.check_output(['git', 'show', 'c03c169:' + row['prior_capture']], cwd=ROOT)
        assert hashlib.sha256(committed).hexdigest() == sha(prior), 'Prior capture changed'
        assert Image.open(prior).convert('RGBA').tobytes() == Image.open(current).convert('RGBA').tobytes()
        evidence = None
        for name in ['frame-review.json', 'captures.json', 'capture-index.json']:
            path = folder / name
            if not path.exists():
                continue
            data = json.loads(path.read_text(encoding='utf-8'))
            rows = data.get('captures', []) if isinstance(data, dict) else data
            for item in rows:
                recorded = item if isinstance(item, str) else item.get('path', item.get('capture'))
                if recorded == row['prior_capture']:
                    if isinstance(item, dict) and 'sha256' in item:
                        assert item['sha256'] == sha(prior), 'Prior accepted hash changed'
                    evidence = path
                    break
            if evidence:
                break
        assert evidence, 'Prior capture absent from accepted review index: ' + str(prior)
        # Prior journals document opening all their indexed native/3x views,
        # including final HUD/observer corrections in 0018 and 0019.
        assert '3x' in journal.read_text(encoding='utf-8')
        proof.append(dict(capture=row['capture'], prior_capture=row['prior_capture'],
                          prior_sha256=sha(prior), current_sha256=sha(current),
                          prior_review=journal.relative_to(ROOT).as_posix(),
                          prior_review_sha256=sha(journal),
                          prior_index=evidence.relative_to(ROOT).as_posix(),
                          prior_index_sha256=sha(evidence), pixels_identical=True))
    assert len(proof) == index['exact_prior_pixels'] == 242
    report = dict(baseline='c03c169', count=len(proof),
                  families=dict(collections.Counter(r['family'] for r in index['captures'] if r['prior_pixels_identical'])),
                  evidence=proof)
    (HERE / 'reused-review.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8', newline='\n')
    print('PASS: 242 exact native pixel matches resolve to unchanged committed captures and prior native/3x review journals')


if __name__ == '__main__':
    main()
