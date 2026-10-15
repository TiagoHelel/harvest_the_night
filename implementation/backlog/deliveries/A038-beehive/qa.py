"""Hive geometry, cue locality and tiny cloud invariants; no art modifications."""
def check(images,plan):
 by={}
 for f in plan['files']:by.setdefault(f['anim'],[]).append((f,images[f['output']]))
 dims=lambda im:(im.getbbox()[2]-im.getbbox()[0],im.getbbox()[3]-im.getbbox()[1])
 ret={};whole_images=[]
 for root,target in [('beehive',([16,18],[20,22])),('beehive_2',([20,22],[25,28]))]:
  fs=[by[root+s][0] for s in ['', '_hurt','_fire','_wreck']];a=fs[0][1];fire=fs[2][1];whole_images.append(a);w,h=dims(a);ret[root+'_whole_targets']=target[0][0]<=w<=target[0][1] and target[1][0]<=h<=target[1][1];ret[root+'_wreck_inside_whole']=fs[3][1].getbbox()[0]>=a.getbbox()[0] and fs[3][1].getbbox()[2]<=a.getbbox()[2];ret[root+'_one_source_scale']=len({f['source'] for f,im in fs})==1 and len({f['recipe']['content_scale'] for f,im in fs})==1
  x,y=fs[0][0]['points']['muzzle_xy'];diff=[(xx,yy) for yy in range(48) for xx in range(32) if a.getpixel((xx,yy))!=fire.getpixel((xx,yy)) and not(x-2<=xx<x+3 and y-2<=yy<y+3)];ret[root+'_fire_body_exact']=not diff;ret[root+'_body_pixels_changed_outside_cue']=len(diff);ret[root+'_entrance_points_shared']=len({tuple(f['points']['muzzle_xy']) for f,im in fs[:3]})==1;ret[root+'_states_distinct']=len({im.tobytes() for f,im in fs})==4
 ret['level_upgrade_differs_80px']=sum(a!=b for a,b in zip(whole_images[0].get_flattened_data(),whole_images[1].get_flattened_data()))>=80
 sw=sorted(by['bee_swarm'],key=lambda t:t[0]['frame']);areas=[];counts=[];sizes=[]
 for f,im in sw:
  b=im.getbbox();areas.append((b[2]-b[0])*(b[3]-b[1]));pending={(x,y) for y in range(8) for x in range(8) if im.getpixel((x,y))[3]};parts=[]
  while pending:
   q=[pending.pop()];p=set(q)
   while q:
    x,y=q.pop()
    for v in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]:
     if v in pending:pending.remove(v);p.add(v);q.append(v)
   parts.append(len(p))
  counts.append(len(parts));sizes.append(parts)
 ret['swarm_inside_six_px']=all(im.getbbox()[0]>=1 and im.getbbox()[1]>=1 and im.getbbox()[2]<=7 and im.getbbox()[3]<=7 for f,im in sw);ret['swarm_four_to_six_tiny_bees']=all(4<=n<=6 for n in counts) and all(1<=n<=2 for p in sizes for n in p);ret['swarm_size_variation_quarter']=max(areas)<=min(areas)*1.25;ret['swarm_three_distinct']=len({im.tobytes() for f,im in sw})==3;ret['swarm_gold_ink_only']=all({p[:3] for p in im.get_flattened_data() if p[3]}<={(36,31,46),(196,150,70)} for f,im in sw);ret['swarm_components']=sizes
 return ret
