shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec4 target_color : source_color;
uniform float mix_strength = 1.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    // Ne colore que si visible
    if (tex_color.a < 0.05) {
        discard; // évite le carré flouté
    }

    vec3 final_color = mix(tex_color.rgb, target_color.rgb, mix_strength);
    COLOR = vec4(final_color, tex_color.a); // ← on garde l’alpha original
}
