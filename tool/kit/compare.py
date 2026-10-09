#!/usr/bin/env python3
"""Side-by-side kit review: design reference vs Flutter implementation, one row per component state ID.

Usage:
  python3 tool/kit/compare.py --kit <the-forge-design>/kits/<name>/<version> \
      --flutter lib/modules/sli_common/test/goldens/kit [--out build/kit-compare]

Machine checks (cheap, no image libraries): every spec ID has a reference and a Flutter image, and the
aspect ratio matches within tolerance. Colour/spacing/icon correctness is judged by the human in the
generated page; the page records the decision per ID in localStorage and can export it as JSON.
"""
import argparse, html, json, os, shutil, struct, sys
from pathlib import Path

def png_size(path):
    with open(path, 'rb') as f:
        head = f.read(24)
    if head[:8] != b'\x89PNG\r\n\x1a\n': raise ValueError(f'not a PNG: {path}')
    return struct.unpack('>II', head[16:24])

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--kit', required=True); ap.add_argument('--flutter', required=True)
    ap.add_argument('--out', default='build/kit-compare'); ap.add_argument('--ratio-tolerance', type=float, default=0.08)
    a = ap.parse_args()
    kit, flutter, out = Path(a.kit), Path(a.flutter), Path(a.out)
    meta = json.loads((kit / 'kit.json').read_text()); spec = json.loads((kit / 'kit/components.json').read_text())
    ids = [f"{c['id']}.{v}.{s}" for c in spec['components'] for v in c['variants'] for s in c['states']]
    (out / 'ref').mkdir(parents=True, exist_ok=True); (out / 'impl').mkdir(parents=True, exist_ok=True)
    rows, problems = [], 0
    for cid in ids:
        ref, impl = kit / 'reference' / f'{cid}.png', flutter / f'{cid}.png'
        notes = []
        if not ref.is_file(): notes.append('thiếu ảnh thiết kế')
        if not impl.is_file(): notes.append('thiếu ảnh Flutter')
        if not notes:
            (rw, rh), (iw, ih) = png_size(ref), png_size(impl)
            if abs(rw / rh - iw / ih) / (rw / rh) > a.ratio_tolerance: notes.append(f'tỉ lệ lệch: thiết kế {rw}×{rh}, Flutter {iw}×{ih}')
            shutil.copyfile(ref, out / 'ref' / ref.name); shutil.copyfile(impl, out / 'impl' / impl.name)
        problems += bool(notes)
        rows.append((cid, notes))
    extra = sorted(p.stem for p in flutter.glob('*.png') if p.stem not in ids)
    title = f"{meta['name']}@{meta['version']}"
    cells = '\n'.join(f'''<tr data-id="{html.escape(i)}" class="{'warn' if n else ''}"><td><code>{html.escape(i)}</code><div class="note">{html.escape('; '.join(n) or 'máy: khớp kích thước')}</div></td>
<td>{'' if 'thiếu ảnh thiết kế' in n else f'<img src="ref/{html.escape(i)}.png">'}</td><td>{'' if 'thiếu ảnh Flutter' in n else f'<img src="impl/{html.escape(i)}.png">'}</td>
<td><label><input type="radio" name="{html.escape(i)}" value="ok"> Đạt</label><br><label><input type="radio" name="{html.escape(i)}" value="fix"> Sửa</label><br><input class="why" placeholder="Lý do nếu sửa"></td></tr>''' for i, n in rows)
    page = f'''<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Đối chiếu {html.escape(title)}</title>
<style>body{{font:14px system-ui;margin:16px;background:#fff;color:#111}}table{{border-collapse:collapse;width:100%}}td,th{{border:1px solid #ddd;padding:8px;vertical-align:top}}img{{max-width:260px;background:repeating-conic-gradient(#eee 0 25%,#fff 0 50%) 0/16px 16px}}tr.warn{{background:#fff4e5}}.note{{color:#555;font-size:12px;margin-top:4px}}.why{{width:100%;margin-top:4px}}header{{display:flex;gap:16px;align-items:center;flex-wrap:wrap}}</style></head><body>
<header><h1>Đối chiếu kit {html.escape(title)}</h1><span>{len(ids)} trạng thái · {problems} cần chú ý · thừa {len(extra)}</span><button id="export">Xuất kết quả duyệt (JSON)</button></header>
<p>Trái: thiết kế (catalog HTML). Phải: Flutter. Máy chỉ kiểm có đủ ảnh và tỉ lệ khung; màu, icon, chữ, khoảng cách do bạn duyệt. Kit chỉ chuyển "approved" khi mọi dòng là Đạt.</p>
{'<p><b>Ảnh Flutter không có trong spec:</b> ' + ', '.join(map(html.escape, extra)) + '</p>' if extra else ''}
<table><tr><th>ID</th><th>Thiết kế</th><th>Flutter</th><th>Duyệt</th></tr>{cells}</table>
<script>
const KEY='kit-review:{html.escape(title)}';let saved={{}};try{{saved=JSON.parse(localStorage.getItem(KEY)||'{{}}')}}catch(e){{}}
document.querySelectorAll('tr[data-id]').forEach(tr=>{{const id=tr.dataset.id,s=saved[id]||{{}};tr.querySelectorAll('input[type=radio]').forEach(r=>{{r.checked=r.value===s.decision;r.onchange=()=>{{saved[id]={{...saved[id],decision:r.value}};store()}}}});const w=tr.querySelector('.why');w.value=s.reason||'';w.oninput=()=>{{saved[id]={{...saved[id],reason:w.value}};store()}}}});
function store(){{try{{localStorage.setItem(KEY,JSON.stringify(saved))}}catch(e){{}}}}
document.getElementById('export').onclick=()=>{{const blob=new Blob([JSON.stringify({{kit:'{html.escape(title)}',reviewed:new Date().toISOString(),decisions:saved}},null,2)],{{type:'application/json'}});const a=document.createElement('a');a.href=URL.createObjectURL(blob);a.download='kit-review.json';a.click()}};
</script></body></html>'''
    (out / 'index.html').write_text(page, encoding='utf-8')
    print(json.dumps({'kit': title, 'states': len(ids), 'needsAttention': problems, 'extraFlutterImages': extra, 'page': str(out / 'index.html')}, ensure_ascii=False))
    return 1 if problems else 0

if __name__ == '__main__': sys.exit(main())
