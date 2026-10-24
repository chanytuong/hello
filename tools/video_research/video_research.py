#!/usr/bin/env python
"""
video_research.py - small reusable video-research pipeline for OpenCode.

Purpose
-------
Turn a video (local file OR a permitted online URL) into evidence that a
vision-capable model can actually inspect:

  info      -> metadata (ffprobe): duration, size, fps, codecs, streams
  download  -> fetch a permitted online video with yt-dlp
  thumbs    -> extract individual frames (thumbnails / timestamp grabs)
  fps       -> extract N frames per second across the whole clip
  contact   -> build a labeled contact sheet from extracted frames (Pillow)
  run       -> one-shot: download(optional) -> info -> frames -> contact -> markdown

Everything a vision model needs is a PNG/JPG on disk, which the `read` tool can
hand to a vision-capable model.

Design rules
------------
- No large application: this file + ffmpeg/ffprobe + Pillow.
- ffmpeg/ffprobe are looked up in ../bin, then PATH.
- Never downloads more than asked. Never bypasses auth/DRM.
- Outputs stay inside this tool's own folders unless --out is given.

Examples
--------
  python video_research.py info  input/RUN_FINAL.mp4
  python video_research.py fps   input/RUN_FINAL.mp4 --fps 24 --out output/run_final
  python video_research.py thumbs input/RUN_FINAL.mp4 --times 0.0,0.25,0.5 --out output/picks
  python video_research.py contact output/run_final/frames --out output/run_final/CONTACT.png
  python video_research.py download "<permitted URL>" --out downloads
  python video_research.py run input/RUN_FINAL.mp4 --fps 24 --out output/run_final --title "NEVERLOOKBACK RUN_FINAL"

Requires: ffmpeg + ffprobe (bin/ or PATH), Pillow, and for download: yt-dlp.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
BIN = HERE / "bin"


def _tool(name: str) -> str:
    """Find ffmpeg/ffprobe in ./bin first, then PATH."""
    for candidate in (BIN / f"{name}.exe", BIN / name):
        if candidate.exists():
            return str(candidate)
    found = shutil.which(name)
    if found:
        return found
    raise FileNotFoundError(
        f"{name} not found in {BIN} or PATH. "
        f"Install it (see README) or place the binary in {BIN}."
    )


def _run(cmd: list[str]) -> str:
    proc = subprocess.run(cmd, capture_output=True, text=True, errors="replace")
    if proc.returncode != 0:
        raise RuntimeError(
            f"Command failed ({proc.returncode}): {' '.join(cmd)}\n{proc.stderr[-2000:]}"
        )
    return proc.stdout


# ---------------------------------------------------------------- info

def cmd_info(args: argparse.Namespace) -> int:
    ffprobe = _tool("ffprobe")
    out = _run([
        ffprobe, "-v", "error", "-print_format", "json",
        "-show_format", "-show_streams", str(args.source),
    ])
    data = json.loads(out)
    fmt = data.get("format", {})
    print(f"file      : {args.source}")
    print(f"duration  : {fmt.get('duration')} s")
    print(f"size      : {fmt.get('size')} bytes")
    print(f"bitrate   : {fmt.get('bit_rate')}")
    print(f"format    : {fmt.get('format_name')}")
    for s in data.get("streams", []):
        if s.get("codec_type") == "video":
            print(
                f"video     : {s.get('codec_name')} {s.get('width')}x{s.get('height')} "
                f"fps={s.get('r_frame_rate')} pix={s.get('pix_fmt')}"
            )
        elif s.get("codec_type") == "audio":
            print(f"audio     : {s.get('codec_name')} {s.get('sample_rate')}Hz ch={s.get('channels')}")
    if args.json:
        print("\n--- raw ---")
        print(json.dumps(data, indent=2)[:4000])
    return 0


# ------------------------------------------------------------ download

def cmd_download(args: argparse.Namespace) -> int:
    """Download a permitted video via yt-dlp (module form, no PATH needed)."""
    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    cmd = [
        sys.executable, "-m", "yt_dlp",
        "--no-playlist",
        "-f", args.format,
        "-o", str(out_dir / "%(title).120s [%(id)s].%(ext)s"),
        "--print", "after_move:filepath",
        args.url,
    ]
    if args.subs:
        cmd += ["--write-auto-subs", "--write-subs", "--sub-langs", args.subs]
    if args.cookies_from_browser:
        cmd += ["--cookies-from-browser", args.cookies_from_browser]
    print("running:", " ".join(cmd))
    proc = subprocess.run(cmd, text=True, errors="replace")
    return proc.returncode


# --------------------------------------------------------------- frames

def _extract(source: str, out_dir: Path, prefix: str, vf_args: list[str],
             start: str | None = None, duration: str | None = None) -> list[Path]:
    ffmpeg = _tool("ffmpeg")
    out_dir.mkdir(parents=True, exist_ok=True)
    pattern = str(out_dir / f"{prefix}_%03d.png")
    cmd = [ffmpeg, "-hide_banner", "-loglevel", "error", "-y"]
    if start:
        cmd += ["-ss", str(start)]
    cmd += ["-i", source]
    if duration:
        cmd += ["-t", str(duration)]
    cmd += vf_args
    cmd += ["-fps_mode", "vfr", pattern]
    _run(cmd)
    return sorted(out_dir.glob(f"{prefix}_*.png"))


def cmd_fps(args: argparse.Namespace) -> int:
    out_dir = Path(args.out) / "frames" if args.in_output else Path(args.out)
    vf = ["-vf", f"fps={args.fps},scale={args.scale}:-1:flags=neighbor"] if args.scale else \
         ["-vf", f"fps={args.fps}"]
    files = _extract(str(args.source), out_dir, "f", vf, args.start, args.duration)
    print(f"extracted {len(files)} frames at {args.fps} fps -> {out_dir}")
    for f in files[:5]:
        print("  ", f.name)
    if len(files) > 5:
        print("   ...")
    return 0


def cmd_thumbs(args: argparse.Namespace) -> int:
    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    ffmpeg = _tool("ffmpeg")
    times = [t.strip() for t in args.times.split(",") if t.strip()]
    made = []
    for i, t in enumerate(times):
        dest = out_dir / f"t{str(i).zfill(2)}_{t.replace('.', 'p').replace(':', 'm')}s.png"
        cmd = [ffmpeg, "-hide_banner", "-loglevel", "error", "-y",
               "-ss", t, "-i", str(args.source), "-frames:v", "1", str(dest)]
        _run(cmd)
        made.append(dest)
    print(f"wrote {len(made)} frames -> {out_dir}")
    for m in made:
        print("  ", m.name)
    return 0


# ---------------------------------------------------------- contact sheet

def cmd_contact(args: argparse.Namespace) -> int:
    from PIL import Image, ImageDraw

    frames_dir = Path(args.frames)
    files = sorted(
        p for p in frames_dir.iterdir()
        if p.suffix.lower() in (".png", ".jpg", ".jpeg", ".webp")
    )
    if not files:
        print(f"no images found in {frames_dir}", file=sys.stderr)
        return 1
    if args.limit:
        files = files[: args.limit]

    cell = args.cell
    cols = args.cols
    rows = (len(files) + cols - 1) // cols
    label_h = 16
    sheet = Image.new("RGB", (cols * cell, rows * (cell + label_h)), (24, 24, 28))
    draw = ImageDraw.Draw(sheet)

    for i, f in enumerate(files):
        try:
            im = Image.open(f).convert("RGB")
        except Exception as e:  # noqa: BLE001
            print(f"skip {f}: {e}", file=sys.stderr)
            continue
        im.thumbnail((cell, cell))
        x = (i % cols) * cell
        y = (i // cols) * (cell + label_h)
        # center in cell
        sheet.paste(im, (x + (cell - im.width) // 2, y + (cell - im.height) // 2))
        draw.text((x + 3, y + cell + 1), f.name, fill=(235, 235, 235))

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print(f"contact sheet: {out} ({sheet.width}x{sheet.height}, {len(files)} cells)")
    return 0


# --------------------------------------------------------------------- run

def cmd_run(args: argparse.Namespace) -> int:
    out = Path(args.out)
    frames_dir = out / "frames"
    vf = ["-vf", f"fps={args.fps}"]
    files = _extract(str(args.source), frames_dir, "f", vf)
    print(f"[run] {len(files)} frames -> {frames_dir}")

    # contact sheet
    contact = out / "CONTACT_SHEET.png"
    from PIL import Image, ImageDraw
    cell, cols = args.cell, args.cols
    rows = (len(files) + cols - 1) // cols
    label_h = 16
    sheet = Image.new("RGB", (cols * cell, rows * (cell + label_h)), (24, 24, 28))
    draw = ImageDraw.Draw(sheet)
    for i, f in enumerate(files):
        im = Image.open(f).convert("RGB")
        im.thumbnail((cell, cell))
        x, y = (i % cols) * cell, (i // cols) * (cell + label_h)
        sheet.paste(im, (x + (cell - im.width) // 2, y + (cell - im.height) // 2))
        draw.text((x + 3, y + cell + 1), f.name, fill=(235, 235, 235))
    sheet.save(contact)
    print(f"[run] contact sheet -> {contact}")

    # markdown scaffold
    md = out / "RESEARCH_REPORT.md"
    md.write_text(
        f"# Video research: {args.title}\n\n"
        f"- Source: `{args.source}`\n"
        f"- Source URL: {args.url or '(local file)'}\n"
        f"- Extracted: {len(files)} frames @ {args.fps} fps (ffmpeg)\n"
        f"- Contact sheet: `{contact.name}`\n\n"
        "## Frames\n\n"
        + "\n".join(f"- `frames/{f.name}`" for f in files)
        + "\n\n## Observations\n\n_(fill in from actual visual inspection; cite frame filenames)_\n",
        encoding="utf-8",
    )
    print(f"[run] report scaffold -> {md}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Small reusable video-research pipeline.")
    sub = p.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("info", help="ffprobe metadata")
    s.add_argument("source")
    s.add_argument("--json", action="store_true")
    s.set_defaults(func=cmd_info)

    s = sub.add_parser("download", help="download a permitted URL via yt-dlp")
    s.add_argument("url")
    s.add_argument("--out", default=str(HERE / "downloads"))
    s.add_argument("--format", default="bv*[height<=720]+ba/b[height<=720]/b")
    s.add_argument("--subs", default=None, help="e.g. 'en.*' to fetch subtitles")
    s.add_argument("--cookies-from-browser", default=None,
                   help="ONLY with user approval; uses your own browser session")
    s.set_defaults(func=cmd_download)

    s = sub.add_parser("fps", help="extract N frames/second")
    s.add_argument("source")
    s.add_argument("--fps", type=float, default=12)
    s.add_argument("--start", default=None, help="start time (e.g. 4.0 or 00:00:04)")
    s.add_argument("--duration", default=None, help="window length in seconds (e.g. 2)")
    s.add_argument("--out", default=str(HERE / "output"))
    s.add_argument("--scale", type=int, default=0, help="scale width (0=keep)")
    s.add_argument("--in-output", action="store_true", help="write into <out>/frames")
    s.set_defaults(func=cmd_fps)

    s = sub.add_parser("thumbs", help="extract frames at given timestamps")
    s.add_argument("source")
    s.add_argument("--times", required=True, help="comma list, e.g. 0.0,0.5,1.0")
    s.add_argument("--out", default=str(HERE / "output" / "picks"))
    s.set_defaults(func=cmd_thumbs)

    s = sub.add_parser("contact", help="build a labeled contact sheet")
    s.add_argument("frames", help="directory of frames")
    s.add_argument("--out", default=str(HERE / "output" / "CONTACT_SHEET.png"))
    s.add_argument("--cols", type=int, default=4)
    s.add_argument("--cell", type=int, default=220)
    s.add_argument("--limit", type=int, default=0)
    s.set_defaults(func=cmd_contact)

    s = sub.add_parser("run", help="frames + contact sheet + report scaffold")
    s.add_argument("source")
    s.add_argument("--fps", type=float, default=12)
    s.add_argument("--out", required=True)
    s.add_argument("--title", default="video")
    s.add_argument("--url", default="")
    s.add_argument("--cols", type=int, default=4)
    s.add_argument("--cell", type=int, default=220)
    s.set_defaults(func=cmd_run)

    return p


def main() -> int:
    args = build_parser().parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
