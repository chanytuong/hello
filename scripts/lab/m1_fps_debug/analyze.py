import json, statistics, sys, os

path = sys.argv[1] if len(sys.argv) > 1 else r"E:\neverlookback\scripts\lab\m1_fps_debug\bench_before.json"
d = json.load(open(path))
rows = d["rows"]

print("mode", d["mode"], "tag", d["tag"], "godot", d["godot"])
print("renderer", d["renderer"])
print("hits", d["hits"], "strikes", d["strikes"], "combo_starts", d["combo_starts"])
print()

phases = ["WARMUP", "IDLE", "RUN", "M1", "DONE"]
for ph in phases:
    v = [r["dt_ms"] for r in rows if r["phase"] == ph]
    if not v:
        continue
    v2 = sorted(v)
    n = len(v2)
    def pct(p):
        return v2[min(n - 1, int(p * n))]
    avg = statistics.mean(v2)
    print(f"{ph:6s} n={n:4d} avg={avg:7.2f}ms ({1000/avg:6.1f} fps) "
          f"med={statistics.median(v2):7.2f} p95={pct(.95):7.2f} p99={pct(.99):7.2f} "
          f"max={v2[-1]:8.2f} min_fps={1000/v2[-1]:5.1f}")
print()

print("Top 15 frame-time spikes:")
for r in sorted(rows, key=lambda r: -r["dt_ms"])[:15]:
    print(f"  t={r['t']:7.3f} {r['phase']:6s} dt={r['dt_ms']:8.2f}ms "
          f"proc={r['proc_ms']:6.2f} phys={r['phys_ms']:6.2f} draws={r['draws']:4d} "
          f"canvas={r['canvas_items']:4d} nodes={r['nodes']:4d} tris={r['ribbon_tris']:4d} "
          f"combo={r['combo_index']} age={r['combo_age']:.3f}")
print()

# Correlation of dt with ribbon triangles during M1
m1 = [r for r in rows if r["phase"] == "M1"]
if len(m1) > 10:
    def corr(a, b):
        n = len(a)
        ma, mb = sum(a)/n, sum(b)/n
        cov = sum((x-ma)*(y-mb) for x, y in zip(a, b))
        va = sum((x-ma)**2 for x in a) ** .5
        vb = sum((y-mb)**2 for y in b) ** .5
        return cov/(va*vb) if va*vb else 0
    print("M1 correlations (Pearson):")
    for key in ["ribbon_tris", "draws", "canvas_items", "nodes", "proc_ms", "phys_ms", "prims"]:
        print(f"  dt_ms vs {key:14s} = {corr([r['dt_ms'] for r in m1], [float(r[key]) for r in m1]):+.3f}")
    print()
    # bucket by tris
    buckets = {}
    for r in m1:
        t = r["ribbon_tris"]
        b = "0" if t == 0 else ("1-60" if t <= 60 else ("61-120" if t <= 120 else ("121-200" if t <= 200 else "200+")))
        buckets.setdefault(b, []).append(r["dt_ms"])
    print("M1 frame time by ribbon triangle bucket:")
    for b in ["0", "1-60", "61-120", "121-200", "200+"]:
        if b in buckets:
            v = buckets[b]
            print(f"  tris {b:8s} n={len(v):4d} avg={statistics.mean(v):7.2f}ms max={max(v):8.2f}")
print()

print("Combo events:")
for e in d.get("combo_events", []):
    print(" ", e)
