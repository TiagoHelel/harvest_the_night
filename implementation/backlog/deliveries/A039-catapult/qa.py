"""Measure tower, shot and splat constraints without changing source art."""
def check(images,p):
 by={f['anim']:images[f['output']] for f in p['files'] if f['frame']==0};ret={};whole=[]
 for l,wlo,whi,hlo,hhi in [(1,20,22,17,19),(2,23,25,20,22),(3,26,28,24,27)]:
  n='catapult'+('' if l==1 else '_'+str(l));a=by[n];b=by[n+'_fire'];r=by[n+'_wreck'];box=a.getbbox();whole.append(a);ret[n+'_whole_dimensions']=wlo<=box[2]-box[0]<=whi and hlo<=box[3]-box[1]<=hhi;ret[n+'_wreck_inside_whole']=r.getbbox()[0]>=box[0] and r.getbbox()[2]<=box[2];ret[n+'_stationary_base_exact']=a.crop((0,40,32,44)).tobytes()==b.crop((0,40,32,44)).tobytes();fs=[f for f in p['files'] if f['anim'] in [n,n+'_hurt',n+'_fire',n+'_wreck']];ret[n+'_one_source_scale']=len({f['source'] for f in fs})==1 and len({f['recipe']['content_scale'] for f in fs})==1
 ret['level1_level3_differs80']=sum(a!=b for a,b in zip(whole[0].get_flattened_data(),whole[2].get_flattened_data()))>=80
 ret['twelve_distinct_tower_states']=len({im.tobytes() for n,im in by.items() if n.startswith('catapult')})==12
 ret['tower_clearance']=all(im.getbbox()[0]>=1 and im.getbbox()[1]>=1 and im.getbbox()[2]<=31 and im.getbbox()[3]==44 for n,im in by.items() if n.startswith('catapult'))
 for n,N in [('pumpkin_shot',3),('pumpkin_splat',4)]:
  fs=sorted([f for f in p['files'] if f['anim']==n],key=lambda f:f['frame']);ims=[images[f['output']] for f in fs];ret[n+'_count_distinct']=len(ims)==N and len({im.tobytes() for im in ims})==N;ret[n+'_single_source_scale']=len({f['source'] for f in fs})==1 and len({f['recipe']['content_scale'] for f in fs})==1;ret[n+'_clearance']=all(im.getbbox()[0]>=1 and im.getbbox()[1]>=1 and im.getbbox()[2]<im.width and im.getbbox()[3]<im.height for im in ims)
  if n=='pumpkin_splat':
   areas=[sum(a>0 for r,g,b,a in im.get_flattened_data()) for im in ims];ret['splat_peak_then_dissipation']=areas[1]==max(areas) and areas[3]<areas[1];ret['splat_no_blood_rgb']=all((142,43,51,255) not in set(im.get_flattened_data()) for im in ims)
 return ret
