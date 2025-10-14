shader_type canvas_item;

uniform vec2 scroll_speed = vec2(0.05, 0.0); // +X = vers la droite
uniform float tint_strength = 0.0;           // 0 = neutre, 0.0–0.3 conseillé
uniform vec4 tint_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    // UV qui défilent. REPEAT doit être activé sur la texture.
    vec2 uv = UV + TIME * scroll_speed;
    vec4 col = texture(TEXTURE, uv);

    // Optionnel: léger tint pour homogénéiser la teinte mangrove
    col.rgb = mix(col.rgb, tint_color.rgb, tint_strength);

    COLOR = col;
}
