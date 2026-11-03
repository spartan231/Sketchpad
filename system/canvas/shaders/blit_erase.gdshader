// Erases from a premultiplied LayerSurface: dst *= 1 - stamp alpha * strength.
// Scaling every channel keeps the premultiplied color valid.
shader_type texture_blit;
render_mode blend_mul;

uniform sampler2D source : hint_blit_source0;

void blit() {
	COLOR0 = vec4(1.0 - texture(source, UV).a * MODULATE.a);
}
