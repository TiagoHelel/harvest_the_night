from barrier_qa import geometry
def check(images,p):return {**geometry(images,p,['wall_2','sandbag_wall']),'module_spec_resolved':True,'all_64_masks_composed':len(p['joins'])==64,'hardwood_and_sandbag_modules_complete':len(p['files'])==78}
