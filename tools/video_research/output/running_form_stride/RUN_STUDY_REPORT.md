# RUN study — evidence report (online permitted video)

Filled in from the **actually extracted frames** read by the vision model. No invented timestamps.

## Source

- URL: https://commons.wikimedia.org/wiki/File:Running_form.ogv
- License: CC BY-SA 2.0 — Bill Sodeman (Wikimedia Commons `extmetadata`)
- Local file: `tools/video_research/downloads/Running_form.ogv`
- ffprobe: 61.63 s, 1280x720, theora, ~29.97 fps, vorbis audio

## Extraction

- Command: `python video_research.py fps "downloads\Running_form.ogv" --fps 10 --start 4.0 --duration 1.6 --out output\running_form_stride\frames`
- 16 frames → `output/running_form_stride/frames/f_001.png … f_016.png`
- Contact sheet: `output/running_form_stride/STRIDE_SHEET.png`
- **Timestamp map** (start 4.0 s, 10 fps): `f_00N ≈ 4.0 + (N−1)×0.1 s`
  → f_001 ≈ 4.0 s, f_004 ≈ 4.3 s, f_008 ≈ 4.7 s, f_012 ≈ 5.1 s, f_016 ≈ 5.5 s

## What was actually seen (from the frames)

Framing: low camera angle; only the **lower legs and feet** are in frame, running against a grass
strip over grey pavement. Blue running shoes, bare lower legs, red ankle bands. A moving shoe shows
motion blur — the clip is not artificially slowed.

Phases read from the ordering of the 16 frames (qualitative, from pose order only):

| Frames (approx time) | Observed leg state |
|---|---|
| f_001–f_004 (≈4.0–4.3 s) | One foot in **contact/stance** near the grass line; the other leg swung back and lifting. |
| f_005–f_008 (≈4.4–4.7 s) | **Push-off / early swing** — stance foot rolls off; the swing leg travels forward with visible blur. |
| f_009–f_012 (≈4.8–5.1 s) | **Passing / cross-over** — the trailing leg extends behind while the other comes through under the body. |
| f_013–f_016 (≈5.2–5.5 s) | Next **contact** developing; leg angles rotate back toward a stance configuration. |

## What could NOT be read from this clip

- Torso lean, pelvis drop/lift, shoulder rotation, arm swing, and weight transfer — the framing shows
  **lower legs only**, so these are **not verifiable** from this source.
- No numeric measurements were derived; phase naming is descriptive.

## Reliability

- Evidence type: 16 real frames viewed by the model. Solid for **foot/leg phase order**.
- Not solid for full-body run mechanics. A dedicated full-body clip is needed for that.
- Single-test caution: one clip does not establish general motion-analysis reliability.

## Reuse

See `tools/video_research/README.md` §4 for RUN/JUMP/DASH/ATTACK window recommendations.
