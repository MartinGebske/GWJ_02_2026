shader_type spatial;
render_mode unshaded, shadows_disabled, world_vertex_coords;
#include "res://scenes/funcs.gdshaderinc"

uniform vec3 color: source_color;
uniform float lines_1: hint_range(0.0, 200.0, 1.0) = 2.0;
uniform float lines_2: hint_range(0.0, 100.0, 1.0) = 2.0;
uniform float _emission: hint_range(0.0, 10.0) = 1.0;
uniform float _fresnel: hint_range(0.0, 10.0) = 1.0;

varying float rand_dist;

void vertex(){
	float distortion = sin(TIME* 10.0 * VERTEX.y * 30.0) * 0.04;
	float rand_time = random(TIME);
	rand_dist = step(rand_time,0.05);
	VERTEX.x += distortion * rand_dist;
}

void fragment(){
	// this produces random noise evenly distributed without a UV from a model from include
	float screen_noise = random2_1(SCREEN_UV);
	// this is the fresnel from the include
	float screen_fresnel = fresnel(_fresnel, NORMAL, VIEW);
	
	// -- add even lines
	vec2 igrid = floor(SCREEN_UV * lines_1) / lines_1;
	float l1 = mod(igrid.y,2.0);
	l1 = mix(0.4, 1.0, l1);
	
	// -- random lines
	vec2 uv2 = SCREEN_UV;
	uv2.y -= TIME * 0.06;
	vec2 igrid2 = floor(uv2 * lines_2);
	float l2 = random(igrid2.y);
	// create just black and white lines
	l2 = step(0.2, l2);
	l2 = mix(0.2, 1.0, l2);
	
	// Berechne, ob die Fläche nach oben zeigt (Dot-Produkt mit der Y-Achse)
	float is_facing_up = dot(NORMAL, vec3(0.0, 1.0, 0.0));
	// Je näher an 1.0, desto mehr zeigt die Fläche nach oben
	float alpha_up = smoothstep(0.1, 1.0, is_facing_up); // Schwellenwert anpassen
	
	
	// edges 
	float edge_intensity = pow(screen_fresnel, 2.0);
	vec3 edge_color = color * 10.0;
	
	//vec3 edge_color = vec3(1.0); // would be white
	edge_color = mix(color, edge_color, edge_intensity);
	
	float mixed = screen_noise * screen_fresnel * l1 * l2;
	ALBEDO = mix(color, edge_color,edge_intensity) * mix(_emission, _emission + 5.0, rand_dist);
	ALPHA = mix(mixed, 1.0, alpha_up);

}