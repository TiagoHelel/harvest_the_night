shader_type canvas_item;

// A014 stand-in (0171): stage-2 leaves lose their colour when the season ends.
void fragment() {
	float grey = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	COLOR.rgb = vec3(grey * 0.7);
}
