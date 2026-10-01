"""Persist exact built-in tool outputs/prompts and hashes, never paint pixels."""
from pathlib import Path
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent


def main():
    attempts = []
    for path in sorted(HERE.glob('0005-*-call.json')):
        attempt = json.loads(path.read_text(encoding='utf-8'))
        returned = Path(attempt['returned_file'])
        source = ROOT / attempt['source']
        source.parent.mkdir(parents=True, exist_ok=True)
        if not source.exists():
            shutil.copyfile(returned, source)
        assert source.read_bytes() == returned.read_bytes(), str(source)
        attempt['source_sha256'] = hashlib.sha256(source.read_bytes()).hexdigest()
        prompt = HERE / ('0005-' + attempt['id'] + '.prompt.txt')
        exact = attempt['prompt_text'] + '\n'
        if not prompt.exists() or prompt.read_text(encoding='utf-8') != exact:
            prompt.write_text(exact, encoding='utf-8', newline='\n')
        attempts.append(attempt)
    (HERE / '0005-generations.json').write_text(json.dumps({'date': '2026-10-01', 'attempts': attempts}, indent=2)+'\n', encoding='utf-8', newline='\n')
    print('Saved %d raw source copies and exact prompt records' % len(attempts))


if __name__ == '__main__':
    main()
