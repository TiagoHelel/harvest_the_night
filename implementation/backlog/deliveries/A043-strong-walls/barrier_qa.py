"""Shared measured module/join diagnostics for newly generated barrier candidates."""
def geometry(images,plan,families):
 checks={};measure={}
 for family in families:
  paths=lambda name:f'native/{family}_{name}/none/01.png'
  whole=[images[paths(k)] for k in ['post','horizontal','vertical']]
  hurt=[images[paths(k+'_hurt')] for k in ['post','horizontal','vertical']]
  wreck=images[paths('wreck')];b=[im.getbbox() for im in whole];wb=wreck.getbbox()
  measure[family]={'whole_bounds':b,'wreck_bounds':wb,'hurt_alpha_difference':[sum(a!=z for a,z in zip(im.getchannel('A').get_flattened_data(),hm.getchannel('A').get_flattened_data())) for im,hm in zip(whole,hurt)]}
  checks[family+'_post_span_row20']=b[0][3]==20 and b[1][3]==20
  checks[family+'_horizontal_full_width']=b[1][0]==0 and b[1][2]==16
  checks[family+'_vertical_27_envelope']=b[2][3]-b[2][1]==27 and b[2][3]==28
  checks[family+'_wreck_bounds']=wb[2]-wb[0]<=14 and wb[3]-wb[1]<=(6 if family=='sandbag_wall' else 8) and wb[3]==28
  files=[f for f in plan['files'] if f.get('operation')=='compose' and f['anim'].startswith(family)]
  checks[family+'_all_32_masks_composed']=len(files)==32 and {plan['joins'][f['anim']]['mask'] for f in files}==set(range(16))
  checks[family+'_hurt_modules_different']=all(v>=3 for v in measure[family]['hurt_alpha_difference'])
  same_scale={f['recipe']['content_scale'] for f in plan['files'] if f['anim'].startswith(family)}
  checks[family+'_one_family_scale']=len(same_scale)==1
  mask_checks=[];diff=[]
  for mask in range(16):
   name=family+('' if mask==0 else f'_join_{mask}');im=images[f'native/{name}/none/01.png'];hm=images[f'native/{name}_hurt/none/01.png'];a=im.getchannel('A')
   mask_checks.append(bool(a.crop((0,0,1,32)).getbbox())==bool(mask&8) and bool(a.crop((15,0,16,32)).getbbox())==bool(mask&2) and bool(a.crop((0,0,16,min(7,b[0][1]))).getbbox())==bool(mask&1) and bool(a.crop((0,20,16,32)).getbbox())==bool(mask&4))
   diff.append(sum(x!=y for x,y in zip(a.get_flattened_data(),hm.getchannel('A').get_flattened_data())))
  checks[family+'_mask_arms_match_bits']=all(mask_checks);checks[family+'_hurt_breaks_visible']=all(n>=3 for n in diff);measure[family]['join_alpha_differences']=diff
 checks['barrier_measurements']=measure
 return checks
