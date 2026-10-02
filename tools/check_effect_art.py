"""Validate complete generated FX, fixed origins, palette/alpha and exact cuts."""
import json
import import_art


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
    print('OK: seven FX families / 25 distinct one-shot frames / shared strip scales / palette alpha / unclipped origins / exact outputs')


if __name__=='__main__':main()
