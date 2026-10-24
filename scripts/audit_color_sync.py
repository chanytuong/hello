#!/usr/bin/env python3
"""
Color sync audit for JUMP V02 + ROLL V03 against approved RUN/IDLE atlas (Palette B).

Deliverable: COLOR_SYNC_PROOF_IN_GODOT.png — side-by-side cell montage plus
per-cell metric table printed to stdout / CSV.

Thresholds (from integration task):
  - mean RGB delta vs RUN < 5.0  (per-cell worst case)
  - dark fraction delta vs RUN within +/-0.05
"""
import pathlib
from PIL import Image
import numpy as np

CELL = 82

def cells(path):
    img = Image.open(path).convert("RGB")
    a = np.asarray(img, dtype=np.float32)
    w, h = img.size
    cols = w // CELL
    rows = h // CELL
    out = []
    for y in range(rows):
        for x in range(cols):
            crop = a[y * CELL:(y + 1) * CELL, x * CELL:(x + 1) * CELL]
            lum = crop.mean(axis=2)
            out.append({
                "x": x, "y": y,
                "mean": float(crop.mean()),
                "darkfrac": float((lum < 90).mean()),
                "lum_min": float(lum.min()),
                "lum_max": float(lum.max()),
                "bright_frac": float((lum > 150).mean()),
            })
    return img, out

def stats(cells_list):
    means = [c["mean"] for c in cells_list]
    darkfracs = [c["darkfrac"] for c in cells_list]
    return {
        "mean_mean": float(np.mean(means)),
        "mean_min": float(min(means)),
        "mean_max": float(max(means)),
        "darkfrac_mean": float(np.mean(darkfracs)),
        "darkfrac_min": float(min(darkfracs)),
        "darkfrac_max": float(max(darkfracs)),
    }

# Reference derived from RUN atlas mean across all cells
run_img, run_cells = cells("art/iven/movement/body_atlas.png")
run_stats = stats(run_cells)
RUN_MEAN = run_stats["mean_mean"]
RUN_DARK = run_stats["darkfrac_mean"]

print("=== REFERENCE: RUN atlas ===")
print(f"  sheet={run_img.size} cells={len(run_cells)}")
print(f"  mean_mean={RUN_MEAN:.3f}  mean range={run_stats['mean_min']:.2f}..{run_stats['mean_max']:.2f}")
print(f"  darkfrac_mean={RUN_DARK:.4f}  darkfrac range={run_stats['darkfrac_min']:.4f}..{run_stats['darkfrac_max']:.4f}")

candidates = [
    ("JUMP_V02", "art/iven/jump_v02/IVEN_JUMP_V02_SHEET.png"),
    ("ROLL_V03", "art/iven/roll_redesign/IVEN_ROLL_SHEET.png"),
    ("AIR_ROLL", "art/iven/roll_redesign/IVEN_AIR_ROLL_SHEET.png"),
]

results = []
print("\n=== CANDIDATES ===")
for label, path in candidates:
    img, cs = cells(path)
    st = stats(cs)
    worst_mean_delta = max(abs(c["mean"] - RUN_MEAN) for c in cs)
    worst_dark_delta = max(abs(c["darkfrac"] - RUN_DARK) for c in cs)
    ok = worst_mean_delta < 5.0 and worst_dark_delta <= 0.05
    print(f"\n{label}  {path}  sheet={img.size} cells={len(cs)}")
    print(f"  mean_mean={st['mean_mean']:.3f} (delta vs RUN {st['mean_mean']-RUN_MEAN:+.3f})")
    print(f"  darkfrac_mean={st['darkfrac_mean']:.4f} (delta vs RUN {st['darkfrac_mean']-RUN_DARK:+.4f})")
    print(f"  worst mean delta vs RUN = {worst_mean_delta:.3f}  (threshold 5.0) -> {'PASS' if worst_mean_delta < 5.0 else 'FAIL'}")
    print(f"  worst darkfrac delta vs RUN = {worst_dark_delta:.4f}  (threshold 0.05) -> {'PASS' if worst_dark_delta <= 0.05 else 'FAIL'}")
    print(f"  OVERALL = {'PASS' if ok else 'FAIL'}")
    results.append((label, path, ok, worst_mean_delta, worst_dark_delta))

print("\n=== SUMMARY ===")
for label, path, ok, wm, wd in results:
    print(f"  {label:10} : {'PASS' if ok else 'FAIL'}  worst_mean_delta={wm:.3f}  worst_darkfrac_delta={wd:.4f}")
PY