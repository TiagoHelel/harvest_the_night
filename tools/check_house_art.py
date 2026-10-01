"""Check independent house states, native contacts, window planes and slices."""
import sys
from PIL import Image
import import_art
import palette

def main():
    data=import_art.load_manifest();files,images=import_art.build(data)
    entries={e['id']:e for e in data['assets']}
    whole,hurt=[images['buildings/'+name] for name in ('house','house_hurt')]
    expected_points=[[32,33],[19,45],[41,45],[30,45],[52,46]]
    for name,im in (('house',whole),('house_hurt',hurt)):
        e=entries['buildings/'+name]
        if e.get('source')!='assets/art_source/buildings/house/'+('whole' if name=='house' else 'hurt')+'.png' or e['canvas_wh']!=[64,64] or e['pivot_xy']!=[32,60] or e['cell_offset_xy']!=[-8,-12]:
            raise ValueError('House lacks independent measured source/ground contract')
        bbox=im.getbbox()
        if not bbox or bbox[0]<2 or bbox[1]<2 or bbox[2]>62 or bbox[3]!=60:
            raise ValueError('House is clipped or misplaced')
        if e['windows_xy']!=expected_points or e['smoke_xy']!=[51,12]:
            raise ValueError('House emission moved from reviewed window/chimney locations')
        bright={palette.COLOURS[k] for k in ('flame_hot','bone','gold_light')}
        for rect in e['window_rects_xywh']:
            x,y,w,h=rect
            if sum(im.getpixel((i,j))[:3] in bright for j in range(y,y+h) for i in range(x,x+w))<2:
                raise ValueError('Window pane disappears at native resolution')
        assembled=Image.new('RGBA',(64,64));area=0
        for child in data['assets']:
            if child.get('input')==e['id']:
                if child['operation']!='slice':raise ValueError('House state uses a painted/generated damage substitute')
                x,y,w,h=child['slice_xywh'];assembled.paste(images[child['id']],(x,y));area+=w*h
        if area!=4096 or assembled.tobytes()!=im.tobytes():raise ValueError('House compatibility slices lose/duplicate roof pixels')
        # All full states and derived slices must be exact required outputs.
        for entry in [e]+[c for c in data['assets'] if c.get('input')==e['id']]:
            if (import_art.ROOT/entry['output']).read_bytes()!=files[entry['output']]:raise ValueError('House runtime differs from source: '+entry['id'])
    a,b=entries['buildings/house'],entries['buildings/house_hurt']
    if a['source']==b['source'] or a['crop_xywh']!=b['crop_xywh'] or a['content_scale']!=b['content_scale']:
        raise ValueError('House states refit or borrow a raw source')
    changed=sum(whole.getpixel((x,y))!=hurt.getpixel((x,y)) for y in range(18,36) for x in range(8,27))
    if changed<40:raise ValueError('Localized structural roof damage does not survive reduction')
    # Independently authored damage may change stone colors. Grounding is the
    # bottom alpha contact, not identical RGB on a painted stair tread.
    contacts=[]
    for im in (whole,hurt):
        row=[x for x in range(64) if im.getpixel((x,59))[3]]
        if not row or row[0]!=24 or not 34<=row[-1]<=35 or any(not im.getpixel((x,59))[3] for x in range(24,35)):
            raise ValueError('Damage shifts or breaks the reviewed entrance ground contact')
        contacts.append((row[0]+row[-1])/2)
    if abs(contacts[0]-contacts[1])>0.5:raise ValueError('Entrance contact drifts between independent states')
    print('OK: 2 independent source-owned house states; 18 exact roof slices; 5 readable glass lamps; shared scale/door contact; %d roof damage pixels'%changed)
    return 0

if __name__=='__main__':
    try:sys.exit(main())
    except (ValueError,KeyError,OSError) as error:print('FAIL: '+str(error));sys.exit(1)
