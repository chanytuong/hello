"""Phase C inspection only: preserve source pixels in crops and nearest enlargements.

No production drawing, sprite extraction, palette conversion, or animation timing.
All generated PNGs are documentary views under docs/, never game assets.
"""
from pathlib import Path
from collections import Counter
import hashlib
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
VIEWS = OUT / "reference_inspection"
VIEWS.mkdir(exist_ok=True)
candidates = sorted((ROOT / "refs").glob("*.png"))
if len(candidates) != 1:
    raise RuntimeError(f"Select the verified reference explicitly: {candidates}")
source = candidates[0]
regions = [
    ("turnaround", (18, 18, 737, 365), 4, "static body/head views"),
    ("silhouette", (827, 85, 1012, 353), 6, "static faint silhouette studies"),
    ("head_idle", (1040, 18, 1518, 246), 10, "two rows of five head studies"),
    ("head_action", (1040, 254, 1518, 364), 4, "action deformation studies"),
    ("idle", (17, 374, 409, 525), 5, "visible body poses"),
    ("walk", (426, 374, 891, 525), 5, "visible body poses; trailing ellipsis"),
    ("run", (907, 374, 1520, 525), 6, "visible body poses; trailing ellipsis"),
    ("jump", (17, 532, 562, 666), 6, "visible body poses"),
    ("fall", (570, 532, 968, 666), 5, "visible body poses"),
    ("dash", (979, 532, 1519, 666), 4, "visible body/flame poses"),
    ("attack_quick", (17, 677, 496, 827), 6, "visible body poses"),
    ("attack_heavy", (509, 677, 1000, 827), 4, "visible body poses"),
    ("attack_up", (1010, 677, 1519, 827), 5, "visible body poses"),
    ("hurt", (17, 837, 345, 983), 4, "visible body poses"),
    ("death", (358, 837, 856, 983), 5, "four body poses plus one ember-only sample; ellipsis"),
    ("extra_effect", (879, 837, 1519, 993), 6, "distinct optional effect sketches, not a proven sequence"),
]

with Image.open(source) as original:
    rgba = original.convert("RGBA")
    alpha = Counter(rgba.getchannel("A").get_flattened_data())
    width, height = rgba.size
    metadata = {
        "exact_path": str(source),
        "filename": source.name,
        "bytes": source.stat().st_size,
        "sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
        "dimensions": [width, height],
        "mode": original.mode,
        "alpha_min": min(alpha), "alpha_max": max(alpha),
        "alpha_distinct_values": len(alpha),
        "alpha_zero_pixels": alpha[0], "alpha_255_pixels": alpha[255],
        "alpha_partial_pixels": sum(n for a, n in alpha.items() if 0 < a < 255),
        "alpha_histogram": {str(a): n for a, n in sorted(alpha.items())},
        "unique_rgb_colors_whole_board": len(set(rgba.convert("RGB").get_flattened_data())),
        "embedded_metadata_keys": list(original.info),
        "native_scale": "1536x1024 presentation-board raster only; original sprite pixel grid and exposure timing unknown",
        "crop_convention": "source coordinate boxes: left, top, right-exclusive, bottom-exclusive",
        "inspection_views": [],
    }
    for name, box, count, notes in regions:
        crop = rgba.crop(box)
        native = VIEWS / (name + "_1x.png")
        enlarged = VIEWS / (name + "_4x_nearest.png")
        crop.save(native)
        crop.resize((crop.width*4, crop.height*4), Image.Resampling.NEAREST).save(enlarged)
        metadata["inspection_views"].append({
            "group": name, "source_box": list(box),
            "visible_samples": count, "count_note": notes,
            "native": native.relative_to(OUT).as_posix(),
            "enlarged": enlarged.relative_to(OUT).as_posix(),
        })
    # Alpha is essential: a viewer displaying RGB alone can reveal a removed backdrop.
    rgba.getchannel("A").save(VIEWS / "alpha_1x.png")
    Image.alpha_composite(Image.new("RGBA", rgba.size, (13, 15, 23, 255)), rgba).convert("RGB").save(
        VIEWS / "composite_dark_1x.png")
    palette = rgba.crop((768, 81, 814, 347))
    palette.save(VIEWS / "palette_column_1x.png")
    palette.resize((palette.width*4, palette.height*4), Image.Resampling.NEAREST).save(
        VIEWS / "palette_column_4x_nearest.png")
    metadata["diagnostic_views"] = ["reference_inspection/alpha_1x.png",
                                    "reference_inspection/composite_dark_1x.png",
                                    "reference_inspection/palette_column_1x.png",
                                    "reference_inspection/palette_column_4x_nearest.png"]
    supplied = Path("C:/Users/Aloha/Downloads") / source.name
    if supplied.is_file():
        supplied_hash = hashlib.sha256(supplied.read_bytes()).hexdigest()
        metadata["supplied_download_path"] = str(supplied)
        metadata["supplied_download_sha256"] = supplied_hash
        metadata["matches_supplied_download"] = supplied_hash == metadata["sha256"]

(OUT / "reference_file_metadata.json").write_text(
    json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps({k: metadata[k] for k in (
    "exact_path", "dimensions", "mode", "sha256", "alpha_min", "alpha_max",
    "alpha_zero_pixels", "alpha_255_pixels", "alpha_partial_pixels",
    "alpha_distinct_values", "unique_rgb_colors_whole_board")}, ensure_ascii=True))
print("Documentary inspection regions:", len(regions))
