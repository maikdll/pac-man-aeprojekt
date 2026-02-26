shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Schieberegler für den Inspektor
uniform float shake_power : hint_range(0.0, 0.02) = 0.003; // Wie stark wackelt es?
uniform float shake_speed : hint_range(0.0, 20.0) = 5.0;   // Wie schnell wackelt es?
uniform float color_split : hint_range(0.0, 0.02) = 0.004; // Wie weit trennen sich Rot und Blau?

void fragment() {
    vec2 uv = SCREEN_UV;
    
    // Das Bild leicht wellenförmig verzerren (Wobble)
    uv.x += sin(TIME * shake_speed + uv.y * 10.0) * shake_power;
    
    // Die Farben (Rot, Grün, Blau) leicht versetzt auslesen
    float r = texture(screen_texture, uv - vec2(color_split, 0.0)).r;
    float g = texture(screen_texture, uv).g;
    float b = texture(screen_texture, uv + vec2(color_split, 0.0)).b;
    
    COLOR = vec4(r, g, b, 1.0);
}