shader_type canvas_item;
render_mode unshaded;
uniform vec2 cel_origin = vec2(0.0);
uniform float bend = 0.0;
uniform float vertical = 0.0;
uniform float branch = 0.0;

// Existing V3 inverse nearest deformation. Fixed root rows >=28, no blur.
void fragment() {
	vec2 p = floor(UV / TEXTURE_PIXEL_SIZE) - cel_origin;
	float sy = p.y >= 28.0 ? p.y : floor((p.y - 28.0 * vertical / 18.0) / (1.0 - vertical / 18.0) + 0.5);
	float height = clamp((28.0 - sy) / 18.0, 0.0, 1.0);
	float b = p.x > 19.0 ? 0.65 * bend + 0.35 * branch : bend;
	vec2 sp = vec2(p.x - floor(b * pow(height, 1.22) + 0.5), sy);
	if (sp.x < 0.0 || sp.x >= 36.0 || sy < 0.0 || sy >= 36.0) {
		COLOR = vec4(0.0);
	} else {
		COLOR = texture(TEXTURE, (sp + cel_origin + vec2(0.5)) * TEXTURE_PIXEL_SIZE);
	}
}
