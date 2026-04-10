shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

uniform float noise_scale : hint_range(1.0, 20.0) = 5.0;
uniform float wisp_sharpness : hint_range(0.5, 6.0) = 2.2;
uniform float edge_softness : hint_range(0.1, 1.0) = 0.55;
uniform float drift_speed : hint_range(0.0, 1.0) = 0.12;

float hash(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i),              hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	vec2 shift = vec2(100.0);
	for (int i = 0; i < 5; i++) {
		v += a * vnoise(p);
		p = p * 2.0 + shift;
		a *= 0.5;
	}
	return v;
}

void vertex() {
}

void fragment() {
	// Soft radial edge — kills the hard quad border
	vec2 centered = UV - 0.5;
	float dist = length(centered) * 2.0;
	float radial = 1.0 - smoothstep(edge_softness, 1.0, dist);

	// Two FBM layers drifting at slightly different speeds/angles
	// to produce thin wispy tendrils rather than uniform puffs
	vec2 uv1 = UV * noise_scale + TIME * vec2(drift_speed * 0.8, drift_speed);
	float n1 = fbm(uv1);

	vec2 uv2 = UV * noise_scale * 1.6 + TIME * vec2(-drift_speed * 0.6, drift_speed * 1.3);
	float n2 = fbm(uv2);

	// Multiply layers: where both are low we get a gap (the wispy holes)
	float wisp = pow(n1 * n2 * 2.2, wisp_sharpness) * radial;

	// COLOR is fed by the particle color_ramp — it carries the lifetime alpha fade
	ALBEDO = COLOR.rgb;
	ALPHA = wisp * COLOR.a;
}
