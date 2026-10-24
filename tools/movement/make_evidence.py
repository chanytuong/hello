"""Review actual Godot framebuffers at native and nearest-neighbor scales."""
import json, subprocess, hashlib
from pathlib import Path
from PIL import Image, ImageDraw
import imageio_ffmpeg

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'artifacts/movement_integration'
rows = json.loads((OUT / 'graphical_trace.json').read_text())
captured = [r for r in rows if 'capture' in r]
ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()

def call(args):
    p = subprocess.run([ffmpeg, '-hide_banner', '-y', *args], capture_output=True, text=True)
    if p.returncode: raise RuntimeError(p.stderr[-3000:])
    return p

call(['-framerate', '30', '-i', str(OUT / 'frames/frame_%05d.png'), '-c:v', 'libx264',
      '-crf', '18', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', str(OUT / 'MOVEMENT_GAMEPLAY.mp4')])
call(['-v', 'error', '-i', str(OUT / 'MOVEMENT_GAMEPLAY.mp4'), '-f', 'null', '-'])

def crop(row):
    image = Image.open(OUT / row['capture']).convert('RGB')
    x, y = round(row['x']), round(row['y'])
    # At a boundary, use a literal in-viewport crop rather than PIL black padding.
    left = max(0, min(image.width-96, x-48))
    top = max(0, min(image.height-104, y-88))
    return image.crop((left, top, left+96, top+104))

sheet = Image.new('RGB', (5*400, 2*460), '#202832')
native = Image.new('RGB', (5*130, 2*140), '#202832')
d, nd = ImageDraw.Draw(sheet), ImageDraw.Draw(native)
selected = []
for di, direction in enumerate(['right', 'left']):
    for si, state in enumerate(['IDLE', 'RUN', 'SKID_STOP', 'JUMP', 'DODGE_ROLL']):
        candidates = [r for r in captured if r['case'].endswith(direction) and r['state'] == state]
        preferred = {'IDLE': 0, 'RUN': 5, 'SKID_STOP': 5, 'JUMP': 0, 'DODGE_ROLL': 10}[state]
        r = min(candidates, key=lambda r: abs(r['frame']-preferred))
        selected.append(r)
        im = crop(r)
        sheet.paste(im.resize((384, 416), Image.Resampling.NEAREST), (si*400, di*460+35))
        native.paste(im, (si*130+15, di*140+28))
        d.text((si*400+6, di*460+8), f'{state} / {direction} / cel {r["frame"]+1}', fill='white')
        nd.text((si*130+3, di*140+5), state, fill='white')
sheet.save(OUT / 'NATIVE_AND_4X_STATES.png')
native.save(OUT / 'NATIVE_STATES.png')

# Every roll drawing, from the actual running scene, no source PNG substitutions.
roll_samples = []
for direction in ['right', 'left']:
    plate = Image.new('RGB', (7*208, 3*240), '#202832')
    pd = ImageDraw.Draw(plate)
    for index in range(21):
        candidates = [r for r in captured if r['case'] == f'idle_roll_idle_{direction}' and r['frame'] == index and r['state'] == 'DODGE_ROLL']
        assert candidates, (direction, index)
        r = candidates[0]
        roll_samples.append(r)
        plate.paste(crop(r).resize((192, 208), Image.Resampling.NEAREST), ((index%7)*208, (index//7)*240+25))
        pd.text(((index%7)*208+5, (index//7)*240+5), f'{direction} / {index+1:02}', fill='white')
    plate.save(OUT / f'ROLL_ATTACHMENT_{direction.upper()}.png')

# Moving native + 4x crops. Fixed world-floor row remains visible in each crop.
gif_frames = []
for r in captured:
    if r['case'].startswith(('idle_run_skid_idle', 'run_jump_run', 'idle_roll_idle', 'run_roll_run', 'reversal', 'roll_wall')):
        im = crop(r)
        canvas = Image.new('RGB', (600, 460), '#202832')
        ImageDraw.Draw(canvas).text((14, 12), f'{r["case"]} | {r["state"]} | {r["tick"]/60:.2f}s', fill='white')
        canvas.paste(im, (22, 140))
        canvas.paste(im.resize((384, 416), Image.Resampling.NEAREST), (180, 38))
        gif_frames.append(canvas)
gif_frames[0].save(OUT / 'NATIVE_AND_4X_MOTION.gif', save_all=True, append_images=gif_frames[1:],
                   duration=[30 if i%3 else 40 for i in range(len(gif_frames))], loop=0, disposal=2)

# Inspect decoded animation cels, not only the raw framebuffer PNGs.
gif = Image.open(OUT / 'NATIVE_AND_4X_MOTION.gif')
decoded = Image.new('RGB', (1800, 3*460), '#202832')
gif_duration = 0
gif_count = gif.n_frames
for i in range(gif_count):
    gif.seek(i)
    gif_duration += gif.info.get('duration', 0)
for j, i in enumerate([round(k*(gif_count-1)/8) for k in range(9)]):
    gif.seek(i)
    decoded.paste(gif.convert('RGB'), ((j%3)*600, (j//3)*460))
decoded.save(OUT / 'DECODED_MOTION_CHECK.png')

# Red flame colors are unique to the unchanged source palette. Check the
# actual rendered pixels against the floor, with terrain drawn behind Iven.
palette = {rgb for count, rgb in Image.open(ROOT/'art/iven/movement/flame_atlas.png').convert('RGBA').getcolors()
           if rgb[3] > 0}
palette = {c[:3] for c in palette}
below = []
flame_samples = 0
for row in captured:
    if not row['floor']: continue
    im = Image.open(OUT / row['capture']).convert('RGB')
    x, floor = round(row['x']), round(row['y'])
    for yy in range(max(0, floor-90), min(720, floor+16)):
        for xx in range(max(0, x-48), min(1280, x+48)):
            if im.getpixel((xx, yy)) in palette:
                flame_samples += 1
                if yy >= floor: below.append([row['case'], row['tick'], xx, yy-floor])

sources = json.loads((OUT / 'protected_sources.json').read_text())
changed = [p for p, digest in sources.items() if hashlib.file_digest((ROOT/p).open('rb'), 'sha256').hexdigest() != digest]
assert not changed, changed
validation = {'actual_godot_framebuffers': len(captured), 'mp4_full_decode': 'PASS',
              'mp4_fps': 30, 'selected_state_captures': selected,
              'all_roll_cels_inspected_in_sheets': len(roll_samples),
              'protected_source_files': len(sources), 'changed_sources': changed,
              'max_neck_anchor_rounding_px': max(r['anchor_error'] for r in rows),
              'decoded_gif_frames': gif_count, 'gif_duration_ms': gif_duration,
              'rendered_flame_pixel_samples': flame_samples,
              'flame_pixels_at_or_below_floor': len(below), 'floor_violations_first_10': below[:10],
              'inspection': 'Generated review evidence; agent visual observations recorded separately in QA.'}
(OUT / 'media_validation.json').write_text(json.dumps(validation, indent=2))
print(json.dumps({k:v for k,v in validation.items() if k not in ['selected_state_captures']}))
