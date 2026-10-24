"""Lossless packing of existing render cells, with source/checkpoint receipts."""
import hashlib, json, math, shutil
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'art/iven/movement'
EVIDENCE = ROOT / 'artifacts/movement_integration'
OUT.mkdir(parents=True, exist_ok=True)
EVIDENCE.mkdir(parents=True, exist_ok=True)
(EVIDENCE / '.gdignore').touch()

def sha(p):
    return hashlib.file_digest(p.open('rb'), 'sha256').hexdigest()

checkpoint = EVIDENCE / 'checkpoint'
if not checkpoint.exists():
    checkpoint.mkdir()
    for name in ['project.godot', 'scripts/player.gd', 'scenes/player.tscn', 'scenes/main.tscn']:
        dest = checkpoint / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / name, dest)
    (checkpoint / 'README.txt').write_text('No Git repository configured. Pre-edit file checkpoint.\n')

jump = ROOT / 'maincharacter/jump_simplified/r2'
skid = ROOT / 'maincharacter/run_skid_stop'
roll = ROOT / 'maincharacter/dodge_roll'
flame = ROOT / 'maincharacter/flame_head_v3'
ja = json.loads((jump / 'ANCHORS.json').read_text())
sa = json.loads((skid / 'PREVIEW_ANCHORS.json').read_text())
ra = json.loads((roll / 'PREVIEW_ANCHORS.json').read_text())
source_manifest = json.loads((roll / 'sprites/SPRITE_MANIFEST.json').read_text())
assets, entries, animations = {}, [], {}
protected = {}

def record(p):
    protected[p.relative_to(ROOT).as_posix()] = sha(p)

for p in [jump / 'IVEN_JUMP_GAMEPLAY.blend', skid / 'IVEN_RUN_SKID_STOP.blend',
          roll / 'IVEN_DODGE_ROLL.blend', flame / 'IVEN_FLAME_HEAD_V3.pxo',
          jump / 'ANCHORS.json', skid / 'PREVIEW_ANCHORS.json', roll / 'PREVIEW_ANCHORS.json',
          flame / 'flame_motion.js', ROOT / 'maincharacter/iven_animation_research/CAMERA_AND_ASSET_LOCK.json']:
    record(p)

for direction in ['right', 'left']:
    groups = {
        'IDLE': [(jump / f'body/{direction}/82/STANDING.png', ja[direction]['STANDING'])],
        'RUN': [(jump / f'body/{direction}/82/RUN_{n:02}.png', ja[direction][f'RUN_{n:02}']) for n in range(1, 19)],
        'SKID_STOP': [(skid / f'frames/{direction}/82/body_{n:04}.png', sa[direction][(n-1)*8]) for n in range(6, 19)],
        'JUMP': [(jump / f'body/{direction}/82/AIR.png', ja[direction]['AIR'])],
        'DODGE_ROLL': [(roll / f'body/{direction}/ROLL_{n:02}.png', ra[direction][f'ROLL_{n:02}']) for n in range(1, 22)]
    }
    for state, frames in groups.items():
        name = f'{state}_{direction}'
        animations[name] = []
        for p, anchor in frames:
            im = Image.open(p).convert('RGBA')
            assert im.size == (82, 82), p
            assert im.getextrema()[3][0] == 0 and im.getbbox(), p
            index = len(entries)
            animations[name].append(index)
            neck = anchor['neck_xy']
            angle = 0.0
            if state == 'DODGE_ROLL':
                tip = anchor['neck_tip_xy']
                angle = math.atan2(tip[1]-neck[1], tip[0]-neck[0]) + math.pi/2
            entries.append({'image': im, 'source': p.relative_to(ROOT).as_posix(),
                            'neck': neck, 'angle': angle})
            record(p)

atlas = Image.new('RGBA', (82*9, 82*math.ceil(len(entries)/9)))
for i, entry in enumerate(entries):
    xy = ((i % 9)*82, (i // 9)*82)
    atlas.paste(entry['image'], xy)
    assert atlas.crop((*xy, xy[0]+82, xy[1]+82)).tobytes() == entry['image'].tobytes()
atlas.save(OUT / 'body_atlas.png')
shutil.copy2(flame / 'FLAME_HEAD_V3_SHEET.png', OUT / 'flame_atlas.png')
record(flame / 'FLAME_HEAD_V3_SHEET.png')

lines = [f'[gd_resource type="SpriteFrames" load_steps={len(entries)+2} format=3]',
         '[ext_resource type="Texture2D" path="res://art/iven/movement/body_atlas.png" id="1"]']
for i in range(len(entries)):
    lines += [f'[sub_resource type="AtlasTexture" id="F{i}"]', 'atlas = ExtResource("1")',
              f'region = Rect2({(i%9)*82}, {(i//9)*82}, 82, 82)']
anim = []
for name, indices in animations.items():
    frames = ', '.join('{"duration": 1.0, "texture": SubResource("F%d")}' % i for i in indices)
    loop = 'true' if name.startswith(('RUN_', 'IDLE_', 'JUMP_')) else 'false'
    anim.append('{"frames": [%s], "loop": %s, "name": &"%s", "speed": 30.0}' % (frames, loop, name))
lines += ['[resource]', 'animations = [' + ',\n'.join(anim) + ']']
(OUT / 'body_frames.tres').write_text('\n\n'.join(lines), encoding='utf-8')
anchors = {name: [{'neck': entries[i]['neck'], 'angle': entries[i]['angle']} for i in ids]
           for name, ids in animations.items()}
(OUT / 'anchors.json').write_text(json.dumps(anchors, indent=2))
assets = {
    'native_cell': [82, 82], 'pivot': source_manifest['floor_origin_pixel_center'],
    'scale': 1.0, 'camera': source_manifest['camera'], 'body_atlas': list(atlas.size),
    'animations': {n: {'frames': len(ids), 'fps': 30, 'sources': [entries[i]['source'] for i in ids]}
                   for n, ids in animations.items()},
    'status': {'RUN': 'approved baseline per developer; original cells unchanged',
               'SKID_STOP': 'approved baseline per developer; original cells unchanged',
               'IDLE': 'TEMPORARY held existing standing frame; no approved idle loop found',
               'JUMP': 'TEMPORARY current R2 AIR hold; no human approval recorded',
               'DODGE_ROLL': 'TEMPORARY processed IVEN_DODGE_ROLL review candidate',
               'flame': 'TEMPORARY existing V3 review candidate; artwork unchanged'},
    'license': 'Project-provided assets. Roll source FBX license remains unverified: local prototype only; commercial release blocked pending provenance.',
    'packing': 'Exact RGBA tile equality checked for all 108 cells; no trim, recolor, resize or camera changes.'
}
(OUT / 'asset_manifest.json').write_text(json.dumps(assets, indent=2))
receipt = EVIDENCE / 'protected_sources.json'
if not receipt.exists():
    receipt.write_text(json.dumps(protected, indent=2))
else:
    old = json.loads(receipt.read_text())
    assert all(sha(ROOT / p) == digest for p, digest in old.items())
print(f'Packed {len(entries)} exact cells; protected {len(protected)} source files; checkpoint {checkpoint}')
