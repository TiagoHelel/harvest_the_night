"""Validate complete generated FX, fixed origins, palette/alpha and exact cuts."""
import json
import import_art

# The packs' effects: family, task, frames, canvas, pivot, origin, loop.
PACK_EFFECTS=[('bee_swarm','A038',3,[8,8],[4,4],'center',True),
              ('pumpkin_shot','A039',3,[8,8],[4,4],'center',True),
              ('pumpkin_splat','A039',4,[20,16],[10,14],'base',False)]


def main():
    data=import_art.load_manifest();files,images=import_art.build(data)
    plan=json.loads((import_art.ROOT/'implementation/sprites/generation/0017-plan.json').read_text())
    selected=[e for e in data['assets'] if e.get('generation_task')=='0017']
    assert len(selected)==25, 'All seven effects must own all 25 frames'
    for spec in plan:
        family=spec['id']
        frames=sorted((e for e in selected if e['fx_family']==family),key=lambda e:e['frame'])
        assert [e['frame'] for e in frames]==list(range(len(spec['modules']))),family
        assert len({e['source'] for e in frames})==len({e['content_scale'] for e in frames})==1,family
        shapes=[];areas=[]
        for e in frames:
            assert e['source']=='assets/art_source/effects/'+family+'.png'
            assert e['canvas_wh']==spec['canvas'] and e['pivot_xy']==spec['pivot'] and e['seconds']==spec['seconds'] and e['loop'] is False
            art=images[e['id']];box=art.getbbox();w,h=art.size
            assert box and box[0]>0 and box[1]>0 and box[2]<w and box[3]<h, 'Clipped FX: '+e['id']
            assert art.tobytes() not in shapes, 'Repeated effect pose: '+e['id']
            shapes.append(art.tobytes())
            samples=list(import_art.samples(art));visible=[p for p in samples if p[3]]
            assert all(p[3] in (0,255) for p in samples), 'Alpha fringe: '+e['id']
            areas.append(len(visible))
            if family=='smoke':assert sum(sum(p[:3])/3 for p in visible)/len(visible)<140, 'Bright smoke'
            if family=='splash':assert sum(p[2]-p[0] for p in visible)>0, 'Water lost blue ramp'
            assert (import_art.ROOT/e['output']).read_bytes()==files[e['output']], 'Runtime cut mismatch'
        assert areas[1]>areas[0] and areas[-1]<areas[1], 'No expansion/dissipation: '+family
    # The packs' own effects, each its own block, 0017's 25 frames untouched.
    # A loop (A038's swarm, task 0237; A039's pumpkin in the air, 0238) hangs
    # on as long as what it shows lasts, so it neither grows nor dies away; a
    # one-shot (A039's splat, 0238) bursts and fades as 0017's do.
    for family,task,count,canvas,pivot,origin,loop in PACK_EFFECTS:
        frames=sorted((e for e in data['assets'] if e.get('fx_family')==family),key=lambda e:e['frame'])
        assert [e['frame'] for e in frames]==list(range(count)) and all(e.get('generation_task')==task for e in frames),'%s owns its %d frames'%(family,count)
        assert len({e['source'] for e in frames})==len({e['content_scale'] for e in frames})==1,'One strip, one scale: '+family
        shapes=[];areas=[]
        for e in frames:
            assert e['output']=='sprites/effects/%s_%d.png'%(family,e['frame']),e['id']
            assert e['canvas_wh']==canvas and e['pivot_xy']==pivot and e['seconds']==0.1 and e['loop'] is loop and e['fx_origin']==origin,e['id']
            art=images[e['id']];box=art.getbbox();w,h=art.size
            assert box and box[0]>=0 and box[1]>=0 and box[2]<=w and box[3]<=h, 'Clipped FX: '+e['id']
            assert art.tobytes() not in shapes, 'Repeated effect pose: '+e['id']
            shapes.append(art.tobytes())
            samples=list(import_art.samples(art));visible=[p for p in samples if p[3]]
            assert all(p[3] in (0,255) for p in samples), 'Alpha fringe: '+e['id']
            areas.append(len(visible))
            assert (import_art.ROOT/e['output']).read_bytes()==files[e['output']], 'Runtime cut mismatch'
        if loop:
            assert min(areas)*2>=max(areas), 'A loop that grows or dies away: %s %s'%(family,areas)
        else:
            assert max(areas)>areas[0] and areas[-1]<max(areas), 'No expansion/dissipation: %s %s'%(family,areas)
    print('OK: seven FX families / 25 distinct one-shot frames / shared strip scales / palette alpha / unclipped origins / exact outputs; %d pack effects (%s)'%(len(PACK_EFFECTS),', '.join(f[0] for f in PACK_EFFECTS)))


if __name__=='__main__':main()
