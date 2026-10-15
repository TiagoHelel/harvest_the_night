from barrier_qa import geometry
def check(images,p):
 ims=[images[f['output']] for f in sorted(p['files'],key=lambda f:f['frame']) if f['anim']=='zap'];areas=[sum(a>0 for r,g,b,a in im.get_flattened_data()) for im in ims];warm=[sum(a>0 and r>150 and g>70 and b<130 for r,g,b,a in im.get_flattened_data()) for im in ims]
 return {**geometry(images,p,['electric_fence']),'all_32_masks_composed':len(p['joins'])==32,'module_spec_resolved':True,'zap_three_distinct':len({im.tobytes() for im in ims})==3,'zap_expands_then_fades':areas[1]==max(areas) and areas[2]<areas[1],'zap_two_to_three_warm_sparks':all(2<=n<=3 for n in warm),'warm_pixel_counts':warm}
