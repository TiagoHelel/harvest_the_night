"""New animation GIF previews at nearest 4x, with exact original scale."""
from PIL import Image
from io import BytesIO
def render(images,plan,out):
 html='<section><h2>New additions only / pending review</h2><p>The original fourteen exports are unchanged and approved. Judge the four-frame heavy stride and the compact raised-staff cast below.</p>'
 for name in ['winter_lord_walk','winter_lord_cast']:
  fs=sorted([f for f in plan['files'] if f['anim']==name],key=lambda f:f['frame']);frames=[]
  for f in fs:
   im=Image.new('RGBA',(88,68),(29,40,44,255));im.alpha_composite(images[f['output']],(4,2));frames.append(im.convert('RGB').resize((352,272),Image.Resampling.NEAREST))
  b=BytesIO();dur=[round(f['seconds']*1000) for f in fs];dur[-1]=dur[-1] if fs[0]['loop'] else 1000
  frames[0].save(b,format='GIF',save_all=True,append_images=frames[1:],duration=dur,loop=0,disposal=2);out[f'preview/{name}-new.gif']=b.getvalue();html+=f'<h3>{name}</h3><img src="preview/{name}-new.gif">'
 return html+'</section>'
