shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Vignette
uniform float vignette_strength : hint_range(0.0, 2.0) = 0.5;
uniform float vignette_radius : hint_range(0.0, 1.0) = 0.75;

// Oil paint (Kuwahara filter)
uniform int kuwahara_radius : hint_range(1, 5) = 2;

// Film grain
uniform float grain_strength : hint_range(0.0, 0.2) = 0.03;

// Color grading
uniform float desaturation : hint_range(0.0, 1.0) = 0.15;

// Chromatic aberration
uniform float chromatic_strength : hint_range(0.0, 0.02) = 0.002;

// God rays
uniform vec2 sun_uv = vec2(0.5, 0.3);
uniform float ray_exposure : hint_range(0.0, 2.0) = 0.5;
uniform float ray_decay : hint_range(0.8, 1.0) = 0.97;
uniform float ray_density : hint_range(0.0, 1.0) = 0.5;
uniform float ray_weight : hint_range(0.0, 1.0) = 0.4;
uniform int ray_samples : hint_range(10, 100) = 60;
uniform vec3 ray_color : source_color = vec3(1.0, 0.95, 0.8);

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 kuwahara(vec2 uv, vec2 px, int r) {
	float n = float((r + 1) * (r + 1));
	vec3 mean[4];
	vec3 sq[4];
	for (int q = 0; q < 4; q++) {
		mean[q] = vec3(0.0);
		sq[q] = vec3(0.0);
	}

	for (int j = -r; j <= r; j++) {
		for (int i = -r; i <= r; i++) {
			vec3 c = texture(SCREEN_TEXTURE, uv + vec2(float(i), float(j)) * px).rgb;
			vec2 fi = vec2(float(i), float(j));
			if (fi.x <= 0.0 && fi.y <= 0.0) { mean[0] += c; sq[0] += c * c; }
			if (fi.x >= 0.0 && fi.y <= 0.0) { mean[1] += c; sq[1] += c * c; }
			if (fi.x <= 0.0 && fi.y >= 0.0) { mean[2] += c; sq[2] += c * c; }
			if (fi.x >= 0.0 && fi.y >= 0.0) { mean[3] += c; sq[3] += c * c; }
		}
	}

	float min_var = 1e9;
	vec3 result = mean[0] / n;
	for (int q = 0; q < 4; q++) {
		vec3 m = mean[q] / n;
		vec3 variance = sq[q] / n - m * m;
		float v = dot(variance, vec3(1.0));
		if (v < min_var) {
			min_var = v;
			result = m;
		}
	}
	return result;
}

float god_rays(vec2 uv) {
	vec2 delta = (uv - sun_uv) * (1.0 / float(ray_samples)) * ray_density;
	float illumination = 0.0;
	float decay = 1.0;
	vec2 pos = uv;
	for (int i = 0; i < ray_samples; i++) {
		pos -= delta;
		float samp = luma(texture(SCREEN_TEXTURE, pos).rgb);
		samp *= decay * ray_weight;
		illumination += samp;
		decay *= ray_decay;
	}
	return illumination * ray_exposure / float(ray_samples);
}

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE;
	vec2 dir = SCREEN_UV - 0.5;
	float dist = length(dir);

	// Chromatic aberration towards screen edges
	vec2 aberr = normalize(dir + vec2(0.0001)) * chromatic_strength * dist;
	vec3 color;
	color.r = texture(SCREEN_TEXTURE, SCREEN_UV + aberr).r;
	color.g = texture(SCREEN_TEXTURE, SCREEN_UV).g;
	color.b = texture(SCREEN_TEXTURE, SCREEN_UV - aberr).b;

	// Oil paint
	color = kuwahara(SCREEN_UV, px, kuwahara_radius);

	// God rays
	float rays = god_rays(SCREEN_UV);
	color += ray_color * rays;

	// Desaturate slightly
	color = mix(color, vec3(luma(color)), desaturation);

	// Film grain (animated)
	float grain = hash(SCREEN_UV + fract(TIME * 0.1)) * 2.0 - 1.0;
	color += grain * grain_strength;

	// Vignette
	float vignette = smoothstep(vignette_radius, vignette_radius - 0.3, dist);
	vignette = mix(1.0 - vignette_strength, 1.0, vignette);
	color *= vignette;

	COLOR = vec4(color, 1.0);
}
