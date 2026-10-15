"""Measured geometry and motion invariants. False visual results remain visible."""
def check(images,plan):
 groups={}
 for f in plan['files']:groups.setdefault(f['anim'],[]).append(images[f['output']])
 a,b=groups['dog_sit'];w0,w1=groups['dog_wag'];s0,s1=groups['dog_sleep'];barks=groups['dog_bark']
 def dims(im):
  x0,y0,x1,y1=im.getbbox();return x1-x0,y1-y0
 def same(ims,box,alpha=False):
  vals=[(im.getchannel('A') if alpha else im).crop(box).tobytes() for im in ims]
  return len(set(vals))==1
 return {'seven_animations_complete':{k:len(v) for k,v in groups.items()}=={'dog_sit':2,'dog_wag':2,'dog_walk':4,'dog_bark':3,'dog_sleep':2,'dog_run':4,'dog_bite':3},'idle_body_identical':same([a,b],(0,19,40,32)),'idle_paw_alpha_stationary':same([a,b],(0,27,40,32),True),'sitting_visible_targets':all(13<=dims(im)[0]<=15 and 17<=dims(im)[1]<=19 for im in [a,b]),'wag_only_tail_changes':same([w0,w1],(0,0,26,32)),'wag_paws_stationary':same([w0,w1],(0,26,40,32),True),'bark_paws_stationary':same(barks,(0,27,40,32),True),'sleep_head_paws_stationary':same([s0,s1],(0,24,40,32)),'sleep_visible_targets':all(16<=dims(im)[0]<=20 and 8<=dims(im)[1]<=10 for im in [s0,s1]),'run_stretch_visible_targets':24<=dims(groups['dog_run'][3])[0]<=28 and 12<=dims(groups['dog_run'][3])[1]<=15,'distinct_animation_frames':all(len({im.tobytes() for im in ims})==len(ims) for name,ims in groups.items()),'all_facing_west_metadata':all(f['dir']=='west' and f['mirror']=='runtime' for f in plan['files'])}
