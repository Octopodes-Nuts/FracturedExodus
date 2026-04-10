shader_type spatial;
render_mode cull_disabled;

uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform float wave_speed : hint_range(0.01, 2.0) = 0.3;
uniform float wave_strength : hint_range(0.0, 0.05) = 0.005;
uniform float wave_frequency : hint_range(0.1, 10.0) = 3.0;
uniform vec2 wind_direction = vec2(1.0, 0.3);

// Glint settings
uniform float glint_speed : hint_range(0.1, 5.0) = 1.5;
uniform float glint_intensity : hint_range(0.0, 0.5) = 0.15;
uniform float glint_sharpness : hint_range(4.0, 64.0) = 24.0;

// Simple hash for pseudo-random glint variation per leaf position
float hash(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y);
}

void vertex() {
	float world_x = (MODEL_MATRIX * vec4(VERTEX, 1.0)).x;
	float world_z = (MODEL_MATRIX * vec4(VERTEX, 1.0)).z;

	vec2 wind_dir = normalize(wind_direction);
	float wave_front = dot(vec2(world_x, world_z), wind_dir) * wave_frequency;

	// Gust envelope
	float gust = 0.6 + 0.4 * sin(TIME * 0.4) + 0.2 * sin(TIME * 0.17);

	float angle = sin(wave_front + TIME * wave_speed) * wave_strength * gust;

	// Rotate around the vertex's own base (model origin Y axis)
	// Use distance from origin in XZ plane as the lever arm
	float dist = length(VERTEX.xz);
	float cos_a = cos(angle);
	float sin_a = sin(angle);

	vec2 wind_dir_xz = wind_dir;
	vec2 perp = vec2(-wind_dir_xz.y, wind_dir_xz.x);

	// Project vertex XZ onto wind axis, rotate only along wind direction
	float along_wind = dot(VERTEX.xz, wind_dir_xz);
	float across_wind = dot(VERTEX.xz, perp);

	float new_along = along_wind * cos_a - VERTEX.y * sin_a;
	float new_y = along_wind * sin_a + VERTEX.y * cos_a;

	VERTEX.x = new_along * wind_dir_xz.x + across_wind * perp.x;
	VERTEX.z = new_along * wind_dir_xz.y + across_wind * perp.y;
	VERTEX.y = new_y;
}

void fragment() {
	vec4 albedo = texture(texture_albedo, UV);
	ALBEDO = albedo.rgb;
	ALPHA = albedo.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;

	// Each leaf gets a unique random phase based on its UV position
	vec2 leaf_cell = floor(UV * 32.0);
	float rand_phase = hash(leaf_cell) * 6.283;
	float rand_speed = 0.5 + hash(leaf_cell + 7.3) * 1.5;

	// Glint pulses at a random rate per leaf, driven by time
	float glint = pow(max(0.0, sin(TIME * glint_speed * rand_speed + rand_phase)), glint_sharpness);
	glint *= glint_intensity;

	EMISSION = albedo.rgb * glint;
}
