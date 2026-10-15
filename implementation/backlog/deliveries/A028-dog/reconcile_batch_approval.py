"""Record the owner's batch approval without changing any reviewed art pixels."""
from pathlib import Path
from collections import Counter
import hashlib
import html
import json
import re
import subprocess
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
DELIVERIES = HERE.parent
IDS = ["A028"] + [f"A{i:03}" for i in range(37, 57)]
DATE = "2026-10-14"
OWNER_WORDS = (
    "meu amigo, todos aqueles assets que voce mandou pra eu aprovar hoje eu aprovei -> "
    "file:///C:/Users/Helel/Documents/repos/harvest_the_night/implementation/backlog/"
    "deliveries/A028-dog/all-packs-review.html"
)
PRIOR_WORDS = "tudo aprovado, mas eu vi 2 que ficaram sem imagens, ta certo?"
STRUCTURAL = {
    "frame_count_matches", "candidate_frame_count_matches", "exact_22_files",
    "all_required_groups_present", "all_three_states_complete", "seven_animations_complete",
    "all_32_masks_composed", "all_64_masks_composed", "module_spec_resolved",
    "hardwood_and_sandbag_modules_complete", "walk_has_4_frames", "cast_has_4_frames",
}
COMPLETE = {
    "A037", "A038", "A039", "A041", "A044", "A046", "A047", "A048",
    "A049", "A050", "A051", "A052", "A053", "A055", "A056",
}


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def write(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def normalize_files(files, complete):
    groups = Counter(f.get("anim", f.get("name")) for f in files)
    for f in files:
        anim = f.get("anim", f.get("name"))
        f.setdefault("anim", anim)
        f.setdefault("dir", f.get("direction", "none"))
        f.setdefault("frame", 0)
        f.setdefault("canvas_wh", f["recipe"].get("canvas_wh"))
        f.setdefault("pivot_xy", f["recipe"].get("pivot_xy"))
        f.setdefault("draw_scale", 1)
        f.setdefault("seconds", 1.0)
        f.setdefault("loop", False)
        f.setdefault("mirror", "none")
        f.setdefault("points", {})
        if not f.get("runtime_name"):
            folder = "ui" if anim.startswith(("head_", "hud_", "icon_")) else "enemies"
            if anim == "ice_shards":
                folder = "effects"
            name = anim + (f"_{f['frame']}" if groups[anim] > 1 else "")
            f["runtime_name"] = f"sprites/{folder}/{name}.png"
        if complete:
            f["output"] = f["output"].replace("preview/candidates/", "native/", 1)


def capture_baseline(d, pack):
    path = d / "approval-baseline.json"
    if path.exists():
        return read(path)
    contract = read(d / "contract.json")
    if not contract.get("files") and (d / "candidate-contract.json").exists():
        contract = read(d / "candidate-contract.json")
    files = contract.get("files", [])
    checks = read(d / "checks.json")
    plan = read(d / "raw/export-plan.json") if (d / "raw/export-plan.json").exists() else {}
    expected = plan.get("expected_files", contract.get("expected_pngs", 6 if pack == "A055" else len(files)))
    for f in files:
        assert (d / f["output"]).is_file(), (pack, f["output"])
        assert digest(d / f["output"]) == f["sha256"], (pack, "reviewed file changed", f["output"])
    data = {"contract": contract, "checks": checks, "expected": expected, "files": files}
    write(path, data)
    return data


GENERIC_APPROVAL_HOOK = '''
# Owner approval changes delivery metadata only; measured QA booleans remain intact.
if A:
 contract['owner_approval']={'date':A['date'],'owner_words':A['owner_words'],'scope':A['scope']}
 contract.setdefault('deviations',[]).append({'rule':'Reviewed visual constraints','change':'The owner accepted the exact displayed artwork, including the documented visual QA differences. Missing outputs are not approved or invented.','owner_words':A['owner_words'],'accepted_checks':A.get('accepted_visual_checks',[])})
 checks['owner_visual_approval_recorded']=True
 checks['owner_accepted_visual_checks']=A.get('accepted_visual_checks',[])
 banner='<aside style="padding:16px;background:#244533;color:#eef5df"><b>Artwork approved by the owner on '+A['date']+'.</b> '+('Complete delivery: ready for Claude integration.' if not blocked else 'Partial delivery: '+str(A['frames'])+' reviewed images approved; '+str(A['frames_expected']-A['frames'])+' outputs still missing. Approval of these images remains valid.')+' <a href="APPROVAL.json">Approval record</a> / <a href="CLAUDE-'+D.name[:4]+'-PROMPT.txt">Claude handoff</a></aside>'
 page=page.replace('</h1>','</h1>'+banner,1)
 if blocked:
  candidate=json.loads(out['candidate-contract.json']);candidate['owner_approval']=contract['owner_approval'];candidate['delivery_type']='owner-approved reviewed artwork; partial delivery';out['candidate-contract.json']=j(candidate)
  contract['delivery_type']='approved artwork; blocked only for missing outputs'
  page=page.replace('Blocked diagnostics only: no production export.','Owner-approved reviewed artwork; pack delivery remains incomplete.')
 else:
  contract['status']='approved for integration'
  assert set(A['approved_sha256'])=={f['output'] for f in files}, 'Approval file set changed'
  for f in files:assert sha(out[f['output']])==A['approved_sha256'][f['output']], 'Approved art changed: '+f['output']
  checks['approved_art_hashes_match']=True
'''


def patch_generic(d, complete):
    p = d / "build.py"
    s = p.read_text(encoding="utf-8")
    if "# Owner approval changes delivery metadata only" in s:
        return
    old = "P=json.loads((D/'raw/export-plan.json').read_text(encoding='utf-8'));blocked=P.get('status')=='blocked';"
    assert old in s, d
    s = s.replace(old, "P=json.loads((D/'raw/export-plan.json').read_text(encoding='utf-8'))\nA=json.loads((D/'APPROVAL.json').read_text(encoding='utf-8')) if (D/'APPROVAL.json').exists() else {}\nif A.get('scope')=='complete_reviewed_delivery':P['status']='approved for integration'\nblocked=P.get('status')=='blocked'", 1)
    marker = "out['contract.json']=j(contract);out['checks.json']=j(checks);out['index.html']=page.encode()"
    assert marker in s, d
    s = s.replace(marker, GENERIC_APPROVAL_HOOK + "\n" + marker, 1)
    assert "if failed:raise SystemExit(2)" in s, d
    s = s.replace("if failed:raise SystemExit(2)", "unaccepted=[k for k in failed if k not in A.get('accepted_visual_checks',[])]\nif unaccepted:raise SystemExit(2)", 1)
    p.write_text(s, encoding="utf-8")
    if complete:
        plan = read(d / "raw/export-plan.json")
        plan["status"] = "approved for integration"
        normalize_files(plan["files"], True)
        write(d / "raw/export-plan.json", plan)


CUSTOM_CHECK = '''
if '--check' in sys.argv:
    contract=json.loads((D/'contract.json').read_text(encoding='utf-8'))
    approval=json.loads((D/'APPROVAL.json').read_text(encoding='utf-8'))
    assert contract['status']=='approved for integration'
    assert set(approval['approved_sha256'])=={f['output'] for f in contract['files']}
    for f in contract['files']:
        path=D/f['output']
        assert hashlib.sha256(path.read_bytes()).hexdigest()==approval['approved_sha256'][f['output']]
        assert render_source(f['recipe']).tobytes()==Image.open(path).convert('RGBA').tobytes(), f['output']
        assert hashlib.sha256((D/f['source']).read_bytes()).hexdigest()==f['source_sha256']
        assert hashlib.sha256((D/f['prompt']).read_bytes()).hexdigest()==f['prompt_sha256']
    print(D.name+' approval, hashes and in-memory source recipes: PASS')
    raise SystemExit(0)
'''

CUSTOM_FINISH = '''
# Preserve exact reviewed pixels while exposing the approved integration contract.
if (D/'APPROVAL.json').exists():
    a=json.loads((D/'APPROVAL.json').read_text(encoding='utf-8'))
    c=json.loads((D/'contract.json').read_text(encoding='utf-8'))
    c['status']='approved for integration'
    c['owner_approval']={'date':a['date'],'owner_words':a['owner_words'],'scope':a['scope']}
    c.setdefault('deviations',[]).append({'rule':'Reviewed visual constraints','change':'The owner approved the displayed artwork, including the documented visual QA differences.','owner_words':a['owner_words'],'accepted_checks':a.get('accepted_visual_checks',[])})
    c.setdefault('palette_keys',None);c.setdefault('colour_ramp',[]);c.setdefault('mirror_pairs',{});c.setdefault('supersedes',[])
    refs={}
    for f in c['files']:
        receipt=json.loads((D/f['call']).read_text(encoding='utf-8'))
        for ref in receipt.get('input_images',[]):
            ref_path=Path(ref.get('archived_path',ref['path']))
            assert hashlib.sha256(ref_path.read_bytes()).hexdigest()==ref['sha256'], str(ref_path)
            refs[str(ref_path)]=ref
    c['references']=[refs[k] for k in sorted(refs)]
    c['animations']=[]
    for f in c['files']:
        name=f['name'];f['anim']=name;f['dir']='none';f['frame']=0;f['seconds']=f.get('seconds',1.0);f['loop']=False;f['mirror']='none';f['points']={}
        f['runtime_name']=f.get('runtime_name','sprites/ui/'+name+'.png')
        f['canvas_wh']=f.get('canvas_wh',f['recipe']['canvas_wh']);f['pivot_xy']=f.get('pivot_xy',f['recipe']['pivot_xy']);f['draw_scale']=1
        f['source_sha256']=hashlib.sha256((D/f['source']).read_bytes()).hexdigest()
        f['prompt']=f.get('prompt',f['call'].removesuffix('.call.json')+'.prompt.txt')
        f['prompt_sha256']=hashlib.sha256((D/f['prompt']).read_bytes()).hexdigest()
        c['animations'].append({'anim':name,'dir':'none','frames':1,'poses':[name],'frame_seconds':f['seconds'],'loop':False,'canvas_wh':f['canvas_wh'],'pivot_xy':f['pivot_xy'],'draw_scale':1,'mirror':'none','points':{}})
    assert set(a['approved_sha256'])=={f['output'] for f in c['files']}
    for f in c['files']:assert hashlib.sha256((D/f['output']).read_bytes()).hexdigest()==a['approved_sha256'][f['output']], f['output']
    (D/'contract.json').write_text(json.dumps(c,indent=2,ensure_ascii=False)+'\\n',encoding='utf-8')
    q=json.loads((D/'checks.json').read_text(encoding='utf-8'));q['owner_visual_approval_recorded']=True;q['owner_accepted_visual_checks']=a.get('accepted_visual_checks',[]);q['approved_art_hashes_match']=True
    (D/'checks.json').write_text(json.dumps(q,indent=2,ensure_ascii=False)+'\\n',encoding='utf-8')
    page=(D/'index.html').read_text(encoding='utf-8')
    page=page.replace(' / review</h1>',' / approved for integration</h1>').replace(' / blocked</h1>',' / approved for integration</h1>')
    page=page.replace('Candidate only; no runtime integration or approval.','Owner-approved artwork; integration pending.')
    page=page.replace('Candidate review only. Nothing here is approved or integrated.','Owner-approved artwork; integration pending.')
    banner='<aside style="padding:16px;background:#244533;color:#eef5df"><b>Artwork approved on '+a['date']+'. Complete delivery ready for Claude integration.</b> <a href="APPROVAL.json">Approval record</a> / <a href="CLAUDE-'+D.name[:4]+'-PROMPT.txt">Claude handoff</a></aside>'
    page=page.replace('</h1>','</h1>'+banner,1)
    (D/'index.html').write_text(page,encoding='utf-8')
'''


def patch_custom(d):
    p = d / "build.py"
    s = p.read_text(encoding="utf-8")
    if "# Preserve exact reviewed pixels" in s:
        return
    assert "from palette import COLOURS" in s
    s = s.replace("from palette import COLOURS", "from palette import COLOURS\n" + CUSTOM_CHECK, 1)
    if d.name.startswith("A056"):
        s = s.replace("status='blocked' if failed else 'review'", "status='approved for integration' if (D/'APPROVAL.json').exists() else ('blocked' if failed else 'review')", 1)
    s += "\n" + CUSTOM_FINISH
    p.write_text(s, encoding="utf-8")


def handoff(d, approval, files, pack_text):
    tasks = re.search(r"For game tasks?:\*\* ([^\n]+)", pack_text)
    lines = [
        f"{d.name}: owner-approved artwork", "",
        f"Approval date: {DATE}", f"Owner words (verbatim): {OWNER_WORDS}",
        f"Authoritative delivery: {d.relative_to(ROOT).as_posix()}",
        f"Game integration task: {tasks.group(1) if tasks else 'See the pack specification.'}",
        "",
        "Scope: " + ("Complete reviewed delivery approved for integration." if approval["scope"] == "complete_reviewed_delivery" else "The exact displayed files are approved. The full pack still lacks outputs; keep its integration task gated until the missing outputs are supplied. Do not regenerate the approved files."),
        "Review-log.txt and APPROVAL.json preserve the owner acceptance of documented visual differences. Measured QA booleans remain unchanged; accepted visual checks are listed separately.",
        "No older delivery is superseded. The batch review HTML is an index, not an art source.",
        "Mode A: use the original raw ImageGen sources and the exact per-file crop, scale, pivot, alpha threshold and palette_keys in the contract; tools/palette.py:COLOURS is the palette. Preserve exact approved PNG hashes.",
        "01.png is frame 0. All per-file timing, canvas, pivot, points, aliases and mirror behavior are included below. A runtime mirror means east is obtained by flipping west in the game. Bind baked mirrors directly and do not flip them again.",
        "Use contract.json for complete deliveries. For partial deliveries, use candidate-contract.json only to locate the explicitly approved hashes in APPROVAL.json; it does not claim the missing frames exist.",
        "Never use raw rejected cells, screenshots, GIFs, or unlisted PNGs. Never regenerate, repaint, recolor, resample or retime these approved images.",
        "", "Exact mappings:",
    ]
    for f in files:
        lines.append(f"{f['output']} -> {f['runtime_name']} | {f['canvas_wh']} pivot {f['pivot_xy']} draw {f['draw_scale']} | frame {f['frame']} | {f['seconds']} seconds | loop {f['loop']} | mirror {f['mirror']} | points {json.dumps(f.get('points', {}), sort_keys=True)}")
    if approval.get("missing_outputs"):
        lines += ["", "Missing outputs (not approved; retain placeholders for them):", *approval["missing_outputs"]]
    lines += ["", "Integration procedure for complete deliveries:",
              "1. Verify APPROVAL.json and contract.json SHA-256 values before promotion.",
              "2. Promote versioned raw sources through assets/art_source/<family>/, the raster manifest, ownership.json and tools/import_art.py, with prompt/reference/approval provenance. Metadata points are native coordinates.",
              "3. Extend the relevant hard-coded family validation lists. Any changes to code, aliases and manifest bindings belong to the named game task.",
              "4. Run python tools/verify.py and inspect day/night FHD captures.",
              f"5. Only after integration succeeds, run python implementation/backlog/assets.py set {d.name[:4]} integrated.",
              "6. Claude owns assets.py unblock and game-task state changes. Codex did not run them.", ""]
    (d / f"CLAUDE-{d.name[:4]}-PROMPT.txt").write_text("\n".join(lines), encoding="utf-8")


def main():
    summary = []
    for pack in IDS:
        d = next(DELIVERIES.glob(pack + "-*"))
        base = capture_baseline(d, pack)
        files = json.loads(json.dumps(base["files"]))
        expected = base["expected"]
        complete = pack in COMPLETE
        assert not complete or len(files) == expected, (pack, len(files), expected)
        pack_file = next((ROOT / "implementation/backlog/packs").glob(pack + "-*.md"))
        pack_text = pack_file.read_text(encoding="utf-8")
        title = base["contract"].get("title", d.name)
        if not files:
            summary.append({"id": pack, "folder": d.name, "title": title, "art_approval": "No images in the reviewed page", "ready": False, "available": 0, "expected": expected, "status": "blocked", "missing": expected})
            continue
        normalize_files(files, complete)
        accepted = [k for k, v in base["checks"].items() if v is False and k not in STRUCTURAL]
        # Structural constraints are never silently waived by approval of displayed art.
        core = {"binary_alpha", "no_empty_frame", "canvas_and_pivot_consistent", "colours_allowed", "importer_recipe_matches", "rebuild_identical", "raw_provenance_matches", "reference_hashes_match", "prompts_match_calls", "palette_allowed", "alpha_binary", "source_receipts_complete"}
        assert not (set(accepted) & core), (pack, "Structural check failed", set(accepted) & core)
        missing = []
        spec_path = d / "raw/delivery-spec.json"
        if not complete and spec_path.exists():
            delivered = {f.get("runtime_name") for f in files}
            missing = [f.get("runtime_name", f.get("output")) for f in read(spec_path).get("files", []) if f.get("runtime_name") not in delivered]
        if pack == "A028":
            missing = [f"sprites/props/{anim}_{n}.png" for anim, count in {"dog_wag": 2, "dog_walk": 4, "dog_bark": 3, "dog_sleep": 2, "dog_run": 4, "dog_bite": 3}.items() for n in range(count)]
        if pack == "A054":
            missing = [f"sprites/enemies/winter_lord_{anim}_{n}.png" for anim in ["walk", "cast"] for n in range(4)]
        approval = {
            "pack": pack, "date": DATE,
            "status": "approved for integration" if complete else "reviewed images approved; full delivery incomplete",
            "scope": "complete_reviewed_delivery" if complete else "available_reviewed_files_only",
            "owner_words": OWNER_WORDS, "prior_owner_words": PRIOR_WORDS,
            "approved_folder": d.relative_to(ROOT).as_posix(),
            "review_page": "implementation/backlog/deliveries/A028-dog/all-packs-review.html",
            "approved_sha256": {f["output"]: f["sha256"] for f in files},
            "frames": len(files), "frames_expected": expected,
            "accepted_visual_checks": accepted, "missing_outputs": missing,
            "runtime_integrated": False,
        }
        write(d / "APPROVAL.json", approval)
        marker = "2026-10-14 / Batch approval reconciliation"
        log = d / "review-log.txt"
        old = log.read_text(encoding="utf-8") if log.exists() else ""
        if marker not in old:
            log.write_text(old + f"\n{marker}\nOwner words: {OWNER_WORDS}\nPrior owner words: {PRIOR_WORDS}\n{len(files)}/{expected} reviewed outputs approved. All approved pixels, crops, palette choices and timing preserved. Accepted visual differences remain measured in checks.json: {', '.join(accepted) or 'none'}. " + ("Complete delivery released for Claude integration.\n" if complete else "Approval applies only to displayed images. Missing outputs remain a delivery blocker, not a rejection of approved art.\n"), encoding="utf-8")
        if pack in {"A055", "A056"}:
            patch_custom(d)
        else:
            patch_generic(d, complete)
        handoff(d, approval, files, pack_text)
        # Two identical builds and an independent source/hash check; no new art generation.
        artifact_hashes = None
        for mode in [[], [], ["--check"]]:
            result = subprocess.run([sys.executable, "-X", "utf8", str(d / "build.py"), *mode], cwd=ROOT, capture_output=True, text=True, encoding="utf-8")
            allowed_codes = {0} if complete else {0, 2}
            if result.returncode not in allowed_codes:
                raise RuntimeError(pack + " build failed: " + result.stdout + result.stderr)
            if mode:
                print(pack, "source/hash check passed" if complete else "partial delivery checked; missing outputs retained", flush=True)
            else:
                artifacts = [p for p in d.rglob("*.png") if "raw" not in p.relative_to(d).parts and "rejected" not in p.relative_to(d).parts]
                artifacts += [d / "index.html", d / "checks.json", d / "contract.json"]
                now = {p.relative_to(d).as_posix(): digest(p) for p in artifacts}
                if artifact_hashes is not None:
                    assert now == artifact_hashes, (pack, "second build changed")
                artifact_hashes = now
        current = read(d / "contract.json")
        if complete:
            assert current["status"] == "approved for integration"
            assert {f["output"]: digest(d / f["output"]) for f in current["files"]} == approval["approved_sha256"]
            handoff(d, approval, current["files"], pack_text)
            result = subprocess.run([sys.executable, "implementation/backlog/assets.py", "set", pack, "approved"], cwd=ROOT, capture_output=True, text=True)
            assert result.returncode == 0, result.stderr
            print(result.stdout.strip(), flush=True)
        else:
            note = f"Owner approved {len(files)} reviewed images; {expected-len(files)} outputs still missing"
            result = subprocess.run([sys.executable, "implementation/backlog/assets.py", "set", pack, "blocked", note], cwd=ROOT, capture_output=True, text=True)
            assert result.returncode == 0, result.stderr
        summary.append({"id": pack, "folder": d.name, "title": title, "art_approval": "Approved", "ready": complete, "available": len(files), "expected": expected, "status": "approved" if complete else "blocked: missing outputs", "missing": expected-len(files), "accepted_visual_checks": accepted})
    write(HERE / "batch-approval.json", {"date": DATE, "owner_words": OWNER_WORDS, "packages": summary, "complete_deliveries": sum(s["ready"] for s in summary), "approved_partial_deliveries": sum(s["available"] > 0 and not s["ready"] for s in summary), "empty_deliveries": sum(s["available"] == 0 for s in summary)})
    update_page(summary)


def update_page(summary):
    rows = []
    embeds = []
    for s in summary:
        folder = s["folder"]
        state = "Ready for Claude integration" if s["ready"] else (f"Delivery incomplete: {s['missing']} outputs missing" if s["available"] else "No reviewed images delivered")
        links = f'<a href="../{folder}/index.html">View</a>'
        if s["available"]:
            links += f' / <a href="../{folder}/APPROVAL.json">Approval</a> / <a href="../{folder}/CLAUDE-{s["id"]}-PROMPT.txt">Claude handoff</a>'
        rows.append(f'<tr><td>{s["id"]}</td><td>{html.escape(s["title"])}</td><td class="approved">{s["art_approval"]}</td><td>{s["available"]}/{s["expected"]}</td><td>{state}</td><td>{links}</td></tr>')
        embeds.append(f'<details><summary>{s["id"]} / {html.escape(s["title"])} / {s["art_approval"]} / {state}</summary><iframe loading="lazy" src="../{folder}/index.html" title="{s["id"]}"></iframe></details>')
    page = '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Approved artwork / 21-pack batch</title><style>body{background:#192326;color:#eee4d3;font:16px system-ui;margin:24px;line-height:1.45}a{color:#89d1cd}table{border-collapse:collapse;width:100%;margin:20px 0}th,td{border:1px solid #526064;padding:9px;text-align:left;vertical-align:top}th{background:#28383d}.approved{color:#b7e7b8}details{border:1px solid #526064;padding:12px;margin:16px 0}summary{cursor:pointer;font-weight:650}iframe{width:100%;height:75vh;border:1px solid #526064;background:#1b292c}.note{padding:16px;background:#244533}</style><h1>Approved artwork / 21-pack batch</h1><p class="note">The owner approved every image shown in this review. Approval is recorded per delivery with exact PNG hashes. 15 complete packs are ready for Claude; 4 partial packs retain approval of the displayed images and still need missing outputs. A043 and A045 had no images in the reviewed page. No reviewed sprite pixels were changed.</p><p><a href="batch-approval.json">Batch approval manifest</a>. Visual approval and delivery completeness are shown separately below. Measured visual QA differences remain in each checks.json as owner-accepted differences, not fresh rejections.</p><table><thead><tr><th>Pack</th><th>Title</th><th>Artwork approval</th><th>Delivered / expected</th><th>Integration readiness</th><th>Files</th></tr></thead><tbody>' + ''.join(rows) + '</tbody></table><h2>Delivery pages</h2>' + ''.join(embeds) + '</html>\n'
    (HERE / "all-packs-review.html").write_text(page, encoding="utf-8")


if __name__ == "__main__":
    main()
