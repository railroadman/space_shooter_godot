shader_type canvas_item;
// Paints the sprite one flat colour (hit flash); `amount` blends from the normal look to the flat colour.
uniform vec4 fill_color : source_color = vec4(1.0);
uniform float amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	COLOR.rgb = mix(COLOR.rgb, fill_color.rgb, amount);
}
