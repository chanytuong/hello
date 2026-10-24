# tools/video_research — reusable video research pipeline

Small, self-contained pipeline that turns a video into **frames a vision-capable model can actually
look at**, plus a contact sheet and a Markdown report scaffold.

No large application: one Python script + FFmpeg/ffprobe + Pillow (already present).

```
tools/video_research/
├─ video_research.py        <- the pipeline (this is the whole app)
├─ bin/                     <- portable ffmpeg.exe / ffprobe.exe / ffplay.exe (NOT in PATH)
├─ input/                   <- put local videos to analyse here (optional)
├─ downloads/               <- videos fetched from permitted URLs land here
└─ output/                  <- frames, contact sheets and reports
```

---

## 1. Prerequisites (already installed in this project)

| Tool | Version | Location |
|---|---|---|
| Python | 3.14.7 | `C:\Users\Aloha\AppData\Local\Python\pythoncore-3.14-64` |
| Pillow | 12.3.0 | user site-packages |
| yt-dlp | 2026.08.19 (+ yt-dlp-ejs 0.8.0) | `python -m yt_dlp` |
| ffmpeg | N-127588-...-20261016 | `tools\video_research\bin\ffmpeg.exe` |
| ffprobe | same build | `tools\video_research\bin\ffprobe.exe` |

FFmpeg is **portable** — it is not on the system PATH and nothing global was changed.
The script finds it automatically in `bin/`, and falls back to PATH if `bin/` is missing.

---

## 2. Commands

Run from `tools\video_research`.

```powershell
# metadata
python video_research.py info "input\RUN_FINAL.mp4"

# download a PERMITTED url (legitimate / licensed content only)
python video_research.py download "https://commons.wikimedia.org/..." --out downloads

# frames across the whole clip
python video_research.py fps "input\RUN_FINAL.mp4" --fps 12 --out output\run --in-output

# frames inside a time window (e.g. one stride)
python video_research.py fps "downloads\clip.ogv" --fps 10 --start 4.0 --duration 1.6 --out output\stride\frames

# single frames at exact timestamps
python video_research.py thumbs "input\RUN_FINAL.mp4" --times 0.0,0.25,0.5,1.0 --out output\picks

# labeled contact sheet from any folder of frames
python video_research.py contact "output\stride\frames" --out output\stride\STRIDE_SHEET.png --cols 4 --cell 240

# one-shot: frames + contact sheet + report scaffold
python video_research.py run "input\RUN_FINAL.mp4" --fps 2 --out output\run_final --title "NEVERLOOKBACK RUN_FINAL"
```

Then ask the model to **`read`** the produced PNGs (single frames or the contact sheet) and describe
them. That is the vision step.

---

## 3. Legal / ethical rules baked into the workflow

- Only download content that is public domain, openly licensed (e.g. CC), or that you own.
- **Never** use the pipeline to bypass authentication, DRM, paywalls or platform access controls.
- YouTube now blocks anonymous `yt-dlp` with *"Sign in to confirm you're not a bot."*
  Do **not** work around it by harvesting browser cookies unless the user explicitly approves it and
  the content is theirs to access. Prefer openly licensed hosts (Wikimedia Commons, archive.org).
- Keep downloads small; grab a window, not a whole film.

---

## 4. Recommended settings per animation type (RUN / JUMP / DASH / ATTACK)

| Study | Window to grab | fps to sample | What the frames should let you read |
|---|---|---|---|
| **RUN** | 2–4 full strides (~1–2 s) | 10–15 | contact, down/compression, passing, up/push-off; foot-strike vs. toe-off; opposite-arm swing; vertical bob |
| **JUMP** | ~1.5 s before to ~1.5 s after peak | 12–20 | crouch/anticipation, launch, apex, fall, landing squash, recovery |
| **DASH** | ~0.6–1.0 s (dash is short) | 15–30 | lean angle, first-step explosion, arm tuck, smearing/stretch, foot spacing |
| **ATTACK** | ~0.5–1.0 s around the hit | 15–24 | anticipation, wind-up, contact frame, follow-through, hit-stop/hold |

Tip: for a run cycle, extract a **dense window** (`--fps 12 --start X --duration 2`) rather than
sampling the whole clip; phase order is easier to read when frames are close together.

Contact-sheet tip: 4 columns × 240 px reads well for a full run; for JUMP/ATTACK use 6 columns to
fit the whole arc on one sheet.

---

## 5. What this pipeline does NOT do

- It does **not** "watch" video. It converts video → still PNGs; the model then reads the stills.
- It cannot receive audio.
- Temporal interpolation between frames is inferred by the model, not measured.
- It does not judge artistic quality; it produces evidence for a human/model to interpret.

---

## 6. Provenance

FFmpeg binaries: official yt-dlp build — https://github.com/yt-dlp/FFmpeg-Builds
(equivalent to upstream FFmpeg; GPLv3 build).
yt-dlp: https://github.com/yt-dlp/yt-dlp (Unlicense).
Testing sources are listed in
`E:\neverlookback\research_capability_audit\VIDEO_RESEARCH_PIPELINE_VERIFICATION.md`.
