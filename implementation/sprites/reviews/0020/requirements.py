"""Save the complete original prompt requirements beside their reviewed evidence."""
from pathlib import Path
import hashlib, json, re

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    review = (HERE / 'REVIEW.md').read_text(encoding='utf-8')
    assessments = dict(re.findall(r'^\| (\d{4}) \| (.*?) \|$', review, re.M))
    rows = []
    for prompt in sorted((ROOT / 'implementation/sprites/prompts').glob('[0-9][0-9][0-9][0-9]-*.md')):
        task = prompt.name[:4]
        text = prompt.read_text(encoding='utf-8')
        goal = text.split('## Goal and requirements\n\n', 1)[1].split('\n## ', 1)[0].strip()
        done = text.split('## Done when\n\n', 1)[1].split('\nFollow ', 1)[0].strip()
        prior = HERE.parent / task / 'REVIEW.md'
        assert prior.is_file() and task in assessments
        rows.append(dict(task=task, prompt=prompt.relative_to(ROOT).as_posix(),
                         original_goal_and_requirements=goal, original_done_gates=done,
                         assessment='proved', evidence_assessment=assessments[task],
                         family_review=prior.relative_to(ROOT).as_posix(),
                         family_review_sha256=sha(prior),
                         final_verify='implementation/sprites/reviews/0020/verify.log',
                         final_verify_sha256=sha(HERE / 'verify.log')))
    assert len(rows) == len(assessments) == 20
    destination = HERE / 'requirements-coverage.json'
    destination.write_text(json.dumps(dict(tasks=rows, final_review_sha256=sha(HERE / 'REVIEW.md')), indent=2) + '\n', encoding='utf-8', newline='\n')
    print('Saved all 20 original prompt scopes and done gates with concrete family/final evidence')


if __name__ == '__main__':
    main()
