"""Check all resource icons at both native sizes and code-owned frame profiles."""
import json
from PIL import Image
import import_art
import art_ownership
import gen_sprites


def main():
    manifest=import_art.load_manifest();files,images=import_art.build(manifest)
    plans=json.loads((import_art.ROOT/'implementation/sprites/generation/0018-plan.json').read_text(encoding='utf-8'))
    entries=[e for e in manifest['assets'] if e.get('generation_task')=='0018']
    assert len(plans)==15 and len(entries)==30,'Incomplete resource family'
    registry=art_ownership.registry();seen={16:set(),10:set()}
    for plan in plans:
        resource=plan['id']
        family=[e for e in entries if e['resource_id']==resource]
        assert len(family)==2 and len({e['source'] for e in family})==1
        assert len({tuple(e['crop_xywh']) for e in family})==1
        call=json.loads((import_art.ROOT/f'implementation/sprites/generation/0018-{resource}-call.json').read_text(encoding='utf-8'))
        assert call['actual_submitted_arguments']['transparent_background'] is True
        assert call['actual_submitted_arguments']['prompt']==(import_art.ROOT/call['prompt']).read_text(encoding='utf-8')
        for e in family:
            size=16 if e['display_role']=='inventory' else 10
            assert e['id']==f'ui/{"icon" if size==16 else "hud"}_{resource}'
            assert e['canvas_wh']==[size,size] and e['pivot_xy']==[size//2]*2
            assert not e['loop'] and e['frame']==0 and registry[e['output']]=='raster'
            art=images[e['id']];box=art.getbbox();pixels=list(import_art.samples(art));visible=[p for p in pixels if p[3]]
            assert box and 0<box[0]<box[2]<size and 0<box[1]<box[3]<size,'Clipped icon: '+e['id']
            assert all(p[3] in (0,255) for p in pixels)
            assert len(visible)>(24 if size==16 else 7) and len({p[:3] for p in visible})>=2
            fingerprint=art.tobytes();assert fingerprint not in seen[size],'Duplicate silhouettes: '+e['id'];seen[size].add(fingerprint)
            assert (import_art.ROOT/e['output']).read_bytes()==files[e['output']]
    ascii_files=gen_sprites.everything()
    for name in ('panel','tooltip','tab','button_normal','button_hover','button_pressed','button_disabled',
                 'tab_hover','tab_selected','tab_disabled','button_focus','checkbox_on','checkbox_off',
                 'checkbox_on_disabled','checkbox_off_disabled','slider_track','slider_grab','slider_grab_highlight','slider_grab_disabled'):
        path='sprites/ui/'+name+'.png'
        assert registry[path]=='ascii' and (import_art.ROOT/path).read_bytes()==ascii_files['ui/'+name+'.png']
    for name in ('panel','tooltip','tab','button_normal'):
        art=Image.open(import_art.ROOT/f'sprites/ui/{name}.png').convert('RGBA')
        center=art.getpixel((8,8));border=next(x for x in range(16) if art.getpixel((x,8))==center)
        assert border==3,'Nine-patch margin drift: '+name
    focus=Image.open(import_art.ROOT/'sprites/ui/button_focus.png').convert('RGBA')
    assert focus.getpixel((8,8))[3]==0 and focus.getpixel((1,8))[3]==255,'Focus must be a visible open ring'
    print('OK: 15 exact generated resources / 30 distinct native cuts / clear margins / palette alpha / preserved three-pixel frame profiles / focus ring')


if __name__=='__main__':main()
