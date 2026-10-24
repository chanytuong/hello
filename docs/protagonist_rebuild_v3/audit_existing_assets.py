"""Phase B read-only asset measurement and screenshot QA composite.

Pillow is used only to inspect existing PNGs and crop captured runtime images.
This script neither draws production art nor writes to any asset directory.
"""
from pathlib import Path
from collections import Counter
import hashlib
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
records = []
frame_names = ["neutral.png"] + [f"run_{i:02}.png" for i in range(6)]
frame_names += ["d0_entry.png", "d1_hold.png", "d2_exit.png"]
frame_names += [f"attack_a{i}.png" for i in range(5)]
for folder in ("character", "character_a2"):
    for name in frame_names:
        path = ROOT / "art" / "prototype" / folder / name
        with Image.open(path) as source:
            rgba = source.convert("RGBA")
            alpha = rgba.getchannel("A")
            visible = Counter(px for px in rgba.getdata() if px[3])
            box = alpha.getbbox()
            records.append({
                "path": path.relative_to(ROOT).as_posix(),
                "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                "mode": source.mode,
                "size": list(source.size),
                "alpha_values": sorted(set(alpha.getdata())),
                "alpha_bbox_exclusive": list(box) if box else None,
                "visible_color_count": len(visible),
                "visible_pixel_count": sum(visible.values()),
                "colors": [{"rgba": list(color), "pixels": count}
                           for color, count in visible.most_common()],
            })
(OUT / "existing_asset_audit.json").write_text(
    json.dumps(records, indent=2), encoding="utf-8")

# Screenshot crops only. Order matches observations.json (left to right, top down).
observations = json.loads((OUT / "baseline_runtime" / "observations.json").read_text())
sheet = Image.new("RGB", (1536, 768))
for index, record in enumerate(observations):
    x, y = record["player_position"]
    with Image.open(OUT / "baseline_runtime" / (record["label"] + ".png")) as capture:
        crop = capture.crop((round(x)-48, round(y)-80, round(x)+48, round(y)+16))
        crop = crop.resize((384, 384), Image.Resampling.NEAREST)
        sheet.paste(crop, ((index % 4)*384, (index // 4)*384))
sheet.save(OUT / "baseline_runtime" / "qa_capture_crops_4x.png")
print(json.dumps({"measured_runtime_assets": len(records),
                  "qa_capture_crops": len(observations),
                  "all_64x64": all(r["size"] == [64, 64] for r in records),
                  "all_binary_alpha": all(r["alpha_values"] == [0, 255] for r in records),
                  "A2_neutral": records[15],
                  "A2_color_count_range": [min(r["visible_color_count"] for r in records[15:]),
                                           max(r["visible_color_count"] for r in records[15:])]}))
