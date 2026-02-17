shader_type canvas_item;
render_mode unshaded, skip_vertex_transform;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float blur = 0.1;
uniform float vignette_multiplier = 2.0;

// 7 is a decent number. 2 would be extremely distorted
const float curvature = 7.0;



void fragment() {
	// Distortion of the screen
	vec2 centerd_uv = SCREEN_UV * 2.0 - 1.0;
	vec2 uv_offset = centerd_uv.yx / curvature;
	vec2 warped_uv = centerd_uv + centerd_uv * uv_offset * uv_offset;
	vec3 cutoff = vec3(step(abs(warped_uv.x),1.0) * step(abs(warped_uv.y), 1.0)); 
	
	// Scanlines
	float screen_height = 1.0 / SCREEN_PIXEL_SIZE.y;
	vec3 scanlines = vec3(sin(2.0 * warped_uv.y * screen_height) * 0.1 + 0.8);
	
	// vignette
	vec3 vignette = vec3(length(pow(abs(centerd_uv), vec2(4.0)) / 3.0));
	
	vec3 screen_color = textureLod(screen_texture, (warped_uv + 1.0) / 2.0, blur).rgb * cutoff * scanlines;
	screen_color -= vignette * vignette_multiplier;
	
	COLOR = vec4(screen_color, 1.0);
}
