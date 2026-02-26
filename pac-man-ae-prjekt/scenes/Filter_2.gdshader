shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

void fragment() {
    // 1. Holt die Originalfarbe des Pixels an dieser Stelle
    vec4 color = texture(screen_texture, SCREEN_UV);
    
    // 2. Rechnet die bunte Farbe in einen reinen Helligkeitswert (Graustufe) um.
    // Wir nutzen hier eine präzisere Formel als beim letzten Mal (Luminanz),
    // damit z.B. gelber Pac-Man auch wirklich als "hell" erkannt wird.
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    
    // --- Unsere neue 4-Farben-Palette (Blau & Schwarz) ---
    
    // Farbe 1: Tiefschwarz (für den Hintergrund)
    vec3 color_black = vec3(0.0, 0.0, 0.0);
    
    // Farbe 2: Klassisches Dunkelblau (für die Wände)
    // (RGB: 0 Rot, 10% Grün, 55% Blau)
    vec3 color_dark_blue = vec3(0.0, 0.10, 0.55);
    
    // Farbe 3: Mittelblau (für Punkte und dunklere Geister)
    vec3 color_mid_blue = vec3(0.2, 0.4, 0.8);
    
    // Farbe 4: Helles Eisblau/Weiß (für Pac-Man und Highlights)
    // (Damit der Spieler sich gut vom dunklen Rest abhebt)
    vec3 color_bright_blue = vec3(0.7, 0.9, 1.0);
    
    vec3 final_color;
    
    // 3. Die harte Zuteilung: Je nach Helligkeit wird eine der 4 Farben gewählt.
    
    if (gray < 0.15) {
        // Alles was sehr dunkel ist, wird komplett Schwarz
        final_color = color_black;
    } else if (gray < 0.45) {
        // Dunklere Elemente (wie blaue Wände) bleiben Dunkelblau
        final_color = color_dark_blue;
    } else if (gray < 0.75) {
        // Mittlere Helligkeit wird Mittelblau
        final_color = color_mid_blue;
    } else {
        // Alles Helle (Pac-Man, große Punkte) wird leuchtend Eisblau
        final_color = color_bright_blue;
    }
    
    // Das fertige monochrome Bild ausgeben
    COLOR = vec4(final_color, 1.0);
}