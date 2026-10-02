"""Record an agent's explicit visual decisions after opening named review pages."""
from pathlib import Path
import argparse, hashlib, json

HERE=Path(__file__).resolve().parent

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--note',required=True)
    parser.add_argument('pages',nargs='+')
    args=parser.parse_args()
    destination=HERE/'visual-review.json'
    data=json.loads(destination.read_text(encoding='utf-8')) if destination.exists() else dict(reviewed=[])
    for name in args.pages:
        path=(HERE/name).resolve()
        assert path.parent==HERE and path.suffix=='.png'
        record=dict(page=name,sha256=hashlib.sha256(path.read_bytes()).hexdigest(),decision='accepted',note=args.note)
        data['reviewed']=[r for r in data['reviewed'] if r['page']!=name]+[record]
    destination.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('Recorded',len(args.pages),'opened pages;',len(data['reviewed']),'total')

if __name__=='__main__':main()
