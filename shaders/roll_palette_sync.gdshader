shader_type canvas_item;
render_mode unshaded;

// Palette-only conversion for the V03 roll sheets.
//
// The roll art is authored on a lighter, cooler 21-colour palette than the
// live RUN/IDLE body. Multiplying it by a warm modulate cannot recover the
// missing navy cloth colours, so this shader snaps every opaque roll pixel to
// its nearest source-palette entry and emits the corresponding RUN colour.
//
// The correspondence is NOT nearest-RGB: iven_roll_palette.gd supplies the
// authored material table (coat -> RUN navy, skin -> RUN warm, ...) because a
// proximity match turns the coat base into RUN's lit coat and keeps the roll
// pale. palette_count limits the search to the real entries; padded slots are
// skipped so colour 0 can never win the lookup.
//
// Colours are supplied in the same sRGB space as the source PNGs (see
// iven_movement_visual.gd); the live 2D Compatibility path does not perform a
// second linear->sRGB conversion for canvas shader output. Alpha is preserved.
uniform vec4 source_palette[32];
uniform vec4 target_palette[32];
uniform int palette_count = 0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a <= 0.001 || palette_count <= 0) {
		COLOR = tex;
	} else {
		vec3 source = tex.rgb;
		vec3 best = source;
		float best_distance = 1.0e20;
		for (int i = 0; i < 32; i++) {
			if (i >= palette_count) {
				break;
			}
			vec3 candidate = source_palette[i].rgb;
			vec3 delta = source - candidate;
			float distance = dot(delta, delta);
			if (distance < best_distance) {
				best_distance = distance;
				best = target_palette[i].rgb;
			}
		}
		COLOR = vec4(best, tex.a);
	}
}
