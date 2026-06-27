shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 0.35;
uniform float radius : hint_range(0.0, 1.0) = 0.75;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv) / radius;
	float vignette = smoothstep(0.0, 1.0, dist);
	COLOR = vec4(0.0, 0.0, 0.0, vignette * strength);
}
