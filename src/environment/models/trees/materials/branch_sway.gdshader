shader_type spatial;
render_mode cull_disabled;

uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform float sway_speed : hint_range(0.01, 2.0) = 0.4;
uniform float sway_strength : hint_range(0.0, 0.05) = 0.008;
uniform float sway_frequency : hint_range(0.1, 10.0) = 2.5;
uniform vec2 wind_direction = vec2(1.0, 0.3);
uniform float trunk_radius : hint_range(0.01, 2.0) = 0.1;

void vertex() {
	float world_x = (MODEL_MATRIX * vec4(VERTEX, 1.0)).x;
	float world_z = (MODEL_MATRIX * vec4(VERTEX, 1.0)).z;

	vec2 wind_dir = normalize(wind_direction);
	float wave_front = dot(vec2(world_x, world_z), wind_dir) * sway_frequency;

	// Gust envelope
	float gust = 0.6 + 0.4 * sin(TIME * 0.35) + 0.15 * sin(TIME * 0.19);

	float angle = sin(wave_front + TIME * sway_speed) * sway_strength * gust;

	// Use distance from trunk center (XZ origin) as the tip mask
	// Vertices far from center are branch tips, vertices near center are bases
	float dist_from_center = length(VERTEX.xz);
	float tip_mask = clamp(dist_from_center / trunk_radius, 0.0, 1.0);

	vec2 wind_dir_xz = normalize(wind_direction);

	float disp = sin(wave_front + TIME * sway_speed) * sway_strength * gust * tip_mask;

	VERTEX.x += wind_dir_xz.x * disp;
	VERTEX.z += wind_dir_xz.y * disp;
}

void fragment() {
	vec4 albedo = texture(texture_albedo, UV);
	ALBEDO = albedo.rgb;
	ALPHA = albedo.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
