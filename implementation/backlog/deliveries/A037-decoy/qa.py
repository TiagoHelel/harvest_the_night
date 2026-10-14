"""Check the requested decoy geometry and expose the rejected sway honestly."""
def check(images,plan):
 by={}
 for f in plan['files']:by.setdefault(f['anim'],[]).append((f,images[f['output']]))
 for fs in by.values():fs.sort(key=lambda t:t[0]['frame'])
 dims=lambda im:(im.getbbox()[2]-im.getbbox()[0],im.getbbox()[3]-im.getbbox()[1])
 whole=by['decoy'][0][1];hurt=by['decoy_hurt'][0][1];wreck=by['decoy_wreck'][0][1];bait=by['zombie_bait'][0][1]
 top=lambda im:sum(x for x in range(im.width) if im.getpixel((x,im.getbbox()[1]))[3])/sum(bool(im.getpixel((x,im.getbbox()[1]))[3]) for x in range(im.width))
 metrics={name:[top(im)-top(whole if name=='decoy_sway' else hurt) for f,im in by[name]] for name in ['decoy_sway','decoy_hurt_sway']}
 ret={'decoy_whole_targets':11<=dims(whole)[0]<=12 and 25<=dims(whole)[1]<=27 and whole.getbbox()[0]>=2 and whole.getbbox()[2]<=14,'wreck_targets':dims(wreck)[0]<=14 and dims(wreck)[1]<=8,'state_scale_shared':len({f['recipe']['content_scale'] for n in ['decoy','decoy_hurt','decoy_wreck'] for f,im in by[n]})==1,'state_alpha_distinct':len({im.getchannel('A').tobytes() for im in [whole,hurt,wreck]})==3,'bait_targets':dims(bait)[0]<=13 and 5<=dims(bait)[1]<=8 and bait.getbbox()[3]==14,'sway_top_offsets':metrics}
 for n,rest in [('decoy_sway',whole),('decoy_hurt_sway',hurt)]:
  ret[n+'_top_shift_ok']=all(abs(v-t)<=.5 for v,t in zip(metrics[n],[-2,1,-1]));ret[n+'_height_matches_rest']=all(abs(dims(im)[1]-dims(rest)[1])<=1 for f,im in by[n]);ret[n+'_distinct']=len({im.tobytes() for f,im in by[n]})==3
  centres=[]
  for f,im in by[n]:
   xs=[x for y in range(24,28) for x in range(16) if im.getpixel((x,y))[3]];centres.append((min(xs)+max(xs))/2)
  ret[n+'_base_fixed']=max(centres)-min(centres)<=1 and all(abs(x-8)<=1 for x in centres)
 icon=by['icon_zombie_bait'][0];hud=by['hud_zombie_bait'][0];ret['same_icon_crop']=icon[0]['recipe']['crop_xywh']==hud[0]['recipe']['crop_xywh'];ret['icon_bounds_ok']=all(im.getbbox()[0]>=1 and im.getbbox()[1]>=1 and im.getbbox()[2]<=im.width-1 and im.getbbox()[3]<=im.height-1 for f,im in [icon,hud]);ret['icon_density']=all(sum(p[3]>0 for p in im.get_flattened_data())>(24 if im.width==16 else 7) for f,im in [icon,hud]);ret['icon_colours_at_least2']=all(len({p[:3] for p in im.get_flattened_data() if p[3]})>=2 for f,im in [icon,hud])
 return ret
