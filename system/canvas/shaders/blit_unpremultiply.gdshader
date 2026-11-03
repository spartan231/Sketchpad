// Copies a premultiplied LayerSurface out to straight alpha for saving.
shader_type texture_blit;
render_mode blend_disabled;

uniform sampler2D source : hint_blit_source0;

void blit() {
	vec4 c = texture(source, UV);
	COLOR0 = c.a > 0.0 ? vec4(c.rgb / c.a, c.a) : vec4(0.0);
}
