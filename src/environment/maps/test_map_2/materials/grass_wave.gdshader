shader_type spatial;
render_mode cull_disabled;

uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform float wave_speed : hint_range(0.1, 5.0) = 1.0;
uniform float wave_strength : hint_range(0.0, 0.5) = 0.08;
uniform float wave_frequency : hint_range(0.1, 10.0) = 2.0;
uniform vec2 wind_direction = vec2(1.0, 0.3);
// Controls how much the bottom of the mesh is pinned
uniform float height_mask_power : hint_range(0.5, 4.0) = 2.0;

void vertex() {
	float world_x = (MODEL_MATRIX * vec4(VERTEX, 1.0)).x;
	float world_z = (MODEL_MATRIX * vec4(VERTEX, 1.0)).z;

	// Wind travels across the terrain as a wave front — all grass bends together
	// but the speed of the wave varies using a second slower sine so gusts come and go
	vec2 wind_dir = normalize(wind_direction);
	float wave_front = dot(vec2(world_x, world_z), wind_dir) * wave_frequency;

	// Gust envelope: slow sine that varies the intensity of the wave over time
	float gust = 0.6 + 0.4 * sin(TIME * 0.4) + 0.2 * sin(TIME * 0.17);

	float sway = sin(wave_front + TIME * wave_speed) * wave_strength * gust;

	// Pin the base of the blade, allow tips to sway
	float height_mask = pow(clamp(1.0 - UV.y, 0.0, 1.0), height_mask_power);

	VERTEX.x += wind_dir.x * sway * height_mask;
	VERTEX.z += wind_dir.y * sway * height_mask;
}

void fragment() {
	vec4 albedo = texture(texture_albedo, UV);
	ALBEDO = albedo.rgb;
	ALPHA = albedo.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
