shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform float noise_scale : hint_range(1.0, 20.0) = 6.0;
uniform float edge_jaggedness : hint_range(0.5, 5.0) = 2.8;
uniform float core_size : hint_range(0.0, 1.0) = 0.35;
uniform vec4 core_color : source_color = vec4(1.0, 0.95, 0.6, 1.0);
uniform vec4 mid_color : source_color = vec4(1.0, 0.45, 0.05, 1.0);
uniform vec4 outer_color : source_color = vec4(0.6, 0.1, 0.0, 1.0);

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
		mix(hash(i),                   hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p = p * 2.1 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

void vertex() {
}

void fragment() {
	vec2 centered = UV - 0.5;
	float dist = length(centered) * 2.0;

	// Warp the distance field with fbm so the blast edge is jagged/uneven
	vec2 noiseUV = UV * noise_scale + TIME * 8.0;
	float n = fbm(noiseUV);
	float warped_dist = dist + (n - 0.5) * 0.6;

	// Hard cutoff at the outer edge shaped by noise
	float outer_mask = 1.0 - smoothstep(0.7, 1.0, pow(warped_dist, edge_jaggedness));

	// Radial colour zones: white-hot core -> orange mid -> dark red outer
	float core_mask  = 1.0 - smoothstep(0.0, core_size, dist);
	float mid_mask   = 1.0 - smoothstep(core_size, 0.75, dist);

	vec3 fire_color = mix(outer_color.rgb, mid_color.rgb, mid_mask);
	fire_color = mix(fire_color, core_color.rgb, core_mask);

	// Second fbm layer adds internal detail / streaks
	float detail = fbm(UV * noise_scale * 2.0 - TIME * 5.0);
	fire_color += detail * 0.25 * mid_mask;

	// COLOR.a is the particle lifetime alpha fed by color_ramp
	float alpha = outer_mask * COLOR.a;

	ALBEDO = fire_color * COLOR.rgb;
	ALPHA = alpha;
}
