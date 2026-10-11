from pathlib import Path
import hashlib,json,shutil,sys
D=Path(__file__).resolve().parent
ident,source=sys.argv[1:3];source=Path(source);out=D/'raw'/f'{ident}-r1.png';shutil.copyfile(source,out)
a=json.loads((D/'raw'/f'{ident}-r1.request.json').read_text())
# write exact tool prompt
(D/'raw'/f'{ident}-r{rev}.prompt.txt').write_text(a['prompt'],encoding='utf-8')
call={'tool':'image_gen.imagegen','arguments':a,'input_images':[{'path':p,'sha256':hashlib.sha256(Path(p).read_bytes()).hexdigest(),'role':'material/layout/style reference or generated candidate edit target; approval is recorded separately'} for p in a['referenced_image_paths']],'returned_path':str(source),'copied_path':str(out),'sha256':hashlib.sha256(out.read_bytes()).hexdigest(),'date':'2026-10-10','revision':1,'decision':'pending inspection'}
(D/'raw'/f'{ident}-r1.call.json').write_text(json.dumps(call,indent=2)+'\n',encoding='utf-8')
print('Copied '+ident+' '+call['sha256'])
