extends RefCounted
## Palette probing and legacy premodulation for the approved V03 roll sheets.
##
## The live movement visual and the legacy player use roll_palette_sync.gdshader
## with raw V03 textures. The older QA/preview path still uses recolor_sheet()
## plus ROLL_MODULATE: it applies the same role correspondence and divides by
## the modulate so that path also lands on the RUN palette.
##
## Source PNGs and anchors are untouched. This is presentation-only and never
## feeds back into movement, collision or combat.

const ROLL_MODULATE := Color(0.84, 0.765, 0.739, 1.0)

## Authored V03 -> RUN colour roles.
##
## The V03 sheets are not a brightness-shifted copy of the RUN atlas: the same
## 21 colours were re-authored cooler and lighter, and the warm leather/skin
## slots were desaturated into blue-grey. A nearest-RGB match therefore lands
## the coat base (#435060) on RUN's LIT coat (#40546A) instead of its base
## (#2D3745), which is exactly why the roll kept reading pale and grey.
##
## This table is the palette's material correspondence, not a proximity match:
## every coat/cloth tone stays on the RUN navy ramp, every skin/sash tone stays
## on the RUN warm ramp. Keys and values are 0xRRGGBB from the source PNGs and
## the RUN atlas; values are all present in the live RUN palette. Unknown
## colours fall back to nearest-RGB so a future sheet edit fails soft rather
## than rendering unmapped pixels.
const ROLE_TARGETS := {
	0x435060: 0x2D3745, # coat base        -> RUN navy base
	0x546A7E: 0x40546A, # coat lit         -> RUN navy lit
	0x364857: 0x242C36, # coat shadow      -> RUN shadow
	0x26384D: 0x1C2634, # coat deep shadow -> RUN deep shadow
	0x3A495D: 0x242C36, # coat mid shadow  -> RUN shadow
	0x242C38: 0x181E28, # outline          -> RUN outline
	0x162231: 0x130F10, # deep outline     -> RUN black
	0x323245: 0x181E28, # shadow accent    -> RUN outline
	0x8B99A2: 0x40546A, # cloth highlight  -> RUN navy lit
	0x798A93: 0x40546A, # cloth light      -> RUN navy lit
	0x6A7A86: 0x4F5E70, # cloth mid        -> RUN cloth mid
	0x6E7E89: 0x4F5E70, # boot mid         -> RUN cloth mid
	0x6F7284: 0x4F5E70, # cloth accent     -> RUN cloth mid
	0x6D6F77: 0x55453C, # leather grey     -> RUN leather
	0xAAB4B4: 0xC3D2D9, # light rim        -> RUN light rim
	0xA3A4AE: 0x98ABBB, # light cloth      -> RUN light blue
	0x989E9B: 0x98ABBB, # pale cloth       -> RUN light blue
	0xBBBAAA: 0xD8CDB8, # skin light       -> RUN cream
	0x93857F: 0x918A7F, # skin             -> RUN skin
	0x675C62: 0x5C5854, # skin shadow      -> RUN warm shadow
	0x372D39: 0x2B2323, # skin deep shadow -> RUN leather dark
}

## Build the palette-sync material shared by the live and legacy roll paths.
## `source_textures` are the raw V03 sheets; `palette_size` must match the
## shader's fixed array length so padded slots never compete in the lookup.
static func build_material(shader: Shader, run_palette: Array, source_textures: Array, palette_size: int = 32) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = shader
	var source_palette := from_textures(source_textures)
	if run_palette.is_empty() or source_palette.is_empty():
		push_error("Roll palette sync has no source/target palette")
		return material
	var source_colors := PackedColorArray()
	var target_colors := PackedColorArray()
	for i in palette_size:
		if i < source_palette.size():
			var source: Color = source_palette[i]
			source_colors.append(source)
			target_colors.append(resolve(source, run_palette))
		else:
			source_colors.append(Color(0.0, 0.0, 0.0, 0.0))
			target_colors.append(Color(0.0, 0.0, 0.0, 0.0))
	material.set_shader_parameter("source_palette", source_colors)
	material.set_shader_parameter("target_palette", target_colors)
	material.set_shader_parameter("palette_count", mini(palette_size, source_palette.size()))
	return material

## Role lookup first, nearest RUN colour second. Returns an exact RUN palette
## colour in the normal case (the role targets are authored from that palette).
static func resolve(source: Color, palette: Array) -> Color:
	var target: Variant = role_target(source)
	if target != null:
		return target
	return _nearest(source, palette)

## The authored material correspondence for one V03 colour, or null when the
## colour is not part of the known V03 palette.
static func role_target(source: Color) -> Variant:
	var key := _rgb_key(source)
	if not ROLE_TARGETS.has(key):
		return null
	var value: int = ROLE_TARGETS[key]
	return Color(((value >> 16) & 0xFF) / 255.0, ((value >> 8) & 0xFF) / 255.0, (value & 0xFF) / 255.0, 1.0)

