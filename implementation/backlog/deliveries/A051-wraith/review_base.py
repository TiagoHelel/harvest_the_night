"""Review-only compositions. These previews never become runtime art."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageOps
import json,html
D=Path(__file__).resolve().parent;ROOT=D.parents[3]
def png(im):
 from io import BytesIO
 b=BytesIO();im.save(b,format='PNG');return b.getvalue()
def night(im):
 n=im.convert('RGBA');out=[]
 for r,g,b,a in n.get_flattened_data():
  lit=r/255*.36,g/255*.40,b/255*.82;grey=.299*lit[0]+.587*lit[1]+.114*lit[2];out.append(tuple(round(max(0,min(1,grey+.76*(v-grey)+o))*255) for v,o in zip(lit,(.040,.035,.105)))+(a,))
 n.putdata(out);return n
def render(images,plan,out):
 parts=[];by={}
 for f in plan['files']:by.setdefault(f['anim'],[]).append((f,images[f['output']]))
 def add(id,im,caption):
  out['preview/'+id+'.png']=png(im);out['preview/'+id+'-night.png']=png(night(im));parts.append('<h2>'+html.escape(caption)+'</h2><p>Native1x / FHD4x / world relight reference4x</p>'+''.join('<img src="preview/'+id+suffix+'.png" width="'+str(im.width*scale)+'" height="'+str(im.height*scale)+'">' for suffix,scale in [('',1),('',4),('-night',4)]))
 if D.name.startswith(('A022','A032')):
  role='portrait_' if D.name.startswith('A022') else 'icon_';items=[(k,v[0][1]) for k,v in by.items() if k.startswith(role)];size=32 if role.startswith('portrait') else 16;w=8*(size+8);im=Image.new('RGBA',(w,((len(items)+7)//8)*(size+24)),(26,24,48,255));draw=ImageDraw.Draw(im)
  for i,(name,n) in enumerate(items):
   x=i%8*(size+8);y=i//8*(size+24);im.alpha_composite(n,(x+4,y+16));draw.text((x+2,y+2),name[len(role):][:8],fill=(232,224,207))
  add('inventory-grid',im,'Inventory / collection size comparison (HUD stays unlit)')
  if D.name.startswith('A022'):
   im=Image.new('RGBA',(w,((len(items)+7)//8)*(size+8)),(232,224,207,255))
   for i,(name,n) in enumerate(items):
    silhouette=Image.new('RGBA',n.size,(26,24,48,255));silhouette.putalpha(n.getchannel('A'));im.alpha_composite(silhouette,(i%8*(size+8)+4,i//8*(size+8)+4))
   add('silhouettes',im,'Unlabelled silhouette comparison at the book portrait size')
 if D.name.startswith(('A026','A027')):
  grass=Image.open(ROOT/'sprites/terrain/grass.png').convert('RGBA');im=Image.new('RGBA',(240,64))
  for y in range(0,64,16):
   for x in range(0,240,16):im.alpha_composite(grass,(x,y))
  ids=['sheep_idle','pig_idle'] if D.name.startswith('A026') else ['cow_idle','chicken_idle'];actors=[(by[id][0][1],by[id][0][0]['pivot_xy']) for id in ids if id in by]
  for id in ['down','left']:actors.append((Image.open(ROOT/f'implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/{id}/01.png').convert('RGBA'),[20,36]))
  x=8
  for n,pivot in actors:im.alpha_composite(n,(x,54-pivot[1]));x+=n.width+8
  draw=ImageDraw.Draw(im)
  for x in range(0,240,16):draw.line((x,0,x,63),fill=(145,168,125,100))
  for y in range(0,64,16):draw.line((0,y,239,y),fill=(145,168,125,100))
  add('animal-size-family',im,'New animals and approved farmer down/left on a shared ground line; 16px review grid')
  for id,v in by.items():
   if len(v)<2:continue
   n=Image.new('RGBA',v[0][1].size)
   for f,frame in v:
    layer=frame.copy();layer.putalpha(layer.getchannel('A').point(lambda a:48 if a else 0));n.alpha_composite(layer)
   add('onion-'+id,n,'Onion skin / '+id)
   mirrored=Image.new('RGBA',((v[0][1].width+4)*len(v),v[0][1].height))
   for i,(f,frame) in enumerate(v):mirrored.alpha_composite(ImageOps.mirror(frame),(i*(frame.width+4),0))
   add('east-preview-'+id,mirrored,'Runtime east mirror preview only / '+id+' (no east deliverable)')
 if D.name.startswith('A036') and 'tilled_fertilised' in by:
  im=Image.new('RGBA',(48,48));dry=Image.open(ROOT/'sprites/crops/tilled.png').convert('RGBA');wet=Image.open(ROOT/'sprites/crops/tilled_wet.png').convert('RGBA');tiles=[dry,wet,by['tilled_fertilised'][0][1]]
  if 'tilled_fertilised_wet' in by:tiles.append(by['tilled_fertilised_wet'][0][1])
  for y in range(3):
   for x in range(3):im.alpha_composite(tiles[(x+y)%len(tiles)],(16*x,16*y))
  im.alpha_composite(Image.open(ROOT/'sprites/crops/carrot_3.png').convert('RGBA'),(16,16));add('fertilised-field',im,'Plain and fertilised dry/wet soil under a current carrot')
 if D.name.startswith('A057'):
  im=Image.new('RGBA',(480,270),(20,24,29,255));draw=ImageDraw.Draw(im);draw.rectangle((128,30,351,249),fill=(26,24,48),outline=(168,116,44));n=by['report_header'][0][1];im.alpha_composite(n,(137,35));draw.text((142,85),'MORNING OF DAY 2',fill=(232,224,207));
  for y,w in [(110,140),(135,170),(160,125),(185,150),(215,60)]:draw.rectangle((142,y,142+w,y+4),fill=(115,118,124))
  add('morning-report-mock',im,'480x270 morning report mock; header206x40 is not relit in the game')
 if D.name.startswith('A034'):
  grass=Image.open(ROOT/'sprites/terrain/grass.png').convert('RGBA');im=Image.new('RGBA',(180,110))
  for y in range(0,110,16):
   for x in range(0,180,16):im.alpha_composite(grass,(x,y))
  path=Image.open(ROOT/'sprites/terrain/path.png').convert('RGBA')
  for x in range(0,180,16):im.alpha_composite(path,(x,80))
  if 'shop_closed' in by:im.alpha_composite(by['shop_closed'][0][1].resize((64,80),Image.Resampling.NEAREST),(86,16))
  if 'peddler_idle' in by:im.alpha_composite(by['peddler_idle'][0][1],(42,58))
  im.alpha_composite(Image.open(ROOT/'implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png').convert('RGBA'),(8,58));add('peddler-shop-context',im,'Farmer / peddler1x / closed stall2x on the current path; diagnostic candidates')
  if 'peddler_walk' in by:
   v=by['peddler_walk'];im=Image.new('RGBA',(44*len(v),40))
   for i,(f,n) in enumerate(v):im.alpha_composite(ImageOps.mirror(n),(44*i,0))
   add('peddler-east-mirror',im,'East uses exact runtime horizontal mirroring; preview only')
 if D.name.startswith('A031'):
  items=[(id,v[0][1]) for id,v in by.items() if not any(id.endswith(s) for s in ['_active','_hurt','_wreck'])];im=Image.new('RGBA',(sum(n.width+8 for id,n in items)+48,108),(27,41,44,255));x=4
  for id,n in items:
   pivot=by[id][0][0]['pivot_xy'];im.alpha_composite(n,(x,100-pivot[1]));x+=n.width+8
  im.alpha_composite(Image.open(ROOT/'implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png').convert('RGBA'),(x,64));add('machine-family-scale',im,'Five production machines and farmer on one shared ground line')
 # Source/history inspector retains originals and provenance; thumbnails are review only.
 parts.append('<details><summary>ImageGen source history and exact prompts</summary><div style="display:flex;flex-wrap:wrap">')
 for call in sorted(list((D/'raw').glob('*.call.json'))+list((D/'rejected').glob('*.call.json'))):
  data=json.loads(call.read_text());name=call.name.replace('.call.json','.png');p=call.with_name(name)
  if not p.exists():continue
  stem=name[:-4];bucket=call.parent.name;reason=call.with_name(stem+'.reason.txt');detail=reason.read_text().strip() if reason.exists() else data.get('decision','pending inspection');parts.append('<figure><img src="'+bucket+'/'+name+'" width="180"><figcaption>'+html.escape(stem)+' / '+html.escape(detail)+'<br><a href="'+bucket+'/'+stem+'.prompt.txt">Exact prompt</a> / <a href="'+bucket+'/'+call.name+'">Provenance</a></figcaption></figure>')
 parts.append('</div></details>');return ''.join(parts)

