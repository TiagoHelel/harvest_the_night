"""Promote reviewed locomotion through the existing raster owner, without recuts.

Superseded on 2026-10-05: the runtime idle/walk/run families now come from
`implementation/fhd-player/pilots/2026-10-04/palette-variants/promote_blue_walk.py`
(the user's blue eight-direction walk). This review and its sources are kept;
running this script again would put the earlier four-direction farmer back.
"""
from pathlib import Path
import argparse
import importlib.util
import json
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
import import_art

CONTRACT = HERE / 'runtime-locomotion-contract.json'
FAMILIES = ('idle_', 'walk_', 'run_')


def read_review():
    data = json.loads((HERE / 'review-contract.json').read_text())
    frames = sorted([e for e in data['frames'] if e['animation'].startswith(FAMILIES)], key=lambda e:e['id'])
    assert len(frames) == 76
    return {'version':1, 'integration':'User authorized runtime locomotion on 2026-10-02',
            'families':['idle','walk','run'], 'native_body_height':60,
            'draw_scale':.5, 'frames':frames}


def check_sources(contract):
    spec = importlib.util.spec_from_file_location('directional_review', HERE / 'build_review.py')
    review = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(review)
    for entry in contract['frames']:
        assert import_art.sha((ROOT / entry['source']).read_bytes()) == entry['source_sha256'], entry['id']
        assert import_art.sha((ROOT / entry['prompt']).read_bytes()) == entry['prompt_sha256'], entry['id']
        image = import_art.render_source(entry) if 'review_source' in entry else review.render_selected(entry)
        content = import_art.png(image)
        assert import_art.sha(content) == entry['output_sha256'], ('native source recipe changed', entry['id'])
        assert (ROOT / entry['output']).read_bytes() == content, ('review frame tampered', entry['id'])
    review.assert_lateral_knee_exchange(contract['frames'])
    review.assert_lateral_run_readability(contract['frames'])
    review.assert_walking_head_scale(contract['frames'])
    review.assert_front_walk_body_scale(contract['frames'])
    print('FHD SOURCE: 76 exact source-owned frames; lateral knees alternate and front/back walking heads match idle width.')


def runtime_entry(frame, contract_hash):
    native = frame['output']
    size, pivot = frame['canvas_wh'], frame['pivot_xy']
    return {'id':'actors/' + frame['id'], 'owner':'raster',
            'source':native, 'source_sha256':frame['output_sha256'],
            'crop_xywh':[0,0,*size], 'canvas_wh':size, 'pivot_xy':pivot,
            'content_anchor_xy':pivot, 'content_scale':1.0, 'draw_scale':.5,
            'alpha_threshold':128, 'palette':'tools/palette.py:COLOURS',
            'animation':frame['animation'], 'frame':frame['frame'],
            'seconds':frame['seconds'], 'loop':True,
            'output':'sprites/actors/' + frame['id'] + '.png',
            'output_sha256':frame['output_sha256'],
            'prompt':frame['prompt'], 'prompt_sha256':frame['prompt_sha256'],
            'references':[
                {'path':frame['source'], 'sha256':frame['source_sha256'], 'role':'Original generated locomotion master'},
                {'path':CONTRACT.relative_to(ROOT).as_posix(), 'sha256':contract_hash, 'role':'Source-owned native cut and ground registration contract'}],
            'tool':'built-in ImageGen', 'generation_task':'fhd-locomotion',
            'approval':'Runtime integration authorized by user on 2026-10-02'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    contract = json.loads(CONTRACT.read_text()) if args.check else read_review()
    # Activities can be reviewed later without silently changing promoted movement.
    assert contract == read_review(), 'Promoted locomotion differs from current selected review'
    check_sources(contract)
    content = (json.dumps(contract, indent=2) + '\n').encode()
    contract_hash = import_art.sha(content)
    replacements = [runtime_entry(e, contract_hash) for e in contract['frames']]
    manifest = json.loads(import_art.MANIFEST.read_text())
    previous = [e for e in manifest['assets'] if e['output'].startswith('sprites/actors/') and e['animation'].startswith(FAMILIES)]
    if args.check:
        assert CONTRACT.read_bytes() == content
        by_id = {e['id']:e for e in previous}
        assert by_id == {e['id']:e for e in replacements}, 'Runtime locomotion ownership/geometry drift'
        for entry in replacements:
            assert (ROOT / entry['output']).read_bytes() == (ROOT / entry['source']).read_bytes(), entry['id']
        print('FHD RUNTIME: 12 idle + 32 walk + 32 run frames; exact native bytes, 0.5 draw scale, four directions.')
        return
    old_paths, new_paths = {e['output'] for e in previous}, {e['output'] for e in replacements}
    assert old_paths <= new_paths, 'Promotion unexpectedly removes an old runtime path'
    CONTRACT.write_bytes(content)
    # Retain every existing recipe's position, avoiding unrelated manifest churn.
    by_output = {e['output']:e for e in replacements}
    kept = [by_output.get(e['output'], e) for e in manifest['assets']]
    last = max(i for i,e in enumerate(kept) if e['output'] in old_paths)
    kept[last + 1:last + 1] = [e for e in replacements if e['output'] not in old_paths]
    manifest['assets'] = kept
    import_art.MANIFEST.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8', newline='\n')
    registry_path = ROOT / 'assets/art_source/ownership.json'
    registry = json.loads(registry_path.read_text())
    registry['outputs'] = [e for e in registry['outputs'] if e['output'] not in old_paths]
    registry['outputs'] += [{'output':p,'owner':'raster'} for p in sorted(new_paths)]
    registry['outputs'].sort(key=lambda e:e['output'])
    registry_path.write_text(json.dumps(registry, indent=2) + '\n', encoding='utf-8', newline='\n')
    print('Registered reviewed locomotion; run python tools/import_art.py to regenerate runtime files.')


if __name__ == '__main__':
    main()
