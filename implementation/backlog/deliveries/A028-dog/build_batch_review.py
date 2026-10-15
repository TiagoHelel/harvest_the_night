"""Build the consolidated owner-review page for the 21 requested art packs."""
from pathlib import Path
import json,re,subprocess,sys,html
ROOT=Path(__file__).resolve().parents[4]
DEL=ROOT/'implementation/backlog/deliveries'
OUT=Path(__file__).resolve().parent/'all-packs-review.html'
ids=['A028']+[f'A{i:03d}' for i in range(37,57)]
status_rows=subprocess.check_output([sys.executable,'-X','utf8',str(ROOT/'implementation/backlog/assets.py'),'list'],cwd=ROOT,text=True,encoding='utf-8')
statuses={}
for line in status_rows.splitlines():
 m=re.match(r'^(A\d{3})\s+(\w+)\s+(.+)$',line)
 if m: statuses[m.group(1)]=(m.group(2),m.group(3))
packs=[]
for pid in ids:
 matches=sorted(p for p in DEL.iterdir() if p.is_dir() and p.name.startswith(pid+'-'))
 if not matches: packs.append({'id':pid,'folder':None,'status':'missing','title':'Delivery folder missing','count':0,'bad':[],'index':None}); continue
 d=matches[0]; st,title=statuses.get(pid,('unknown',d.name))
 count=sum(1 for folder in [d/'native',d/'preview/candidates'] if folder.exists() for _ in folder.rglob('*.png'))
 checks={}
 for name in ['checks.json','candidate-contract.json']:
  p=d/name
  if p.exists() and name=='checks.json':
   try: checks=json.loads(p.read_text(encoding='utf-8'))
   except Exception: pass
 bad=[k for k,v in checks.items() if v is False]
 index='../'+d.name+'/index.html' if (d/'index.html').exists() else None
 packs.append({'id':pid,'folder':d.name,'status':st,'title':title,'count':count,'bad':bad,'index':index})
def esc(x): return html.escape(str(x),quote=True)
rows=[]; embeds=[]
for p in packs:
 link=f"<a href='{esc(p['index'])}' target='_blank'>Abrir revisão</a>" if p['index'] else '<span class="missing">sem página</span>'
 problems=', '.join(esc(x) for x in p['bad']) if p['bad'] else ('sem falha registrada' if p['count'] else 'sem quadros exportados')
 rows.append(f"<tr><td>{esc(p['id'])}</td><td>{esc(p['title'])}</td><td><b class='{esc(p['status'])}'>{esc(p['status'])}</b></td><td>{p['count']}</td><td>{problems}</td><td>{link}</td></tr>")
 if p['index']:
  embeds.append(f"<details><summary>{esc(p['id'])} · {esc(p['title'])} · {esc(p['status'])} · {p['count']} imagens</summary><p><a href='{esc(p['index'])}' target='_blank'>Abrir esta página em nova aba</a></p><iframe loading='lazy' src='{esc(p['index'])}' title='{esc(p['id'])}'></iframe></details>")
reviewed=sum(p['status']=='review' for p in packs); blocked=sum(p['status']=='blocked' for p in packs); missing=sum(p['status']=='missing' for p in packs)
page='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Revisão final · 21 pacotes de arte</title>
<style>body{background:#192326;color:#eee4d3;font:16px system-ui;margin:24px;line-height:1.45}a{color:#89d1cd}table{border-collapse:collapse;width:100%;margin:20px 0}th,td{border:1px solid #526064;padding:9px;text-align:left;vertical-align:top}th{background:#28383d}.review{color:#b7e7b8}.blocked,.missing{color:#ffb1a4}details{border:1px solid #526064;padding:12px;margin:16px 0}summary{cursor:pointer;font-weight:650}iframe{width:100%;height:75vh;border:1px solid #526064;background:#1b292c}code{background:#2d393d;padding:2px 5px;border-radius:3px}.note{background:#27373b;border-left:4px solid #dcbd79;padding:12px 16px}</style>
<h1>Revisão final · 21 pacotes de arte</h1><p>As páginas abaixo reúnem as imagens para sua revisão. A lista mostra o estado do runner e quantos quadros nativos/candidatos existem. Nenhum pacote foi aprovado automaticamente ou integrado ao jogo.</p>
<p class="note"><b>A056:</b> a autorização registrada permite usar A023 e A052–A054 apenas como referências candidatas. Isso não aprova nem integra esses pacotes. O A056 aparece como bloqueado porque as medalhas excedem a tolerância de alinhamento do contrato e a descrição do pacote diverge sobre 22/23 fontes.</p>
<p><b>Estados:</b> '''+str(reviewed)+''' em revisão, '''+str(blocked)+''' bloqueados, '''+str(missing)+''' sem entrega.</p>
<table><thead><tr><th>Pacote</th><th>Nome</th><th>Estado</th><th>Quadros nativos/candidatos</th><th>Falhas objetivas registradas</th><th>Página</th></tr></thead><tbody>'''+''.join(rows)+'''</tbody></table>
<h2>Páginas embutidas</h2><p>Expanda um pacote para navegar na sua revisão interativa; o link abre a versão isolada em outra aba.</p>'''+''.join(embeds)+'''</html>'''
OUT.write_text(page,encoding='utf-8')
print(json.dumps({'output':str(OUT),'packs':len(packs),'review':reviewed,'blocked':blocked,'missing':missing,'index_links':sum(bool(p['index']) for p in packs)},ensure_ascii=False,indent=2))
