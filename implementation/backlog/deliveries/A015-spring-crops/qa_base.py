"""Numeric checks for the generated candidates; no artwork is modified."""
from pathlib import Path
from PIL import Image
import itertools
D=Path(__file__).resolve().parent;ROOT=D.parents[3]
def check(images,plan):
 from import_art import render_source
 from palette import COLOURS
 fs=plan['files'];ret={};by={}
 if any(im.getbbox() is None for im in images.values()):return {'family_frames_nonempty':False}
 for f in fs:by.setdefault(f['anim'],[]).append((f,images[f['output']]))
 for v in by.values():v.sort(key=lambda t:t[0]['frame'])
 ret['visible_targets']=all(not f.get('visible_limits_wh') or all(l[0]<=n<=l[1] for l,n in zip(f['visible_limits_wh'],[im.getbbox()[2]-im.getbbox()[0],im.getbbox()[3]-im.getbbox()[1]])) for f in fs for im in [images[f['output']]])
 icons=[(f,images[f['output']]) for f in fs if f.get('resource_id')]
 if icons:
  ret['icon_bounds_ok']=all(im.getbbox()[0]>=1 and im.getbbox()[1]>=1 and im.getbbox()[2]<im.width and im.getbbox()[3]<im.height for f,im in icons);ret['icon_density']=all(sum(a>0 for r,g,b,a in im.get_flattened_data())>(7 if im.width==10 else 24) for f,im in icons);ret['icon_colours_at_least2']=all(len({p[:3] for p in im.get_flattened_data() if p[3]})>=2 for f,im in icons);ret['same_crop_per_pair']=all(len({tuple(f['recipe']['crop_xywh']) for f,im in icons if f['resource_id']==id})==1 for id in {f['resource_id'] for f,im in icons});ret['icons_unique']=all(len({im.tobytes() for f,im in icons if im.width==size})==sum(im.width==size for f,im in icons) for size in [10,16])
 if D.name.startswith('A023'):
  bob=[(f,im) for f in fs for im in [images[f['output']]] if f['anim'].startswith('bobber')];ret['bobber_one_source']=len(bob)==5 and len({f['source'] for f,im in bob})==1 and len({(f['recipe']['crop_xywh'][0],f['recipe']['crop_xywh'][1],f['recipe']['crop_xywh'][2],f['recipe']['content_scale']) for f,im in bob})==1;ret['bobber_waterline']=all(im.getbbox()[3]==6 and im.getbbox()[1]==f['points']['line_xy'][1] and im.getpixel(tuple(f['points']['line_xy']))[3]==255 for f,im in bob)
  if 'fishbar_zone' in by:
   f,z=by['fishbar_zone'][0];ret['zone_centre_uniform']=all(len({z.getpixel((x,y)) for x in range(2,6)})==1 for y in range(6));ret['zone_fills_canvas']=set(z.getchannel('A').get_flattened_data())=={255};ret['patch_margins_match']=f['points'].get('patch_margins_lrtb')==[2,2,0,0]
  if 'fishbar_frame' in by:
   f,z=by['fishbar_frame'][0];x,y,w,h=f['points']['track_xywh'];ret['track_ok']=h==6 and w>=80 and abs(x+w/2-50)<=1 and all(z.getpixel((xx,yy))[3] and z.getpixel((xx,yy))[:3] in {COLOURS['water_dark'],COLOURS['water']} for yy in range(y,y+h) for xx in range(x,x+w))
  ret['flash_expands_then_fades']=all(len(by.get(id,[]))==3 and max(by[id][1][1].getbbox()[2]-by[id][1][1].getbbox()[0],by[id][1][1].getbbox()[3]-by[id][1][1].getbbox()[1])>max(by[id][0][1].getbbox()[2]-by[id][0][1].getbbox()[0],by[id][0][1].getbbox()[3]-by[id][0][1].getbbox()[1]) and sum(a>0 for r,g,b,a in by[id][2][1].get_flattened_data())<sum(a>0 for r,g,b,a in by[id][1][1].get_flattened_data()) for id in ['fishbar_hit','fishbar_miss'])
 if D.name.startswith('A036'):
  if len(by.get('moon_stone',[]))==2:
   a,b=[im for f,im in by['moon_stone']];ret['moon_alpha_identical']=a.getchannel('A').tobytes()==b.getchannel('A').tobytes();diff=[(x,y) for y in range(16) for x in range(16) if a.getpixel((x,y))!=b.getpixel((x,y))];ret['moon_changed_pixels']=len(diff);ret['moon_glint_3_to_8']=3<=len(diff)<=8 and all(a.getpixel((x,y))[3] and b.getpixel((x,y))[3] for x,y in diff)
  if len([k for k in by if k.startswith('tilled_')])==2:
   a=by['tilled_fertilised'][0][1];b=by['tilled_fertilised_wet'][0][1];ret['soil_fully_opaque']=all(set(im.getchannel('A').get_flattened_data())=={255} for im in [a,b]);brightness=lambda im:sum(sum(p[:3])/3 for p in im.get_flattened_data())/256;ret['wet_brightness_delta']=brightness(a)-brightness(b);ret['wet_darker_by_20']=ret['wet_brightness_delta']>=20
   mask={(x,y) for y in range(16) for x in range(16) if a.getpixel((x,y))[:3] in {COLOURS['bone'],COLOURS['bone_dark']}};wetmask={(x,y) for y in range(16) for x in range(16) if b.getpixel((x,y))[:3] in {COLOURS['stone'],COLOURS['stone_light']}};pending=set(mask);clusters=[]
   while pending:
    group={pending.pop()};todo=list(group)
    while todo:
     x,y=todo.pop()
     for p in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]:
      if p in pending:pending.remove(p);group.add(p);todo.append(p)
    clusters.append(group)
   ret['fertiliser_cluster_sizes']=[len(c) for c in clusters];ret['fertiliser_clusters_ok']=5<=len(clusters)<=8 and all(2<=len(c)<=4 and sum(a.getpixel(p)[:3]==COLOURS['bone'] for p in c)<=1 for c in clusters) and 14<=len(mask)<=32 and all(0<x<15 and 0<y<15 for x,y in mask) and all(any(x//8==qx and y//8==qy for x,y in mask) for qx in range(2) for qy in range(2));ret['wet_clusters_same_positions']=mask==wetmask
   means=[sum(sum(a.getpixel((x,y))[:3])/3 for x in range(16))/16 for y in range(16)];ret['furrow_rows_preserved']=all(sum(means[y] for y in [2+4*k,3+4*k])/2<sum(means[y] for y in [0+4*k,1+4*k])/2 for k in range(4))
 if D.name.startswith('A057'):
  im=next(iter(images.values()));ret['header_fully_opaque']=set(im.getchannel('A').get_flattened_data())=={255};sky={COLOURS[k] for k in ['night_light','cloth_light','water_light','roof_light','flame','gold_light','flame_hot']};ret['sky_band_ramp_matches']=all(sum(im.getpixel((x,y))[:3] in sky for x in range(206))>=130 for y in range(3));ret['header_exact_aspect_crop']=all(f['recipe']['crop_xywh'][2]*40==f['recipe']['crop_xywh'][3]*206 for f in fs)
 if D.name.startswith(('A026','A027')):
  species=['sheep','pig'] if D.name.startswith('A026') else ['cow','chicken'];ret['west_only']=all(f['dir']=='west' and f['mirror']=='runtime' for f in fs);ret['body_size_coherent']=True;ret['standing_height_coherent']=True;ret['stationary_feet_stable']=True;ret['walk_support_feet']=True
  for id in species:
   idle=by.get(id+'_idle',[])
   if not idle:continue
   master=idle[0][1];mb=master.getbbox();stand=[im for key,v in by.items() if key in [id+'_idle',id+'_walk'] for f,im in v];ret['body_size_coherent'] &= all(abs((im.getbbox()[2]-im.getbbox()[0])-(mb[2]-mb[0]))<=1 for im in stand);ret['standing_height_coherent'] &= all(abs((im.getbbox()[3]-im.getbbox()[1])-(mb[3]-mb[1]))<=1 for im in stand)
   for state in ['idle','eat','sleep']:
    frames=[im for f,im in by.get(id+'_'+state,[])];ret['stationary_feet_stable'] &= len(frames)==2 and all(im.crop((0,im.height-4,im.width,im.height)).tobytes()==frames[0].crop((0,im.height-4,im.width,im.height)).tobytes() for im in frames)
   for f,im in by.get(id+'_walk',[]):
    row=f['pivot_xy'][1]-1;xs=[x for x in range(im.width) if im.getpixel((x,row))[3]];runs=sum(i==0 or xs[i]>xs[i-1]+1 for i in range(len(xs)));ret['walk_support_feet'] &= runs >=(1 if id=='chicken' else 2)
 if D.name.startswith(('A026','A027')):
  ret['sleep_body_width_coherent']=all(all(abs((im.getbbox()[2]-im.getbbox()[0])-(by[id+'_idle'][0][1].getbbox()[2]-by[id+'_idle'][0][1].getbbox()[0]))<=2 for f,im in by.get(id+'_sleep',[])) for id in species)
 if D.name.startswith(('A026','A027')):
  ret['sleep_body_width_coherent']=all(all(abs((im.getbbox()[2]-im.getbbox()[0])-(by[id+'_idle'][0][1].getbbox()[2]-by[id+'_idle'][0][1].getbbox()[0]))<=2 for f,im in by.get(id+'_sleep',[])) for id in species)
 if D.name.startswith('A033') and by:
  frames=[im for f,im in sorted([(f,images[f['output']]) for f in fs],key=lambda t:0 if t[0]['anim']=='bin_closed' else t[0]['frame']+1)];ret['bin_four_states']=len(frames)==4;ret['bin_base_identical']=all(im.crop((0,12,24,24)).tobytes()==frames[0].crop((0,12,24,24)).tobytes() for im in frames);ret['bin_states_distinct']=len({im.tobytes() for im in frames})==4
 if D.name.startswith('A021'):
  pairs=[(by.get(id,[])+by.get(id+('_chipped' if id=='hardwood_stump' else '_b'),[])) for id in ['copper_ore','coal_seam','gold_ore','hardwood_stump']];ret['resource_variants_distinct']=all(len(v)==2 and len({im.tobytes() for f,im in v})==2 for v in pairs);ret['resource_scales_shared']=all(len({f['recipe']['content_scale'] for f,im in v})==1 for v in pairs);ret['resource_sizes_coherent']=all(max(im.getbbox()[2]-im.getbbox()[0] for f,im in v)-min(im.getbbox()[2]-im.getbbox()[0] for f,im in v)<=1 and max(im.getbbox()[3]-im.getbbox()[1] for f,im in v)-min(im.getbbox()[3]-im.getbbox()[1] for f,im in v)<=1 for v in pairs)
 if D.name.startswith('A031'):
  groups={id:[(f,images[f['output']]) for f in fs if f['anim']==id or f['anim'].startswith(id+'_')] for id in ['keg','preserves_jar','dairy','loom','mill']};ret['machine_four_states_each']=all(len(v)==4 for v in groups.values());ret['machine_states_distinct']=all(len({im.tobytes() for f,im in v})==4 for v in groups.values());ret['machine_ground_origin_consistent']=all(len({tuple(f['pivot_xy']) for f,im in v})==1 for v in groups.values())
 if D.name.startswith('A034'):
  idle=[im for f,im in by.get('peddler_idle',[])];ret['idle_neutral_repeated']=len(idle)==4 and idle[0].tobytes()==idle[1].tobytes()==idle[2].tobytes()
  if len(idle)==4:ret['blink_face_only']=all(idle[0].getpixel((x,y))==idle[3].getpixel((x,y)) for y in range(40) for x in range(40) if not(13<=x<=27 and 8<=y<=20))
  talk=[im for f,im in by.get('peddler_talk',[])];ret['talk_body_fixed']=len(talk)==4 and all(im.getpixel((x,y))==talk[0].getpixel((x,y)) for im in talk for y in range(40) for x in range(40) if not(5<=x<=18 and 7<=y<=25 or 16<=x<=24 and 13<=y<=19))
  if 'shop_closed' in by:
   im=by['shop_closed'][0][1];old=Image.open(ROOT/'sprites/props/shop.png').convert('RGBA');changed=sum(im.getpixel((x,y))!=old.getpixel((x,y)) for y in range(40) for x in range(32) if not(6<=x<=25 and 18<=y<=27));ret['shop_changed_outside_opening']=changed;ret['shop_frame_matches']=changed<=10
 if D.name.startswith('A018'):
  groups={metal:by.get(metal+'_sprinkler',[])+by.get(metal+'_sprinkler_spray',[]) for metal in ['copper','iron','gold']};ret['sprinkler_five_states_each']=all(len(v)==5 for v in groups.values());ret['sprinkler_base_identical']=all(all(im.crop((0,11,16,14)).tobytes()==v[0][1].crop((0,11,16,14)).tobytes() for f,im in v) for v in groups.values() if v);ret['nozzle_raised']=all(len(v)==5 and all(v[0][1].getbbox()[1]-im.getbbox()[1]==2 for f,im in v[1:]) for v in groups.values());ret['spray_points_fixed']=all(len({tuple(f['points']['spray_xy']) for f,im in v[1:]})==1 for v in groups.values() if len(v)>1);ret['one_scale_per_tier_sheet']=all(len({f['recipe']['content_scale'] for f,im in v})==1 for v in groups.values())
 if D.name.startswith('A030'):
  m=__import__('json').loads((D/'raw/master-measurements.json').read_text())['coop-master-c3-r1'];p=D/m['source'];p=p if p.exists() else D/'rejected'/p.name;n=render_source({'id':'coop-window-diagnostic','source':str(p),'canvas_wh':m['canvas_wh'],'pivot_xy':m['pivot_xy'],'palette':'tools/palette.py:COLOURS','alpha_threshold':128,**m['recipe']});ret['coop_window_glint_pixels']=sum(n.getpixel((x,y))[:3] in {COLOURS['bone'],COLOURS['moon']} for x in range(11,18) for y in range(43,50));ret['coop_window_glints_at_least2']=ret['coop_window_glint_pixels']>=2
 if D.name.startswith('A030'):
  m=__import__('json').loads((D/'raw/master-measurements.json').read_text())['coop-master-c3-r1'];p=D/m['source'];p=p if p.exists() else D/'rejected'/p.name;n=render_source({'id':'coop-window-diagnostic','source':str(p),'canvas_wh':m['canvas_wh'],'pivot_xy':m['pivot_xy'],'palette':'tools/palette.py:COLOURS','alpha_threshold':128,**m['recipe']});ret['coop_window_glint_pixels']=sum(n.getpixel((x,y))[:3] in {COLOURS['bone'],COLOURS['moon']} for x in range(11,18) for y in range(43,50));ret['coop_window_glints_at_least2']=ret['coop_window_glint_pixels']>=2
 if D.name.startswith(('A030','A035')):ret['building_geometry_and_points_measured']=all(f.get('geometry_verified') for f in fs)
 if D.name.startswith('A031'):
  jar=[f for f in fs if f['anim'] in ['preserves_jar','preserves_jar_active','preserves_jar_hurt']];ret['jar_points_measured']=len(jar)==3 and all(set(f.get('points',{}))=={'light_xy','smoke_xy'} for f in jar) and len({tuple(f['points']['light_xy']) for f in jar})==1 and len({tuple(f['points']['smoke_xy']) for f in jar})==1;ret['jar_firebox_warm_only_active']=False
  if len(jar)==3 and ret['jar_points_measured']:
   warm={COLOURS[k] for k in ['flame','flame_hot','gold_light']};ret['jar_firebox_warm_only_active']=all((images[f['output']].getpixel(tuple(f['points']['light_xy']))[:3] in warm)==(f['anim']=='preserves_jar_active') for f in jar)
 # Check genuine raw alpha against the recorded tool request, not a painted key-out.
 transparency=True
 for f in fs:
  call=__import__('json').loads((D/f['call']).read_text());raw=Image.open(D/f['source']).convert('RGBA');lo,hi=raw.getchannel('A').getextrema();transparent=call['arguments'].get('transparent_background',False);transparency &= lo==0 and hi>=128 if transparent else lo==hi==255
 ret['source_transparency_matches_call']=transparency
 return ret
