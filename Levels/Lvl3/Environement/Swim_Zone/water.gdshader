shader_type canvas_item;

// vitesse par défaut
uniform float speed : hint_range(0.0, 0.2) = 0.02;

void fragment() {
    vec2 uv = UV;
    // on multiplie par une petite valeur pour bien ralentir
    uv.x = fract(uv.x + TIME * speed * 0.1);
    COLOR = texture(TEXTURE, uv);
}
