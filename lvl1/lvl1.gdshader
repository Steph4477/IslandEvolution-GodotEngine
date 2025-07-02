shader_type canvas_item;
render_mode unshaded, light_only;

uniform vec2 light_direction = vec2(1.0, 1.0); // Diagonale bas-gauche

void fragment() {
    float intensity = clamp(dot(normalize(-light_direction), vec2(0.0, -1.0)), 0.0, 1.0);
    COLOR.rgb *= intensity;
}