static func _rgb_key(source: Color) -> int:
	return (roundi(source.r * 255.0) << 16) | (roundi(source.g * 255.0) << 8) | roundi(source.b * 255.0)

## Collect the unique opaque colours used by the requested SpriteFrames clips.
static func from_sprite_frames(frames: SpriteFrames, animations: Array) -> Array[Color]:
	var textures: Array = []
	for animation in animations:
		var clip := String(animation)
		if not frames.has_animation(clip):
			continue
		for i in frames.get_frame_count(clip):
			textures.append(frames.get_frame_texture(clip, i))
	return from_textures(textures)

## Collect the unique opaque colours from a set of textures. AtlasTexture
## regions are cropped before sampling so a whole atlas never leaks colours
## from unrelated clips into the run palette.
static func from_textures(textures: Array) -> Array[Color]:
	var seen: Dictionary = {}
	for value in textures:
		if value is Texture2D:
			_collect_texture(value as Texture2D, seen)
	return _sorted(seen)

## Build one recoloured ImageTexture per sheet cell. The caller still applies
## ROLL_MODULATE to the sprite; these pixels are pre-divided so that modulate
## lands on the live RUN palette at draw time.
static func recolor_sheet(sheet: Texture2D, run_palette: Array, count: int, cell: int = 82, start: int = 0) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	if sheet == null or run_palette.is_empty():
		return out
	var source := sheet.get_image()
	if source == null:
		return out
	source.convert(Image.FORMAT_RGBA8)
	var mapping := _mapping_for_image(source, run_palette)
	for i in count:
		var source_x := (start + i) * cell
		if source_x < 0 or source_x + cell > source.get_width():
			break
		var frame := Image.create(cell, cell, false, Image.FORMAT_RGBA8)
		for y in cell:
			for x in cell:
				var color := source.get_pixel(source_x + x, y)
				if color.a <= 0.001:
					continue
				var key := Color(color.r, color.g, color.b, 1.0).to_rgba32()
				var target: Color = mapping.get(key, color)
				frame.set_pixel(x, y, Color(target.r, target.g, target.b, color.a))
		out.append(ImageTexture.create_from_image(frame))
	return out

static func _collect_texture(texture: Texture2D, seen: Dictionary) -> void:
	var image := _image_for_texture(texture)
	if image == null:
		return
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a <= 0.001:
				continue
			color.a = 1.0
			seen[color.to_rgba32()] = color

static func _image_for_texture(texture: Texture2D) -> Image:
	if texture is AtlasTexture:
		var atlas_texture := texture as AtlasTexture
		if atlas_texture.atlas == null:
			return null
		var base := atlas_texture.atlas.get_image()
		if base == null:
			return null
		var region := atlas_texture.region
		var rect := Rect2i(int(region.position.x), int(region.position.y), int(region.size.x), int(region.size.y))
		rect = rect.intersection(Rect2i(Vector2i.ZERO, base.get_size()))
		if rect.size.x <= 0 or rect.size.y <= 0:
			return null
		return base.get_region(rect)
	return texture.get_image()

static func _mapping_for_image(image: Image, palette: Array) -> Dictionary:
	var source_colors: Dictionary = {}
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a <= 0.001:
				continue
			color.a = 1.0
			source_colors[color.to_rgba32()] = color
	var mapping: Dictionary = {}
	for key in source_colors:
		var source: Color = source_colors[key]
		mapping[key] = _premodulate(resolve(source, palette))
	return mapping

## Public nearest-colour lookup for the shader palette setup. The roll shader
## needs the raw V03 colours and their exact RUN counterparts, not the
## pre-modulated ImageTextures used by the legacy path.
static func nearest_color(source: Color, palette: Array) -> Color:
	return _nearest(source, palette)

static func _nearest(source: Color, palette: Array) -> Color:
	var best: Color = palette[0]
	var best_distance: float = 1.0e20
	for candidate in palette:
		var other: Color = candidate
		var dr: float = source.r - other.r
		var dg: float = source.g - other.g
		var db: float = source.b - other.b
		var distance: float = dr * dr + dg * dg + db * db
		if distance < best_distance:
			best_distance = distance
			best = other
	return best

static func _premodulate(target: Color) -> Color:
	return Color(
		clampf(target.r / ROLL_MODULATE.r, 0.0, 1.0),
		clampf(target.g / ROLL_MODULATE.g, 0.0, 1.0),
		clampf(target.b / ROLL_MODULATE.b, 0.0, 1.0),
		1.0)

static func _sorted(seen: Dictionary) -> Array[Color]:
	var keys := seen.keys()
	keys.sort()
	var palette: Array[Color] = []
	for key in keys:
		palette.append(seen[key])
	return palette
