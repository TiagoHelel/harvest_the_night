shader_type canvas_item;
uniform vec4 head_dark : source_color;
uniform vec4 head_mid : source_color;
uniform vec4 head_light : source_color;
varying vec4 sprite_tint;

void vertex() { sprite_tint = COLOR; }
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	if (distance(source.rgb, vec3(82.0, 80.0, 92.0) / 255.0) < 0.002) {
		source.rgb = head_dark.rgb;
	} else if (distance(source.rgb, vec3(110.0, 108.0, 120.0) / 255.0) < 0.002) {
		source.rgb = head_mid.rgb;
	} else if (distance(source.rgb, vec3(140.0, 138.0, 150.0) / 255.0) < 0.002) {
		source.rgb = head_light.rgb;
	}
	COLOR = source * sprite_tint;
}
