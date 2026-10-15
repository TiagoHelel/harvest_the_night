def check(images,p):
 by={}
 for f in p['files']:by.setdefault(f['anim'],[]).append((f,images[f['output']]))
 ret={}
 for n,wlo,whi,hlo,hhi in [('tarp_tower',22,24,22,26),('tarp_tall',11,13,22,25),('tarp_short',10,12,14,17)]:
  f,a=by[n][0];_,b=by[n+'_hurt'][0];box=a.getbbox();ret[n+'_covered_dimensions']=wlo<=box[2]-box[0]<=whi and hlo<=box[3]-box[1]<=hhi;ret[n+'_torn_alpha_differs']=a.getchannel('A').tobytes()!=b.getchannel('A').tobytes();v=sorted(by[n+'_unveil'],key=lambda q:q[0]['frame']);areas=[sum(a>0 for r,g,b,a in im.get_flattened_data()) for f,im in v];ret[n+'_away_smaller']=areas[1]<areas[0];ret[n+'_unveil_distinct']=v[0][1].tobytes()!=v[1][1].tobytes();ret[n+'_lower_half_revealed']=v[0][1].getbbox()[3]<=box[1]+(box[3]-box[1]+1)//2;fs=by[n]+by[n+'_hurt']+v;ret[n+'_one_raw_one_scale']=len({f['source'] for f,im in fs})==1 and len({f['recipe']['content_scale'] for f,im in fs})==1;ret[n+'_inside_canvas']=all(im.getbbox()[0]>=0 and im.getbbox()[1]>=0 and im.getbbox()[2]<=im.width and im.getbbox()[3]<=im.height for f,im in fs);ret[n+'_covered_clear_edge']=all(im.getbbox()[0]>=1 and im.getbbox()[1]>=1 and im.getbbox()[2]<im.width for f,im in by[n]+by[n+'_hurt'])
 return ret
