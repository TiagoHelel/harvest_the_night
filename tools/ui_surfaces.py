"""Refine the established code-owned UI kit; keep sizes and slice margins."""
from copy import deepcopy


def refine(sprites):
    # Trim only the outer corners. Mid-edge profiles remain three pixels,
    # and every center stays a calm solid field suitable for nine-slicing.
    for name in ('panel','tooltip','button_normal','button_hover',
                 'button_pressed','button_disabled','tab'):
        rows=sprites['ui/'+name]['rows']
        rows[0]='.'+rows[0][1:-1]+'.'
        if name!='tab':
            rows[-1]='.'+rows[-1][1:-1]+'.'
    for state,fill in [('hover','night_light'),('selected','night_light'),
                       ('disabled','ink_soft')]:
        spec=deepcopy(sprites['ui/tab'])
        spec['legend']['n']=fill
        if state=='selected':
            spec['legend']['g']='gold'
            spec['rows'][14]='kggggggggggggggk'
        elif state=='disabled':
            spec['legend']['g']='ink_soft'
            spec['legend']['l']='night_light'
        sprites['ui/tab_'+state]=spec
    for state in ('off','on'):
        spec=sprites['ui/checkbox_'+state]
        spec['rows'][0]='.'+spec['rows'][0][1:-1]+'.'
        spec['rows'][-1]='.'+spec['rows'][-1][1:-1]+'.'
        quiet=deepcopy(spec)
        quiet['legend']['s']='night_light'
        quiet['legend']['n']='ink_soft'
        if state=='on':quiet['legend']['g']='gold_dark'
        sprites['ui/checkbox_'+state+'_disabled']=quiet
    grab=sprites['ui/slider_grab']
    for y in (2,3,4,5):
        grab['rows'][y]='klglggdk'
    bright=deepcopy(grab)
    bright['legend']['g']='gold_light'
    bright['legend']['l']='bone'
    sprites['ui/slider_grab_highlight']=bright
    quiet=deepcopy(grab)
    quiet['legend'].update(g='night_light',l='ink_soft',d='ink')
    sprites['ui/slider_grab_disabled']=quiet
