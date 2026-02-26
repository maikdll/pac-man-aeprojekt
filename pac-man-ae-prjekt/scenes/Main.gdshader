shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

// --- Anpassbare Parameter im Inspektor ---
uniform float curvature : hint_range(0.0, 10.0) = 3.0; // Wie stark ist das Glas gewölbt?
uniform float chromatic_aberration : hint_range(0.0, 5.0) = 1.0; // Farbverschiebung
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.5; // Horizontale Streifen
uniform float grille_intensity : hint_range(0.0, 1.0) = 0.3; // Vertikales Gitter
uniform float vignette_intensity : hint_range(0.0, 5.0) = 1.2; // Dunkle Ränder
uniform float brightness : hint_range(0.5, 2.0) = 1.2; // Bildschirmhelligkeit

// Funktion für die gewölbte Glas-Optik
vec2 curve(vec2 uv) {
    vec2 centered = uv * 2.0 - 1.0;
    vec2 offset = abs(centered.yx) / vec2(curvature + 1.0);
    centered = centered + centered * offset * offset;
    centered = centered * 0.5 + 0.5;
    return centered;
}

void fragment() {
    // 1. Wölbung anwenden
    vec2 uv = curve(SCREEN_UV);
    
    // Wenn die Wölbung das Bild verkleinert, machen wir den Rand schwarz
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        COLOR = vec4(0.0, 0.0, 0.0, 1.0);
    } else {
        // 2. Chromatic Aberration (Farbverschiebung simulieren)
        float r_offset = 0.002 * chromatic_aberration;
        float b_offset = -0.002 * chromatic_aberration;
        
        float r = texture(screen_texture, vec2(uv.x + r_offset, uv.y)).r;
        float g = texture(screen_texture, uv).g;
        float b = texture(screen_texture, vec2(uv.x + b_offset, uv.y)).b;
        vec3 color = vec3(r, g, b);
        
        // 3. Scanlines (Horizontale Linien)
        // Die Zahl 900.0 ist optimal für 1080p Bildschirme
        float scanline_val = sin(uv.y * 900.0) * 0.04 * scanline_intensity;
        color -= vec3(scanline_val);
        
        // 4. CRT Grille (Vertikales Gitter-Muster)
        float grille_val = sin(uv.x * 1400.0) * 0.03 * grille_intensity;
        color -= vec3(grille_val);
        
        // 5. Vignette (Dunkle Ecken)
        float vignette = uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y);
        color *= clamp(pow(vignette * 15.0, vignette_intensity), 0.0, 1.0);
        
        // 6. Helligkeit leicht anheben, da Linien das Bild abdunkeln
        color *= brightness;
        
        COLOR = vec4(color, 1.0);
    }
}