shader_type spatial;
render_mode unshaded, shadows_disabled;

uniform vec3 color : source_color = vec3(1.0, 0.0, 1.0);
uniform float emission_strength : hint_range(0.0, 10.0) = 4.5;
uniform float fresnel_power : hint_range(0.1, 10.0) = 4.0;
uniform float gradient_strength : hint_range(0.0, 3.0) = 1.3;
uniform float edge_intensity : hint_range(0.0, 10.0) = 6.0;
uniform float top_edge_whiteness : hint_range(0.0, 1.0) = 0.9;
uniform float side_opacity : hint_range(0.0, 1.0) = 0.8;
uniform float top_opacity : hint_range(0.0, 1.0) = 1.0;

uniform float beat_strength : hint_range(0.0, 2.0) = 0.0;
uniform float alpha_fade : hint_range(0.0, 1.0) = 1.0;

varying float height_mask;
varying float top_mask_v;

void vertex() {
	// Height gradient
	height_mask = clamp(VERTEX.y, 0.0, 1.0);

	// This is the HEX top
	top_mask_v = dot(NORMAL, vec3(0.0, 1.0, 0.0));
}

void fragment() {
	// === BASE SYNTHWAVE GRADIENT ===
	vec3 dark = color * 0.2;
	vec3 bright = color * (1.0 + gradient_strength + beat_strength);
	vec3 gradient_color = mix(dark, bright, height_mask);

	// === SIDE FRESNEL GLOW (Synthwave Rim) ===
	float fresnel = pow(1.0 - dot(NORMAL, VIEW), fresnel_power);
	vec3 rim_color = gradient_color * (1.0 + fresnel * 2.5);

	// === TOP SURFACE DETECTION ===
	float top_surface = smoothstep(0.6, 1.0, top_mask_v);

	// Top bekommt extra Helligkeit auf Beat
	vec3 top_boost = gradient_color * (1.0 + beat_strength * 2.0) * top_surface;


	// === SEPARATE FADE CONTROL (für Auflösen!) ===
	float alpha_base = mix(side_opacity, top_opacity, top_surface);
	float final_alpha = alpha_base * alpha_fade;

	// Weißer Edge Glow auf der Oberseite
	vec3 white_edge = mix(color * edge_intensity, vec3(1.0) * edge_intensity, top_edge_whiteness);

	// Kombiniere: Seiten-Rim + Top-Edge Glow
	vec3 final_color = rim_color + white_edge * top_boost;
	
	// === AUDIO REACTIVE EMISSION ===
	float reactive_emission = emission_strength + (beat_strength * 15.0);
	vec3 emission = final_color * reactive_emission;


	// === OPAQUE TOP (für Jumping Gameplay) ===
	float alpha = mix(side_opacity, top_opacity, top_surface);



	ALBEDO = final_color;
	ALPHA = alpha_fade;
	EMISSION = emission;
}
