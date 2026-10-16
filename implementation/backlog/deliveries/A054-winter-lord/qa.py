"""Objective A054 geometry and completeness diagnostics for blocked candidates."""
from pathlib import Path
import json
D=Path(__file__).resolve().parent
def check(images,plan):
    groups={}
    for f in plan['files']: groups.setdefault(f['anim'],[]).append((f,images[f['output']]))
    def bounds(anim): return [im.getbbox() for _,im in groups.get(anim,[])]
    master=bounds('winter_lord')
    mb=master[0] if master else None
    death=[b[3]-b[1] for b in bounds('winter_lord_death') if b]
    shards=[b[2]-b[0] for b in bounds('ice_shards') if b]; shardh=[b[3]-b[1] for b in bounds('ice_shards') if b]
    head=bounds('head_winter_lord'); hb=head[0] if head else None
    return {
      'exact_22_files':len(plan['files'])==22,
      'master_size_ok':bool(mb and 34<=mb[2]-mb[0]<=46 and 46<=mb[3]-mb[1]<=52),
      'walk_has_4_frames':len(groups.get('winter_lord_walk',[]))==4,
      'cast_has_4_frames':len(groups.get('winter_lord_cast',[]))==4,
      'cast_height_ceiling_58':all(b[3]-b[1]<=58 for b in bounds('winter_lord_cast')),
      'new_frames_distinct':all(len({im.tobytes() for _,im in groups.get(anim,[])})==4 for anim in ['winter_lord_walk','winter_lord_cast']),
      'attack_has_3_frames':len(groups.get('winter_lord_attack',[]))==3,
      'death_has_5_frames':len(death)==5,
      'death_never_grows':len(death)==5 and all(a>=b for a,b in zip(death,death[1:])),
      'death_final_at_most_20':len(death)==5 and death[-1]<=20,
      'shards_have_4_frames':len(shards)==4,
      'shards_peak_fits':len(shards)==4 and max(shards)<=22 and max(shardh)<=17,
      'shards_expand_then_fade':len(shards)==4 and shards[1]>shards[0] and shards[3]<shards[1],
      'head_size_and_margin':bool(hb and hb[0]>=1 and hb[1]>=1 and hb[2]<=15 and hb[3]<=15 and max(hb[2]-hb[0],hb[3]-hb[1])==14),
      'all_required_groups_present':set(groups)=={'winter_lord','winter_lord_walk','winter_lord_cast','winter_lord_attack','winter_lord_death','ice_shards','head_winter_lord'}
    }
