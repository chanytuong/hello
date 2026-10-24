"""
Parse IVEN_ROLL.blend Action + FCurve + Keyframe counts without Blender.
Blender 3.6+ .blend format:
- Header (12 bytes) + block directory.
- Each file block: 4-byte sig (e.g. 'REND', 'GLOB', 'DNA ', 'SCC1', 'DATA', 'END '), 4-byte total length (including header), then type-specific payload.
- DNA block: contains struct type definitions (sdna index) and struct instances.
- SCC1 block: data-block names (type-tagged strings).
- DATA block(s): the actual data instances; each DATA block begins with a 1-byte type tag (Blender internal type index encoded as char) followed by an array of these typed structs.

For Action/FCurve/Keyframe we only need counts, so we:
1. Find SCC1 to map data-block names (type tag -> name). Actually SCC1 stores names with their type tag char (e.g. 'A' for Action? Not exactly).
2. Find DATA blocks and group by type tag. The Action type tag in Blender is 'A' (0x41) as a DATA block type byte? Not necessarily; it's an sdna type id.

Simpler approach that worked in earlier inspection: the region around 96107000..96107500 shows DATA blocks with a 1-byte tag at offset 8 and a 4-byte length at offset 4, and the payload seems to contain a name string ptr at offset 4 within the payload (for Action?).

But the tag byte values we saw (0x68, 0x98, 0x28, 0xb8) look like they could be Action type tags in a custom or compressed representation (maybe 0x68 = 'h' which is the pool type char for Action in some Blender versions? Unclear).

Given time constraints, the most reliable proof is to attempt a Blender import via Python subprocess if `bpy` is available; if not, fall back to parsing the SCC1 names and counting the DATA blocks with tag == Action tag by looking for the one whose name is IVEN_ROLL.

We'll implement both: try bpy, else parse.
"""
import sys
from pathlib import Path

BLEND = Path("artifacts/iven_roll_redesign/IVEN_ROLL.blend")

def try_bpy():
    try:
        import bpy  # noqa
    except Exception as e:
        return None, e
    import bpy
    bpy.ops.wm.open_mainfile(filepath=str(BLEND), load_ui=False)
    act = None
    for a in bpy.data.actions:
        if a.name == "IVEN_ROLL":
            act = a
            break
    if act is None:
        return None, "Action IVEN_ROLL not found in blend"
    fps = 30.0
    frames = []
    for fc in act.fcurves:
        for k in fc.keyframe_points:
            frames.append(round(k.co.x, 4))
    n_fcurves = len(act.fcurves)
    n_keys = sum(len(fc.keyframe_points) for fc in act.fcurves)
    return {
        "fcurves": n_fcurves,
        "keyframes": n_keys,
        "frames_sorted": sorted(set(frames)),
        "frame_count": len(set(frames)),
        "duration_sec": max(frames) - min(frames) if frames else 0.0,
        "name": act.name,
    }, None


def parse_scc1_and_actions():
    data = BLEND.read_bytes()
    # find SCC1
    i = 0
    scc1 = -1
    while True:
        j = data.find(b"SCC1", i)
        if j < 0:
            break
        if j + 8 <= len(data):
            length = struct.unpack_from("<I", data, j + 4)[0]
            if 16 < length < 5_000_000:
                scc1 = j
                break
        i = j + 4 if j >= 0 else i + 1
    if scc1 < 0:
        return None, "SCC1 block not found"
    length = struct.unpack_from("<I", data, scc1 + 4)[0]
    seg = data[scc1:scc1 + length]
    cnt = struct.unpack_from("<I", seg, 8)[0]
    off = 12
    names = []
    for _ in range(cnt):
        if off + 4 > len(seg):
            break
        nlen = struct.unpack_from("<I", seg, off)[0]
        off += 4
        if nlen <= 0 or off + nlen > len(seg):
            break
        name = seg[off:off + nlen].rstrip(b"\x00").decode("latin1", errors="replace")
        off += nlen
        if name:
            names.append(name)
    return {"names": names, "count": len(names)}, None


if __name__ == "__main__":
    import struct
    bpy_result, bpy_err = try_bpy()
    if bpy_result is not None:
        print("RESULT_BPY", bpy_result)
        sys.exit(0)
    print("BYP_ERROR", repr(bpy_err))
    names_result, names_err = parse_scc1_and_actions()
    if names_result is not None:
        print("RESULT_SCC1", names_result)
        sys.exit(0)
    print("SCC1_ERROR", repr(names_err))
    sys.exit(2)
