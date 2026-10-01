"""Exercise the damaged exhaust guard entirely in memory; never change assets."""
from pathlib import Path
import copy
import json
import sys

ROOT=Path(__file__).resolve().parents[4]
sys.path.insert(0,str(ROOT/'tools'))
import import_art
import check_station_art

if __name__=='__main__':
    original=import_art.load_manifest
    bad=copy.deepcopy(original())
    entry=next(e for e in bad['assets'] if e['id']=='props/generator_hurt')
    entry['smoke_xy']=[38,14]
    import_art.load_manifest=lambda:bad
    try:
        check_station_art.main()
    except ValueError as error:
        assert 'Station exhaust leaves its source in this state: props/generator_hurt' in str(error)
        result=dict(test='Damaged exhaust outside authored pixels rejected',passed=True,message=str(error),disk_assets_modified=False)
        Path(__file__).with_suffix('.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8',newline='\n')
        print('PASS: damaged exhaust point rejected without changing any disk asset')
    else:
        raise AssertionError('Invalid damaged exhaust was accepted')
    finally:
        import_art.load_manifest=original
