--[[
  Lumetric Corrector für OBS Studio
  Eine Farbkorrektur-Lösung inspiriert von Adobe Lumetri Color
  
  Autor: TheGeekFreaks
  Version: 2.0.0
  Lizenz: GPLv3
]]

-- OBS Modul einfügen
local obs = obslua

-- Minimaler Filter, der praktisch nichts tut - ein "Null-Filter"

local source_info = {}
source_info.id = "lumetric_corrector_filter"
source_info.type = obs.OBS_SOURCE_TYPE_FILTER
source_info.output_flags = bit.bor(obs.OBS_SOURCE_VIDEO, obs.OBS_SOURCE_CUSTOM_DRAW)

-- Übersetzungen
local function T(k) return _(k) end

local translations = {
    ["en-US"] = {
        ["lumetric_corrector"] = "Lumetric Corrector",
        ["presets"] = "Presets",
        ["preset_neutral"] = "Neutral",
        ["preset_warm"] = "Warm",
        ["preset_cool"] = "Cool",
        ["preset_vibrant"] = "Vibrant",
        ["apply_preset"] = "Apply Preset",
        ["basic"] = "Basic Corrections",
        ["exposure"] = "Exposure",
        ["contrast"] = "Contrast",
        ["brightness"] = "Brightness",
        ["highlights"] = "Highlights",
        ["shadows"] = "Shadows",
        ["whites"] = "Whites",
        ["blacks"] = "Blacks",
        ["highlight_fade"] = "Highlight Fade",
        ["shadow_fade"] = "Shadow Fade",
        ["black_lift"] = "Black Lift",
        ["wb"] = "White Balance",
        ["temperature"] = "Temperature",
        ["tint"] = "Tint",
        ["color"] = "Color",
        ["saturation"] = "Saturation",
        ["vibrance"] = "Vibrance",
        ["vignette"] = "Vignette",
        ["vignette_amount"] = "Amount",
        ["vignette_radius"] = "Radius",
        ["vignette_feather"] = "Feathering",
        ["select_preset"] = "Select Preset",
        ["neutral"] = "Neutral",
        ["warm"] = "Warm",
        ["cool"] = "Cool",
        ["contrast_boost"] = "Contrast Boost",
        ["contrast_reduce"] = "Contrast Reduce",
        ["bright"] = "Bright",
        ["dark"] = "Dark",
        ["vintage"] = "Vintage",
        ["bw"] = "Black & White",
        ["bw_high_contrast"] = "B&W High Contrast",
        ["sepia"] = "Sepia",
        ["filmic"] = "Filmic",
        ["cinematic"] = "Cinematic",
        ["dramatic"] = "Dramatic",
        ["vibrant"] = "Vibrant",
        ["muted"] = "Muted",
        ["warm_contrast"] = "Warm Contrast",
        ["cool_contrast"] = "Cool Contrast",
        ["shadows_blue"] = "Shadows Blue",
        ["shadows_green"] = "Shadows Green",
        ["highlights_warm"] = "Highlights Warm",
        ["sunset"] = "Sunset",
        ["moonlight"] = "Moonlight",
        ["vivid_warm"] = "Vivid Warm",
        
        -- Neue kreative Presets (v2.0)
        ["creative_presets"] = "Creative Presets",
        ["neo_noir"] = "Neo Noir",
        ["cyberpunk"] = "Cyberpunk",
        ["retro_film"] = "Retro Film",
        ["teal_orange"] = "Teal & Orange",
        ["dreamy_bloom"] = "Dreamy Bloom",
        ["crisp_clarity"] = "Crisp Clarity",
        ["horror_atmosphere"] = "Horror Atmosphere",
        ["pastel_dreams"] = "Pastel Dreams",
        ["game_stream"] = "Game Stream",
        ["analog_vhs"] = "Analog VHS",
        
        ["color_wheels"] = "Color Balance",
        ["shadows_color_r"] = "Shadows Red",
        ["shadows_color_g"] = "Shadows Green",
        ["shadows_color_b"] = "Shadows Blue",
        ["midtones_color_r"] = "Midtones Red",
        ["midtones_color_g"] = "Midtones Green",
        ["midtones_color_b"] = "Midtones Blue",
        ["highlights_color_r"] = "Highlights Red",
        ["highlights_color_g"] = "Highlights Green",
        ["highlights_color_b"] = "Highlights Blue",
        
        -- Split-Toning
        ["split_toning"] = "Split Toning",
        ["shadows_red"] = "Shadows Red",
        ["shadow_red_desc"] = "Red component for shadow toning",
        ["shadows_green"] = "Shadows Green",
        ["shadow_green_desc"] = "Green component for shadow toning",
        ["shadows_blue"] = "Shadows Blue",
        ["shadow_blue_desc"] = "Blue component for shadow toning",
        ["shadows_sat"] = "Shadows Saturation",
        ["shadow_sat_desc"] = "Strength of shadow toning",
        ["highlights_red"] = "Highlights Red",
        ["highlight_red_desc"] = "Red component for highlight toning",
        ["highlights_green"] = "Highlights Green",
        ["highlight_green_desc"] = "Green component for highlight toning",
        ["highlights_blue"] = "Highlights Blue",
        ["highlight_blue_desc"] = "Blue component for highlight toning",
        ["highlights_sat"] = "Highlights Saturation",
        ["highlight_sat_desc"] = "Strength of highlight toning",
        
        -- Creative Effects
        ["creative_fx"] = "Creative Effects",
        ["sharpen"] = "Sharpen",
        ["sharpen_desc"] = "Local sharpness using unsharp mask",
        ["bloom"] = "Bloom",
        ["bloom_desc"] = "Soft glow effect on bright areas",
        ["halation"] = "Halation",
        ["halation_desc"] = "Reddish glow on highlights (film look)",
        
        -- LUT
        ["lut"] = "3D LUT",
        ["lut_file"] = "LUT File",
        ["lut_file_desc"] = "3D LUT file in CUBE or PNG format (33x33 or 64x64 texture)",
        ["lut_strength"] = "LUT Strength",
        ["lut_strength_desc"] = "Strength of the LUT effect",
        ["basic_presets"] = "--- BASIC PRESETS ---",
        ["style_presets"] = "--- STYLE PRESETS ---",
        ["color_mood_presets"] = "--- COLOR MOOD PRESETS ---",
        ["era_presets"] = "--- ERA PRESETS ---",
        ["creative_presets"] = "--- CREATIVE PRESETS ---",
        ["neo_noir"] = "Neo Noir",
        ["cyberpunk"] = "Cyberpunk",
        ["retro_film"] = "Retro Film",
        ["teal_orange"] = "Teal & Orange",
        ["dreamy_bloom"] = "Dreamy Bloom",
        ["crisp_clarity"] = "Crisp Clarity",
        ["horror_atmosphere"] = "Horror Atmosphere",
        ["pastel_dreams"] = "Pastel Dreams",
        ["game_stream"] = "Game Stream",
        ["analog_vhs"] = "Analog VHS",
        
        ["color_wheels"] = "Color Balance",
        ["shadows_color_r"] = "Shadows Red",
        ["shadows_color_g"] = "Shadows Green",
        ["shadows_color_b"] = "Shadows Blue",
        ["midtones_color_r"] = "Midtones Red",
        ["midtones_color_g"] = "Midtones Green",
        ["midtones_color_b"] = "Midtones Blue",
        ["highlights_color_r"] = "Highlights Red",
        ["highlights_color_g"] = "Highlights Green",
        ["highlights_color_b"] = "Highlights Blue",
        
        -- Split-Toning
        ["split_toning"] = "Split Toning",
        ["shadows_red"] = "Shadows Red",
        ["shadow_red_desc"] = "Red component for shadow toning",
        ["shadows_green"] = "Shadows Green",
        ["shadow_green_desc"] = "Green component for shadow toning",
        ["shadows_blue"] = "Shadows Blue",
        ["shadow_blue_desc"] = "Blue component for shadow toning",
        ["shadows_sat"] = "Shadows Saturation",
        ["shadow_sat_desc"] = "Strength of shadow toning",
        ["highlights_red"] = "Highlights Red",
        ["highlight_red_desc"] = "Red component for highlight toning",
        ["highlights_green"] = "Highlights Green",
        ["highlight_green_desc"] = "Green component for highlight toning",
        ["highlights_blue"] = "Highlights Blue",
        ["highlight_blue_desc"] = "Blue component for highlight toning",
        ["highlights_sat"] = "Highlights Saturation",
        ["highlight_sat_desc"] = "Strength of highlight toning",
        
        -- Creative Effects
        ["creative_fx"] = "Creative Effects",
        ["sharpen"] = "Sharpen",
        ["sharpen_desc"] = "Local sharpness using unsharp mask",
        ["bloom"] = "Bloom",
        ["bloom_desc"] = "Soft glow effect on bright areas",
        ["halation"] = "Halation",
        ["halation_desc"] = "Reddish glow on highlights (film look)",
        
        -- LUT
        ["lut"] = "3D LUT",
        ["lut_file"] = "LUT File",
        ["lut_file_desc"] = "3D LUT file in CUBE or PNG format (33x33 or 64x64 texture)",
        ["lut_strength"] = "LUT Strength",
        ["lut_strength_desc"] = "Strength of the LUT effect",
        ["basic_presets"] = "--- BASIC PRESETS ---",
        ["style_presets"] = "--- STYLE PRESETS ---",
        ["color_mood_presets"] = "--- COLOR MOOD PRESETS ---",
        ["era_presets"] = "--- ERA PRESETS ---"
    },
    ["de-DE"] = {
        ["lumetric_corrector"] = "Lumetric Korrektor",
        ["presets"] = "Voreinstellungen",
        ["preset_neutral"] = "Neutral",
        ["preset_warm"] = "Warm",
        ["preset_cool"] = "Kühl",
        ["preset_vibrant"] = "Lebendig",
        ["apply_preset"] = "Voreinstellung anwenden",
        ["basic"] = "Grundlegende Korrekturen",
        ["exposure"] = "Belichtung",
        ["contrast"] = "Kontrast",
        ["brightness"] = "Helligkeit",
        ["highlights"] = "Lichter",
        ["shadows"] = "Schatten",
        ["whites"] = "Weiß",
        ["blacks"] = "Schwarz",
        ["highlight_fade"] = "Lichter Ausbleichen",
        ["shadow_fade"] = "Schatten Aufhellen",
        ["black_lift"] = "Schwarzwert Anheben",
        ["wb"] = "Weißabgleich",
        ["temperature"] = "Temperatur",
        ["tint"] = "Farbton",
        ["color"] = "Farbe",
        ["saturation"] = "Sättigung",
        ["vibrance"] = "Lebendigkeit",
        ["vignette"] = "Vignette",
        ["vignette_amount"] = "Stärke",
        ["vignette_radius"] = "Radius",
        ["vignette_feather"] = "Weichzeichnung",
        ["select_preset"] = "Voreinstellung auswählen",
        ["neutral"] = "Neutral",
        ["warm"] = "Warm",
        ["cool"] = "Kühl",
        ["contrast_boost"] = "Kontrast-Boost",
        ["contrast_reduce"] = "Kontrast-Reduzierung",
        ["bright"] = "Hell",
        ["dark"] = "Dunkel",
        ["vintage"] = "Vintage",
        ["bw"] = "Schwarz-Weiß",
        ["bw_high_contrast"] = "S/W Hochkontrast",
        ["sepia"] = "Sepia",
        ["filmic"] = "Filmisch",
        ["cinematic"] = "Cinematisch",
        ["dramatic"] = "Dramatisch",
        ["vibrant"] = "Lebendig",
        ["muted"] = "Gedämpft",
        ["warm_contrast"] = "Warmer Kontrast",
        ["cool_contrast"] = "Kühler Kontrast",
        ["shadows_blue"] = "Schatten Blau",
        ["shadows_green"] = "Schatten Grün",
        ["highlights_warm"] = "Lichter Warm",
        ["sunset"] = "Sonnenuntergang",
        ["moonlight"] = "Mondlicht",
        ["vivid_warm"] = "Lebendig Warm",
        ["color_wheels"] = "Farbbalance",
        ["shadows_color_r"] = "Schatten Rot",
        ["shadows_color_g"] = "Schatten Grün",
        ["shadows_color_b"] = "Schatten Blau",
        ["midtones_color_r"] = "Mitteltöne Rot",
        ["midtones_color_g"] = "Mitteltöne Grün",
        ["midtones_color_b"] = "Mitteltöne Blau",
        ["highlights_color_r"] = "Lichter Rot",
        ["highlights_color_g"] = "Lichter Grün",
        ["highlights_color_b"] = "Lichter Blau",
        
        -- Split-Toning
        ["split_toning"] = "Split-Toning",
        ["shadows_red"] = "Schatten Rot",
        ["shadow_red_desc"] = "Rot-Anteil für Schatten-Toning",
        ["shadows_green"] = "Schatten Grün",
        ["shadow_green_desc"] = "Grün-Anteil für Schatten-Toning",
        ["shadows_blue"] = "Schatten Blau",
        ["shadow_blue_desc"] = "Blau-Anteil für Schatten-Toning",
        ["shadows_sat"] = "Schatten Sättigung",
        ["shadow_sat_desc"] = "Stärke des Schatten-Tonings",
        ["highlights_red"] = "Lichter Rot",
        ["highlight_red_desc"] = "Rot-Anteil für Lichter-Toning",
        ["highlights_green"] = "Lichter Grün",
        ["highlight_green_desc"] = "Grün-Anteil für Lichter-Toning",
        ["highlights_blue"] = "Lichter Blau",
        ["highlight_blue_desc"] = "Blau-Anteil für Lichter-Toning",
        ["highlights_sat"] = "Lichter Sättigung",
        ["highlight_sat_desc"] = "Stärke des Lichter-Tonings",
        
        -- Kreative Effekte
        ["creative_fx"] = "Kreative Effekte",
        ["sharpen"] = "Schärfen",
        ["sharpen_desc"] = "Lokale Schärfe durch Unsharp Mask",
        ["bloom"] = "Bloom",
        ["bloom_desc"] = "Weicher Glüheffekt auf hellen Bereichen",
        ["halation"] = "Halation",
        ["halation_desc"] = "Rötlicher Schimmer auf Highlights (Film-Look)",
        
        -- LUT
        ["lut"] = "3D LUT",
        ["lut_file"] = "LUT-Datei",
        ["lut_file_desc"] = "3D LUT-Datei im CUBE oder PNG-Format (33x33 oder 64x64 Textur)",
        ["lut_strength"] = "LUT-Stärke",
        ["lut_strength_desc"] = "Stärke des LUT-Effekts",
        ["basic_presets"] = "--- GRUNDLEGENDE VOREINSTELLUNGEN ---",
        ["style_presets"] = "--- STIL-VOREINSTELLUNGEN ---",
        ["color_mood_presets"] = "--- FARBSTIMMUNG-VOREINSTELLUNGEN ---",
        ["era_presets"] = "--- ÄRA-VOREINSTELLUNGEN ---",
        ["creative_presets"] = "--- KREATIVE VOREINSTELLUNGEN ---",
        ["neo_noir"] = "Neo Noir",
        ["cyberpunk"] = "Cyberpunk",
        ["retro_film"] = "Retro Film",
        ["teal_orange"] = "Teal & Orange",
        ["dreamy_bloom"] = "Traumhafter Bloom",
        ["crisp_clarity"] = "Klare Schärfe",
        ["horror_atmosphere"] = "Horror-Atmosphäre",
        ["pastel_dreams"] = "Pastell-Träume",
        ["game_stream"] = "Spiele-Stream",
        ["analog_vhs"] = "Analog VHS"
    }
}

-- Schaltet Debug-Logs ein/aus
local DEBUG = false

-- Kompatible Zeitfunktion (Sekunden als float)
local function get_time_s()
    if obs.os_gettime_s then
        return obs.os_gettime_s()
    elseif obs.os_gettime_ns then
        return obs.os_gettime_ns() / 1e9
    else
        return os.clock()
    end
end

-- Shader mit erweiterten Funktionen (Vignette)
local shader_code = [[
uniform float4x4 ViewProj;
uniform texture2d image;
uniform float4 buffer_size;   // x = width, y = height, z = 1/width, w = 1/height

// OBS Studio übernimmt die Konvertierung von HLSL zu GLSL/Metal automatisch

// Constant Buffer mit explizitem Memory-Layout
// Alle Uniforms in logische Gruppen mit 16-Byte-Alignment

// Grundlegende Korrekturen
uniform float exposure;
uniform float contrast;
uniform float brightness;
uniform float padding1;  // Padding für 16-Byte-Alignment

uniform float highlights;
uniform float shadows;
uniform float whites;
uniform float blacks;

// Ausbleich-Effekte
uniform float highlight_fade;
uniform float shadow_fade;
uniform float black_lift;
uniform float padding2;  // Padding für 16-Byte-Alignment

// Weißabgleich
uniform float temperature;
uniform float tint;
uniform float padding3;
uniform float padding4;  // Padding für 16-Byte-Alignment

// Farbe
uniform float saturation;
uniform float vibrance;
uniform float padding5;
uniform float padding6;  // Padding für 16-Byte-Alignment

// Vignette-Effekt
uniform float vignette_amount;
uniform float vignette_radius;
uniform float vignette_feather;
uniform float vignette_shape;  // 0.0 = Kreis, 1.0 = Mehr rechteckig

// Erweiterte Effekte
uniform float sharpen_amount;      // 0-1  USM-Stärke
uniform float bloom_intensity;     // 0-1
uniform float halation;            // 0-1
uniform float lut_strength;        // 0-1
uniform float4 split_shadow;       // rgb + sat
uniform float4 split_highlight;    // rgb + sat
uniform texture3d lut_tex;         // 3D-LUT (32³, linear)

// 3D-Sampler für die LUT-Textur
sampler_state lut_sampler
{
    Filter   = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
    AddressW = Clamp;   // 3D braucht alle drei Achsen
};

// WICHTIG: Farbräder IMMER am Ende des Constant Buffers!
// Keine weiteren Uniforms nach diesen definieren!
uniform float4 shadows_color;    // RGB-Komponenten als Vektor (.rgb verwenden, w ignorieren)
uniform float4 midtones_color;   // RGB-Komponenten als Vektor (.rgb verwenden, w ignorieren)
uniform float4 highlights_color; // RGB-Komponenten als Vektor (.rgb verwenden, w ignorieren)

// 2D-Sampler für das Eingangstextur-“image”
sampler_state imageSampler
{
    Filter   = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
    AddressW = Clamp;   // wird bei 2D ignoriert, schadet aber nicht
};

// OBS erzeugt automatisch einen Sampler namens 'imageSampler'

struct VertDataIn {
    float4 pos : POSITION;
    float2 uv  : TEXCOORD0;
};

struct VertDataOut {
    float4 pos : POSITION;
    float2 uv  : TEXCOORD0;
};

VertDataOut VSDefault(VertDataIn v_in)
{
    VertDataOut vert_out;
    vert_out.pos = mul(float4(v_in.pos.xyz, 1.0), ViewProj);
    vert_out.uv  = v_in.uv;
    return vert_out;
}

// Hilfsfunktion für Kontrast
float3 apply_contrast(float3 color, float contrast_value) {
    float3 result = color;
    result = (result - 0.5) * (1.0 + contrast_value) + 0.5;
    return result;
}

// Tone-Mapping-Funktionen
float3 tone_map_log(float3 c, float offset) {
    return c * pow(2.0, offset);
}

// S-Curve für weichen Kontrast
float3 s_curve(float3 c, float k) {
    float a = 1.0 + k;
    return saturate(pow(c, 1.0 / a) * a);
}

// Selektive Farbton-Rotation
float3 hue_rotate(float3 c, float3 shift) {
    // YIQ-Basisrotation pro Kanal
    const float3x3 R = float3x3(1,0,0, 0,0.707,-0.707, 0,0.707,0.707);
    const float3x3 G = float3x3(0.707,0,0.707, 0,1,0, -0.707,0,0.707);
    const float3x3 B = float3x3(0.707,-0.707,0, 0.707,0.707,0, 0,0,1);
    return mul(R, c) * (1+shift.r) +
           mul(G, c) * (1+shift.g) +
           mul(B, c) * (1+shift.b);
}

// Split-Toning anwenden
float3 apply_split_tone(float3 c, float luma, float4 sh, float4 hi) {
    float wS = saturate(1-luma*2);
    float wH = saturate((luma-0.5)*2);
    c = lerp(c, saturate(c+sh.rgb), sh.a*wS);
    c = lerp(c, saturate(c+hi.rgb), hi.a*wH);
    return c;
}

// Unsharp Mask für Schärfe
float3 usm(float2 uv, float3 base, float amt) {
    float2 px = float2(buffer_size.z, buffer_size.w);   // 1/width, 1/height
    float3 blur = (image.Sample(imageSampler, uv+px).rgb + image.Sample(imageSampler, uv-px).rgb +
                   image.Sample(imageSampler, uv+float2(px.x,-px.y)).rgb +
                   image.Sample(imageSampler, uv+float2(-px.x,px.y)).rgb) * 0.25;
    return saturate(base + (base-blur)*amt);
}

// Bloom-Sampling
float3 bloom_sample(float2 uv) {
    float2 px = float2(buffer_size.z, buffer_size.w) * 4;   // (1/width, 1/height) * 4
    return (image.Sample(imageSampler, uv).rgb +
            image.Sample(imageSampler, uv+px).rgb +
            image.Sample(imageSampler, uv-px).rgb) / 3;
}

// Hilfsfunktion für Farbtemperatur
float3 apply_temperature(float3 color, float temp, float tint) {
    // Einfache Annäherung an Temperatur: Rot und Blau anpassen
    float3 warm = float3(0.1, 0.0, -0.1);
    float3 tint_color = float3(0.0, tint * 0.1, 0.0);
    
    return saturate(color + temp * warm + tint_color);
}

// Hilfsfunktion für Sättigung
float3 apply_saturation(float3 color, float sat) {
    // Sättigung anpassen
    float gray = dot(color, float3(0.2126, 0.7152, 0.0722));
    return lerp(float3(gray, gray, gray), color, 1.0 + sat);
}

// Hilfsfunktion für Lebendigkeit
float3 apply_vibrance(float3 color, float vibrance_value) {
    float luminance = dot(color, float3(0.299, 0.587, 0.114));
    float maximum = max(max(color.r, color.g), color.b);
    float minimum = min(min(color.r, color.g), color.b);
    float saturation = (maximum - minimum) / max(maximum, 0.0001);
    
    return lerp(float3(luminance, luminance, luminance), color, 1.0 + (vibrance_value * (1.0 - saturation)));
}

// Vignette anwenden
float3 apply_vignette(float3 color, float2 uv, float amount, float radius, float feather, float shape) {
    float2 center = float2(0.5, 0.5);
    
    // Anpassbare Form zwischen Kreis und mehr rechteckiger Form
    float2 d = abs(uv - center);
    // Bei 0.0 normal euklidische Distanz (Kreis)
    // Bei 1.0 mehr zu Manhattan-Distanz (Rechteckiger)
    float dist = lerp(
        length(d),                       // Kreis
        sqrt(d.x*d.x*1.5 + d.y*d.y*0.5), // Horizontales Oval
        shape
    );
    
    // Vignette stärke berechnen
    float vignette = smoothstep(radius, radius - feather, dist);
    
    // Auf Bild anwenden
    return color * lerp(1.0, vignette, amount);
}

// Film Grain wurde entfernt - es verursachte "tickendes" Verhalten


// Berechnet die Gewichtung für die verschiedenen Tonwertbereiche
float3 calculate_weights(float luma) {
    // Schatten: Abnehmende Gewichtung von Schwarz bis zu den Mitteltönen
    float shadow_weight = 1.0 - smoothstep(0.0, 0.5, luma);
    
    // Lichter: Zunehmende Gewichtung von den Mitteltönen bis zu Weiß
    float highlight_weight = smoothstep(0.5, 1.0, luma);
    
    // Mitteltöne: Im mittleren Bereich am stärksten
    float midtone_weight = 1.0 - shadow_weight - highlight_weight;
    
    return float3(shadow_weight, midtone_weight, highlight_weight);
}

// Tonwert-basierte Farbkorrektur anwenden
float3 apply_color_balance(float3 color, float4 shadows_color, float4 midtones_color, float4 highlights_color) {
    float luma = dot(color, float3(0.2126, 0.7152, 0.0722));
    float3 weights = calculate_weights(luma);
    
    // Additive Farbmischung mit Gewichtung je nach Tonwertbereich
    float3 result = color;
    result += shadows_color.rgb * weights.x * 0.5;     // 50% Stärke für Schatten
    result += midtones_color.rgb * weights.y * 0.3;    // 30% Stärke für Mitteltöne
    result += highlights_color.rgb * weights.z * 0.5;  // 50% Stärke für Lichter
    
    return saturate(result); // Sicherstellen, dass die Farben im gültigen Bereich bleiben
}

float4 PSDefault(VertDataOut v_in) : TARGET
{
    float4 color = image.Sample(imageSampler, v_in.uv);
    float3 result = color.rgb;
    float3 orig = result; // Original für Referenz speichern
    
    // Belichtung
    result *= pow(2.0, exposure);
    
    // Lichterwerte und Schatten
    if (highlights != 0.0) {
        float3 highlight_mask = smoothstep(0.5, 1.0, result);
        result = lerp(result, result * (1.0 + highlights), highlight_mask);
    }
    
    if (shadows != 0.0) {
        float3 shadow_mask = 1.0 - smoothstep(0.0, 0.5, result);
        result = lerp(result, result * (1.0 + shadows), shadow_mask);
    }
    
    // Weißpunkt und Schwarzpunkt
    if (whites != 0.0) {
        float3 whites_mask = smoothstep(0.7, 1.0, result);
        result = lerp(result, result + whites * 0.5, whites_mask);
    }
    
    if (blacks != 0.0) {
        float3 blacks_mask = 1.0 - smoothstep(0.0, 0.3, result);
        result = lerp(result, result + blacks * 0.5, blacks_mask);
    }
    
    // Schwarzwert-Anhebung (Black Lift)
    if (black_lift > 0.0) {
        float lift_amount = black_lift * 0.5; // Maximale Anhebung von 0.5
        float3 lift_mask = 1.0 - smoothstep(0.0, 0.4, result);
        result = lerp(result, result + lift_amount, lift_mask);
    }
    
    // Helligkeit
    result = saturate(result + brightness);
    
    // Kontrast
    result = apply_contrast(result, contrast);
    
    // Farbtemperatur und Tint
    result = apply_temperature(result, temperature, tint);
    
    // Highlight/Shadow Ausbleichen
    float luma = dot(result, float3(0.2126, 0.7152, 0.0722));
    
    // Lichter ausbleichen
    if (highlight_fade > 0.0) {
        float highlight_mask = smoothstep(0.7, 1.0, luma);
        result = lerp(result, float3(1.0, 1.0, 1.0), highlight_mask * highlight_fade);
    }
    
    // Schatten ausbleichen (aufhellen)
    if (shadow_fade > 0.0) {
        float shadow_mask = 1.0 - smoothstep(0.0, 0.3, luma);
        result = lerp(result, float3(1.0, 1.0, 1.0), shadow_mask * shadow_fade);
    }
    
    // Farbräder/Farbbalance anwenden
    // Die Farbvektoren werden direkt verwendet (keine Konvertierung nötig)
    result = apply_color_balance(result, shadows_color, midtones_color, highlights_color);
    
    // 1. Split-Toning (nach Farbrädern)
    luma = dot(result, float3(0.2126, 0.7152, 0.0722));
    result = apply_split_tone(result, luma, split_shadow, split_highlight);
    
    // 2. Master Sättigung und Lebendigkeit
    result = apply_saturation(result, saturation);
    result = apply_vibrance(result, vibrance);
    
    // 3. Bloom-Effekt
    if (bloom_intensity > 0.001) {
        float3 bloom = bloom_sample(v_in.uv);
        result = lerp(result, result + bloom, bloom_intensity);
    }
    
    // 4. Halation (weicher roter Schimmer auf Highlights)
    if (halation > 0.001) {
        float redGlow = bloom_sample(v_in.uv).r;
        result += float3(redGlow*0.1, redGlow*0.04, redGlow*0.02) * halation;
    }
    
    // 5. Lokale Schärfe
    if (sharpen_amount > 0.001) {
        result = usm(v_in.uv, result, sharpen_amount);
    }
    
    // 6. 3D LUT anwenden
    if (lut_strength > 0.001) {
        float3 lutCol = lut_tex.Sample(lut_sampler, result).rgb;
        result = lerp(result, lutCol, lut_strength);
    }
    
    // Vignette anwenden
    if (vignette_amount > 0.0) {
        result = apply_vignette(result, v_in.uv, vignette_amount, vignette_radius, vignette_feather, vignette_shape);
    }
    
    return float4(result, color.a);
}

technique Draw
{
    pass
    {
        vertex_shader = VSDefault(v_in);
        pixel_shader  = PSDefault(v_in);
    }
}
]]

-- Sichere Setter-Funktionen für Shader-Parameter
local function safe_float(param, val)
    if param then
        -- Versuche den Parameter zu setzen, ignoriere Fehler
        pcall(function() obs.gs_effect_set_float(param, val) end)
    end
end

-- Korrekte set_vec3 Funktion - verwendet ein OBS-Vektor-Objekt
local function set_vec3(param, x, y, z)
    if not param then return end
    
    -- OBS-Container anlegen
    local v = obs.vec4()
    v.x = x
    v.y = y
    v.z = z
    v.w = 0.0  -- Padding / wird vom Shader ignoriert
    
    -- Vektor-Objekt übergeben
    pcall(function()
        obs.gs_effect_set_vec4(param, v)
    end)
end

-- Funktion für Split-Toning-Parameter (float4 mit RGB + Saturation)
local function set_split(param, r, g, b, sat)
    if not param then return end
    
    -- OBS-Container anlegen
    local v = obs.vec4()
    v.x = r or 0.0
    v.y = g or 0.0
    v.z = b or 0.0
    v.w = sat or 0.0  -- Saturation in w-Komponente
    
    -- Vektor-Objekt übergeben
    pcall(function()
        obs.gs_effect_set_vec4(param, v)
    end)
end

-- Funktion für buffer_size (float4 mit width, height, 1/width, 1/height)
local function set_buffer_size(param, width, height)
    if not param then return end
    
    -- OBS-Container anlegen
    local v = obs.vec4()
    v.x = width or 1.0            -- width
    v.y = height or 1.0           -- height
    v.z = 1.0 / (width or 1.0)    -- 1/width
    v.w = 1.0 / (height or 1.0)   -- 1/height
    
    -- Vektor-Objekt übergeben
    pcall(function()
        obs.gs_effect_set_vec4(param, v)
    end)
end

-- Parameter an den Shader übergeben
function set_shader_params(data)
    if not data or not data.params or not data.effect then return end
    
    -- Basis-Parameter setzen
    if data.params.exposure then 
        if data.last_exposure ~= data.exposure then
            safe_float(data.params.exposure, data.exposure)
            data.last_exposure = data.exposure
        end
    end
    if data.params.contrast then 
        if data.last_contrast ~= data.contrast then
            safe_float(data.params.contrast, data.contrast)
            data.last_contrast = data.contrast
        end
    end
    if data.params.brightness then 
        if data.last_brightness ~= data.brightness then
            safe_float(data.params.brightness, data.brightness)
            data.last_brightness = data.brightness
        end
    end
    if data.params.highlights then 
        if data.last_highlights ~= data.highlights then
            safe_float(data.params.highlights, data.highlights)
            data.last_highlights = data.highlights
        end
    end
    if data.params.shadows then 
        if data.last_shadows ~= data.shadows then
            safe_float(data.params.shadows, data.shadows)
            data.last_shadows = data.shadows
        end
    end
    if data.params.whites then 
        if data.last_whites ~= data.whites then
            safe_float(data.params.whites, data.whites)
            data.last_whites = data.whites
        end
    end
    if data.params.blacks then 
        if data.last_blacks ~= data.blacks then
            safe_float(data.params.blacks, data.blacks)
            data.last_blacks = data.blacks
        end
    end
    if data.params.temperature then 
        if data.last_temperature ~= data.temperature then
            safe_float(data.params.temperature, data.temperature)
            data.last_temperature = data.temperature
        end
    end
    if data.params.tint then 
        if data.last_tint ~= data.tint then
            safe_float(data.params.tint, data.tint)
            data.last_tint = data.tint
        end
    end
    if data.params.saturation then 
        if data.last_saturation ~= data.saturation then
            safe_float(data.params.saturation, data.saturation)
            data.last_saturation = data.saturation
        end
    end
    if data.params.vibrance then 
        if data.last_vibrance ~= data.vibrance then
            safe_float(data.params.vibrance, data.vibrance)
            data.last_vibrance = data.vibrance
        end
    end
    if data.params.vignette_amount then 
        if data.last_vignette_amount ~= data.vignette_amount then
            safe_float(data.params.vignette_amount, data.vignette_amount)
            data.last_vignette_amount = data.vignette_amount
        end
    end
    if data.params.vignette_radius then 
        if data.last_vignette_radius ~= data.vignette_radius then
            safe_float(data.params.vignette_radius, data.vignette_radius)
            data.last_vignette_radius = data.vignette_radius
        end
    end
    if data.params.vignette_feather then 
        if data.last_vignette_feather ~= data.vignette_feather then
            safe_float(data.params.vignette_feather, data.vignette_feather)
            data.last_vignette_feather = data.vignette_feather
        end
    end
    if data.params.vignette_shape then 
        if data.last_vignette_shape ~= data.vignette_shape then
            safe_float(data.params.vignette_shape, data.vignette_shape)
            data.last_vignette_shape = data.vignette_shape
        end
    end
    if data.params.highlight_fade then 
        if data.last_highlight_fade ~= data.highlight_fade then
            safe_float(data.params.highlight_fade, data.highlight_fade)
            data.last_highlight_fade = data.highlight_fade
        end
    end
    if data.params.shadow_fade then 
        if data.last_shadow_fade ~= data.shadow_fade then
            safe_float(data.params.shadow_fade, data.shadow_fade)
            data.last_shadow_fade = data.shadow_fade
        end
    end   
    if data.params.black_lift then 
        if data.last_black_lift ~= data.black_lift then
            safe_float(data.params.black_lift, data.black_lift)
            data.last_black_lift = data.black_lift
        end
    end
    
    -- Farbrad-Parameter als float3-Vektoren setzen
    if data.params.shadows_color then
        set_vec3(data.params.shadows_color, data.shadows_color_r or 0, data.shadows_color_g or 0, data.shadows_color_b or 0)
    end
    
    if data.params.midtones_color then
        set_vec3(data.params.midtones_color, data.midtones_color_r or 0, data.midtones_color_g or 0, data.midtones_color_b or 0)
    end
    
    if data.params.highlights_color then
        set_vec3(data.params.highlights_color, data.highlights_color_r or 0, data.highlights_color_g or 0, data.highlights_color_b or 0)
    end
    
    -- Erweiterte Effekte
    if data.params.sharpen_amount then
        safe_float(data.params.sharpen_amount, data.sharpen or 0)
    end
    
    if data.params.bloom_intensity then
        safe_float(data.params.bloom_intensity, data.bloom or 0)
    end
    
    if data.params.halation then
        safe_float(data.params.halation, data.halation or 0)
    end
    
    if data.params.lut_strength then
        safe_float(data.params.lut_strength, data.lut_strength or 0)
    end
    
    -- Split-Toning (als vec4 mit RGB + Saturation)
    if data.params.split_shadow then
        set_split(data.params.split_shadow, data.ss_r or 0, data.ss_g or 0, data.ss_b or 0, data.ss_sat or 0)
    end
    
    if data.params.split_highlight then
        set_split(data.params.split_highlight, data.sh_r or 0, data.sh_g or 0, data.sh_b or 0, data.sh_sat or 0)
    end
    
    -- 3D-LUT Textur (einmal nach Load)
    if data.params.lut_tex and data.lut_tex and not data.lut_bound then
        pcall(function() obs.gs_effect_set_texture(data.params.lut_tex, data.lut_tex) end)
        data.lut_bound = true
    end
    
    -- Buffer-Size als vec4 setzen (width, height, 1/width, 1/height)
    if data.params.buffer_size and data.width and data.height then
        set_buffer_size(data.params.buffer_size, data.width, data.height)
    end
    
    -- Nur für die Preview-Textur explizit setzen
    if data.target_texture == nil and data.params.image and data.preview_texture then
        obs.gs_effect_set_texture(data.params.image, data.preview_texture)
    end
end

-- Hilfsfunktion für Debug-Logging
local function log_debug(message)
    if DEBUG then
        obs.blog(obs.LOG_INFO, "[Lumetric] " .. message)
    end
end

-- Übersetzungsfunktion
function _(key)
    local lang = obs.obs_get_locale()
    if not translations[lang] then
        lang = "en-US"
    end
    if translations[lang] and translations[lang][key] then
        return translations[lang][key]
    end
    return key
end

-- Skriptbeschreibung
function script_description()
    return _("lumetric_corrector") .. " - " .. "v2.0.0" .. "\n\n" ..
    "Professional color grading filter for OBS Studio. Usage:\n" ..
    "1. Add as a filter to any source: Right-click source > Filters > + > Lumetric Corrector\n" ..
    "2. Adjust parameters or select one of 35+ presets\n" ..
    "3. Use basic corrections, color wheels, split-toning, and creative effects\n" ..
    "4. Optional: Load a 3D LUT file for advanced color grading\n\n" ..
    "New in v2.0: Enhanced shader compatibility, split-toning, bloom, halation, and 10 new creative presets."
end

-- Filtername für OBS
source_info.get_name = function()
    return _("lumetric_corrector")
end

-- Hilfsfunktion zum Setzen der Render-Größe
local function set_render_size(data)
    if not data then return end
    
    local target = obs.obs_filter_get_target(data.source)
    local width, height = 0, 0
    
    if target ~= nil then
        width = obs.obs_source_get_base_width(target)
        height = obs.obs_source_get_base_height(target)
    end
    
    if (width == 0 or height == 0) then
        width, height = 200, 200
    end
    
    if data.width ~= width or data.height ~= height then
        data.width = width
        data.height = height
        log_debug("Rendergröße aktualisiert: " .. tostring(width) .. "x" .. tostring(height))
    end
end

-- LUT-Textur laden
local function load_lut(path)
    if not path or path == "" then return nil end
    local tex = obs.gs_texture_create_from_file(path)
    if not tex then
        obs.blog(obs.LOG_ERROR, "[Lumetric] LUT-Load failed: "..path)
    end
    return tex
end

-- Funktionen für Vorschaugröße
source_info.get_width = function(data)
    return data.width or 0
end

source_info.get_height = function(data)
    return data.height or 0
end

-- Aktualisierung vor dem Rendern
source_info.video_tick = function(data, seconds)
    if not data then return end
    
    -- Aktualisiere die Größe
    set_render_size(data)
end

-- Hilfsfunktionen für die vordefinierten Presets
local function apply_preset(data, preset_type)
    -- Validierung der Eingabeparameter
    if not data then
        log_debug("FEHLER: apply_preset wurde mit ungültigem data-Objekt aufgerufen")
        return false
    end
    
    -- Standard-Werte für alle Parameter
    local settings = obs.obs_data_create()
    if not settings then
        log_debug("FEHLER: Konnte Settings-Objekt nicht erstellen")
        return false
    end
    
    -- Aktuelle Werte aus data in settings kopieren, um eine korrekte Aktualisierung zu gewährleisten
    for key, value in pairs(data) do
        if type(value) == "number" then
            obs.obs_data_set_double(settings, key, value)
        elseif type(value) == "string" then
            obs.obs_data_set_string(settings, key, value)
        elseif type(value) == "boolean" then
            obs.obs_data_set_bool(settings, key, value)
        end
    end
    
    -- Preset-spezifische Einstellungen
    if preset_type == "neutral" then
        -- Neutrales Preset (Standard-Werte)
        obs.obs_data_set_double(settings, "exposure", 0.0)
        obs.obs_data_set_double(settings, "contrast", 0.0)
        obs.obs_data_set_double(settings, "brightness", 0.0)
        obs.obs_data_set_double(settings, "highlights", 0.0)
        obs.obs_data_set_double(settings, "shadows", 0.0)
        obs.obs_data_set_double(settings, "whites", 0.0)
        obs.obs_data_set_double(settings, "blacks", 0.0)
        obs.obs_data_set_double(settings, "temperature", 0.0)
        obs.obs_data_set_double(settings, "tint", 0.0)
        obs.obs_data_set_double(settings, "saturation", 0.0)
        obs.obs_data_set_double(settings, "vibrance", 0.0)
        obs.obs_data_set_double(settings, "vignette_amount", 0.0)
        obs.obs_data_set_double(settings, "shadows_color_r", 0.0)
        obs.obs_data_set_double(settings, "shadows_color_g", 0.0)
        obs.obs_data_set_double(settings, "shadows_color_b", 0.0)
        obs.obs_data_set_double(settings, "midtones_color_r", 0.0)
        obs.obs_data_set_double(settings, "midtones_color_g", 0.0)
        obs.obs_data_set_double(settings, "midtones_color_b", 0.0)
        obs.obs_data_set_double(settings, "highlights_color_r", 0.0)
        obs.obs_data_set_double(settings, "highlights_color_g", 0.0)
        obs.obs_data_set_double(settings, "highlights_color_b", 0.0)
    elseif preset_type == "warm" then
        obs.obs_data_set_double(settings, "temperature", 0.2)
        obs.obs_data_set_double(settings, "tint", -0.05)
    elseif preset_type == "cool" then
        obs.obs_data_set_double(settings, "temperature", -0.2)
        obs.obs_data_set_double(settings, "tint", 0.05)
    elseif preset_type == "contrast_boost" then
        obs.obs_data_set_double(settings, "contrast", 0.15)
        obs.obs_data_set_double(settings, "highlights", 0.1)
        obs.obs_data_set_double(settings, "shadows", -0.1)
        obs.obs_data_set_double(settings, "blacks", -0.05)
    elseif preset_type == "contrast_reduce" then
        obs.obs_data_set_double(settings, "contrast", -0.1)
        obs.obs_data_set_double(settings, "highlights", -0.05)
        obs.obs_data_set_double(settings, "shadows", 0.05)
    elseif preset_type == "bright" then
        obs.obs_data_set_double(settings, "exposure", 0.1)
        obs.obs_data_set_double(settings, "highlights", 0.05)
        obs.obs_data_set_double(settings, "shadows", 0.1)
    elseif preset_type == "dark" then
        obs.obs_data_set_double(settings, "exposure", -0.1)
        obs.obs_data_set_double(settings, "shadows", -0.05)
        obs.obs_data_set_double(settings, "blacks", -0.05)
    elseif preset_type == "vintage" then
        obs.obs_data_set_double(settings, "temperature", 0.15)
        obs.obs_data_set_double(settings, "contrast", 0.1)
        obs.obs_data_set_double(settings, "saturation", -0.15)
        obs.obs_data_set_double(settings, "shadows_color_r", 0.05)
        obs.obs_data_set_double(settings, "shadows_color_b", -0.1)
        obs.obs_data_set_double(settings, "highlights_color_r", 0.1)
        obs.obs_data_set_double(settings, "highlights_color_b", -0.05)
        obs.obs_data_set_double(settings, "vignette_amount", 0.2)
    elseif preset_type == "bw" then
        obs.obs_data_set_double(settings, "saturation", -1.0)
        obs.obs_data_set_double(settings, "contrast", 0.1)
        obs.obs_data_set_double(settings, "highlights", 0.05)
        obs.obs_data_set_double(settings, "shadows", -0.05)
        obs.obs_data_set_double(settings, "blacks", -0.05)
    elseif preset_type == "bw_high_contrast" then
        obs.obs_data_set_double(settings, "saturation", -1.0)
        obs.obs_data_set_double(settings, "contrast", 0.2)
        obs.obs_data_set_double(settings, "highlights", 0.1)
        obs.obs_data_set_double(settings, "shadows", -0.1)
        obs.obs_data_set_double(settings, "blacks", -0.1)
    elseif preset_type == "sepia" then
        obs.obs_data_set_double(settings, "saturation", -0.8)
        obs.obs_data_set_double(settings, "temperature", 0.3)
        obs.obs_data_set_double(settings, "contrast", 0.05)
        obs.obs_data_set_double(settings, "highlights_color_r", 0.1)
        obs.obs_data_set_double(settings, "highlights_color_g", 0.05)
        obs.obs_data_set_double(settings, "shadows_color_r", 0.1)
        obs.obs_data_set_double(settings, "shadows_color_g", 0.05)
    elseif preset_type == "filmic" then
        obs.obs_data_set_double(settings, "contrast", 0.15)
        obs.obs_data_set_double(settings, "highlights", -0.05)
        obs.obs_data_set_double(settings, "shadows", 0.05)
        obs.obs_data_set_double(settings, "saturation", -0.05)
        obs.obs_data_set_double(settings, "vignette_amount", 0.1)
        obs.obs_data_set_double(settings, "vignette_feather", 0.7)
    elseif preset_type == "cinematic" then
        obs.obs_data_set_double(settings, "contrast", 0.2)
        obs.obs_data_set_double(settings, "highlights", -0.1)
        obs.obs_data_set_double(settings, "shadows", 0.05)
        obs.obs_data_set_double(settings, "saturation", -0.1)
        obs.obs_data_set_double(settings, "midtones_color_b", 0.05)
        obs.obs_data_set_double(settings, "shadows_color_b", 0.1)
        obs.obs_data_set_double(settings, "vignette_amount", 0.15)
        obs.obs_data_set_double(settings, "vignette_feather", 0.8)
    elseif preset_type == "dramatic" then
        obs.obs_data_set_double(settings, "contrast", 0.25)
        obs.obs_data_set_double(settings, "highlights", -0.1)
        obs.obs_data_set_double(settings, "shadows", -0.15)
        obs.obs_data_set_double(settings, "blacks", -0.1)
        obs.obs_data_set_double(settings, "saturation", 0.1)
        obs.obs_data_set_double(settings, "vignette_amount", 0.25)
        obs.obs_data_set_double(settings, "vignette_radius", 0.7)
    elseif preset_type == "vibrant" then
        obs.obs_data_set_double(settings, "saturation", 0.2)
        obs.obs_data_set_double(settings, "vibrance", 0.15)
        obs.obs_data_set_double(settings, "contrast", 0.1)
        obs.obs_data_set_double(settings, "highlights", 0.05)
    elseif preset_type == "muted" then
        obs.obs_data_set_double(settings, "saturation", -0.15)
        obs.obs_data_set_double(settings, "vibrance", -0.1)
        obs.obs_data_set_double(settings, "contrast", -0.05)
    elseif preset_type == "warm_contrast" then
        obs.obs_data_set_double(settings, "temperature", 0.15)
        obs.obs_data_set_double(settings, "contrast", 0.15)
        obs.obs_data_set_double(settings, "highlights", 0.05)
        obs.obs_data_set_double(settings, "shadows", -0.05)
    elseif preset_type == "cool_contrast" then
        obs.obs_data_set_double(settings, "temperature", -0.15)
        obs.obs_data_set_double(settings, "contrast", 0.15)
        obs.obs_data_set_double(settings, "highlights", 0.05)
        obs.obs_data_set_double(settings, "shadows", -0.05)
    elseif preset_type == "shadows_blue" then
        obs.obs_data_set_double(settings, "shadows_color_b", 0.15)
    elseif preset_type == "shadows_green" then
        obs.obs_data_set_double(settings, "shadows_color_g", 0.15)
    elseif preset_type == "highlights_warm" then
        obs.obs_data_set_double(settings, "highlights_color_r", 0.1)
        obs.obs_data_set_double(settings, "highlights_color_g", 0.05)
    elseif preset_type == "sunset" then
        obs.obs_data_set_double(settings, "temperature", 0.2)
        obs.obs_data_set_double(settings, "highlights_color_r", 0.15)
        obs.obs_data_set_double(settings, "highlights_color_g", 0.05)
        obs.obs_data_set_double(settings, "shadows_color_b", 0.1)
    elseif preset_type == "moonlight" then
        obs.obs_data_set_double(settings, "temperature", -0.3)
        obs.obs_data_set_double(settings, "exposure", -0.1)
        obs.obs_data_set_double(settings, "highlights_color_b", 0.1)
        obs.obs_data_set_double(settings, "midtones_color_b", 0.05)
        obs.obs_data_set_double(settings, "shadows", -0.1)
        obs.obs_data_set_double(settings, "contrast", 0.1)
    elseif preset_type == "vivid_warm" then
        obs.obs_data_set_double(settings, "temperature", 0.15)
        obs.obs_data_set_double(settings, "saturation", 0.15)
        obs.obs_data_set_double(settings, "vibrance", 0.1)
        obs.obs_data_set_double(settings, "contrast", 0.1)
    -- Neue kreative Presets mit erweiterten Funktionen
    elseif preset_type == "neo_noir" then
        -- Dramatisches Schwarz-Weiß mit blauem Split-Toning und Vignette
        obs.obs_data_set_double(settings, "saturation", -0.9)
        obs.obs_data_set_double(settings, "contrast", 0.25)
        obs.obs_data_set_double(settings, "blacks", -0.15)
        obs.obs_data_set_double(settings, "vignette_amount", 0.4)
        obs.obs_data_set_double(settings, "vignette_feather", 0.6)
        obs.obs_data_set_double(settings, "ss_b", 0.2)  -- Blaue Schatten
        obs.obs_data_set_double(settings, "ss_sat", 0.3) -- Mittlere Sättigung
        obs.obs_data_set_double(settings, "sharpen", 0.2) -- Leichte Schärfe
    elseif preset_type == "cyberpunk" then
        -- Futuristischer Look mit Neonfarben und Bloom
        obs.obs_data_set_double(settings, "contrast", 0.2)
        obs.obs_data_set_double(settings, "blacks", -0.1)
        obs.obs_data_set_double(settings, "vibrance", 0.3)
        obs.obs_data_set_double(settings, "sh_b", 0.3)  -- Blaue Lichter
        obs.obs_data_set_double(settings, "sh_sat", 0.5) -- Starke Sättigung
        obs.obs_data_set_double(settings, "ss_r", 0.2)  -- Rote Schatten
        obs.obs_data_set_double(settings, "ss_sat", 0.4) -- Starke Sättigung
        obs.obs_data_set_double(settings, "bloom", 0.4)  -- Starker Bloom
        obs.obs_data_set_double(settings, "halation", 0.2) -- Mittlere Halation
    elseif preset_type == "retro_film" then
        -- Vintage-Filmemulation mit Halation und Körnigkeit
        obs.obs_data_set_double(settings, "temperature", 0.1)
        obs.obs_data_set_double(settings, "saturation", -0.2)
        obs.obs_data_set_double(settings, "contrast", 0.15)
        obs.obs_data_set_double(settings, "highlights", -0.1)
        obs.obs_data_set_double(settings, "shadows", 0.05)
        obs.obs_data_set_double(settings, "vignette_amount", 0.25)
        obs.obs_data_set_double(settings, "halation", 0.4)  -- Starke Halation für Filmglühen
        obs.obs_data_set_double(settings, "sh_r", 0.15)  -- Rötliche Lichter
        obs.obs_data_set_double(settings, "sh_sat", 0.3)  -- Mittlere Sättigung
    elseif preset_type == "teal_orange" then
        -- Beliebter Filmkontrast mit Split-Toning
        obs.obs_data_set_double(settings, "contrast", 0.2)
        obs.obs_data_set_double(settings, "vibrance", 0.1)
        obs.obs_data_set_double(settings, "sh_r", 0.25)  -- Orange Lichter
        obs.obs_data_set_double(settings, "sh_g", 0.1)   
        obs.obs_data_set_double(settings, "sh_sat", 0.4) -- Starke Sättigung
        obs.obs_data_set_double(settings, "ss_b", 0.25)  -- Türkise Schatten
        obs.obs_data_set_double(settings, "ss_g", 0.1)   
        obs.obs_data_set_double(settings, "ss_sat", 0.4) -- Starke Sättigung
        obs.obs_data_set_double(settings, "sharpen", 0.15) -- Leichte Schärfe
    elseif preset_type == "dreamy_bloom" then
        -- Weicher, träumerischer Look mit Bloom und Halation
        obs.obs_data_set_double(settings, "contrast", -0.05)
        obs.obs_data_set_double(settings, "highlights", 0.1)
        obs.obs_data_set_double(settings, "shadows", 0.1)
        obs.obs_data_set_double(settings, "saturation", 0.05)
        obs.obs_data_set_double(settings, "bloom", 0.5)  -- Starker Bloom
        obs.obs_data_set_double(settings, "halation", 0.3) -- Mittlere Halation
        obs.obs_data_set_double(settings, "sh_r", 0.1)  -- Leicht warme Lichter
        obs.obs_data_set_double(settings, "sh_g", 0.05) 
        obs.obs_data_set_double(settings, "sh_sat", 0.2) -- Leichte Sättigung
    elseif preset_type == "crisp_clarity" then
        -- Scharfer, klarer Look mit Kontrast und Schärfe
        obs.obs_data_set_double(settings, "contrast", 0.2)
        obs.obs_data_set_double(settings, "highlights", -0.05)
        obs.obs_data_set_double(settings, "shadows", -0.05)
        obs.obs_data_set_double(settings, "blacks", -0.05)
        obs.obs_data_set_double(settings, "vibrance", 0.1)
        obs.obs_data_set_double(settings, "sharpen", 0.4) -- Starke Schärfe
        obs.obs_data_set_double(settings, "vignette_amount", 0.1)
    elseif preset_type == "horror_atmosphere" then
        -- Düsterer, bedrohlicher Look für Horror-Content
        obs.obs_data_set_double(settings, "temperature", -0.2)
        obs.obs_data_set_double(settings, "saturation", -0.3)
        obs.obs_data_set_double(settings, "contrast", 0.2)
        obs.obs_data_set_double(settings, "highlights", -0.1)
        obs.obs_data_set_double(settings, "shadows", -0.2)
        obs.obs_data_set_double(settings, "blacks", -0.15)
        obs.obs_data_set_double(settings, "vignette_amount", 0.4)
        obs.obs_data_set_double(settings, "vignette_feather", 0.5)
        obs.obs_data_set_double(settings, "ss_b", 0.15)  -- Bläuliche Schatten
        obs.obs_data_set_double(settings, "ss_sat", 0.2)  -- Leichte Sättigung
        obs.obs_data_set_double(settings, "sharpen", 0.15) -- Leichte Schärfe
    elseif preset_type == "pastel_dreams" then
        -- Weicher, pastellfarbener Look mit Split-Toning
        obs.obs_data_set_double(settings, "contrast", -0.1)
        obs.obs_data_set_double(settings, "highlights", 0.1)
        obs.obs_data_set_double(settings, "shadows", 0.1)
        obs.obs_data_set_double(settings, "saturation", -0.1)
        obs.obs_data_set_double(settings, "vibrance", 0.1)
        obs.obs_data_set_double(settings, "sh_r", 0.1)  -- Rosa Lichter
        obs.obs_data_set_double(settings, "sh_b", 0.1)  
        obs.obs_data_set_double(settings, "sh_sat", 0.3) -- Mittlere Sättigung
        obs.obs_data_set_double(settings, "ss_b", 0.15)  -- Bläuliche Schatten
        obs.obs_data_set_double(settings, "ss_sat", 0.3)  -- Mittlere Sättigung
        obs.obs_data_set_double(settings, "bloom", 0.2)  -- Leichter Bloom
    elseif preset_type == "game_stream" then
        -- Optimierter Look für Gaming-Streams mit Schärfe und Lebendigkeit
        obs.obs_data_set_double(settings, "contrast", 0.15)
        obs.obs_data_set_double(settings, "highlights", -0.05)
        obs.obs_data_set_double(settings, "shadows", 0.05)
        obs.obs_data_set_double(settings, "vibrance", 0.2)
        obs.obs_data_set_double(settings, "saturation", 0.1)
        obs.obs_data_set_double(settings, "sharpen", 0.3) -- Starke Schärfe für Details
        obs.obs_data_set_double(settings, "vignette_amount", 0.15)
        obs.obs_data_set_double(settings, "vignette_feather", 0.7)
    elseif preset_type == "analog_vhs" then
        -- Retro-VHS-Look mit Halation und Farbverschiebung
        obs.obs_data_set_double(settings, "saturation", 0.1)
        obs.obs_data_set_double(settings, "contrast", 0.1)
        obs.obs_data_set_double(settings, "highlights", -0.1)
        obs.obs_data_set_double(settings, "shadows", -0.05)
        obs.obs_data_set_double(settings, "halation", 0.5) -- Maximale Halation für VHS-Glühen
        obs.obs_data_set_double(settings, "sh_r", 0.1)  -- Rötliche Lichter
        obs.obs_data_set_double(settings, "sh_sat", 0.2) -- Leichte Sättigung
        obs.obs_data_set_double(settings, "ss_b", 0.1)  -- Bläuliche Schatten
        obs.obs_data_set_double(settings, "ss_sat", 0.2) -- Leichte Sättigung
    end
    
    -- Aktualisiere den Filter mit den neuen Einstellungen
    if data.source then
        log_debug("Preset " .. preset_type .. " wird angewendet")
        source_info.update(data, settings)
        obs.obs_source_update(data.source, settings)
        log_debug("Preset " .. preset_type .. " erfolgreich angewendet")
    else
        log_debug("FEHLER: data.source ist nicht definiert")
    end
    
    obs.obs_data_release(settings)
    return true
end

-- UI für Eigenschaften
source_info.get_properties = function(data)
    log_debug("get_properties wird aufgerufen")
    
    -- Prüfen, ob Daten vorhanden sind
    if not data then 
        log_debug("WARNUNG: data-Objekt in get_properties ist nil")
    end
    
    local props = obs.obs_properties_create()
    
    -- Presets
    local preset_group = obs.obs_properties_create()
    
    -- Liste der Presets
    local preset_list = obs.obs_properties_add_list(preset_group, "preset_select", _("select_preset"), 
                                   obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    
    -- Leere Option
    obs.obs_property_list_add_string(preset_list, "", "")
    
    -- Grundlegende Presets
    obs.obs_property_list_add_string(preset_list, _("basic_presets"), "separator_basic")
    obs.obs_property_list_add_string(preset_list, _("neutral"), "neutral")
    obs.obs_property_list_add_string(preset_list, _("warm"), "warm")
    obs.obs_property_list_add_string(preset_list, _("cool"), "cool")
    obs.obs_property_list_add_string(preset_list, _("bright"), "bright")
    obs.obs_property_list_add_string(preset_list, _("dark"), "dark")
    obs.obs_property_list_add_string(preset_list, _("contrast_boost"), "contrast_boost")
    obs.obs_property_list_add_string(preset_list, _("contrast_reduce"), "contrast_reduce")
    
    -- Stil-Presets
    obs.obs_property_list_add_string(preset_list, _("style_presets"), "separator_style")
    obs.obs_property_list_add_string(preset_list, _("cinematic"), "cinematic")
    obs.obs_property_list_add_string(preset_list, _("filmic"), "filmic")
    obs.obs_property_list_add_string(preset_list, _("dramatic"), "dramatic")
    obs.obs_property_list_add_string(preset_list, _("vibrant"), "vibrant")
    obs.obs_property_list_add_string(preset_list, _("muted"), "muted")
    obs.obs_property_list_add_string(preset_list, _("warm_contrast"), "warm_contrast")
    obs.obs_property_list_add_string(preset_list, _("cool_contrast"), "cool_contrast")

    -- Farbstimmung-Presets
    obs.obs_property_list_add_string(preset_list, _("color_mood_presets"), "separator_color_mood")
    obs.obs_property_list_add_string(preset_list, _("highlights_warm"), "highlights_warm") 
    obs.obs_property_list_add_string(preset_list, _("shadows_blue"), "shadows_blue")
    obs.obs_property_list_add_string(preset_list, _("shadows_green"), "shadows_green")
    obs.obs_property_list_add_string(preset_list, _("sunset"), "sunset")
    obs.obs_property_list_add_string(preset_list, _("moonlight"), "moonlight")
    obs.obs_property_list_add_string(preset_list, _("vivid_warm"), "vivid_warm")
    
    -- Ära-Presets
    obs.obs_property_list_add_string(preset_list, _("era_presets"), "separator_era")
    obs.obs_property_list_add_string(preset_list, _("vintage"), "vintage")
    
    -- Kreative Presets mit erweiterten Funktionen (v2.0)
    obs.obs_property_list_add_string(preset_list, _("creative_presets"), "separator_creative")
    obs.obs_property_list_add_string(preset_list, _("neo_noir"), "neo_noir")
    obs.obs_property_list_add_string(preset_list, _("cyberpunk"), "cyberpunk")
    obs.obs_property_list_add_string(preset_list, _("retro_film"), "retro_film")
    obs.obs_property_list_add_string(preset_list, _("teal_orange"), "teal_orange")
    obs.obs_property_list_add_string(preset_list, _("dreamy_bloom"), "dreamy_bloom")
    obs.obs_property_list_add_string(preset_list, _("crisp_clarity"), "crisp_clarity")
    obs.obs_property_list_add_string(preset_list, _("horror_atmosphere"), "horror_atmosphere")
    obs.obs_property_list_add_string(preset_list, _("pastel_dreams"), "pastel_dreams")
    obs.obs_property_list_add_string(preset_list, _("game_stream"), "game_stream")
    obs.obs_property_list_add_string(preset_list, _("analog_vhs"), "analog_vhs")
    obs.obs_property_list_add_string(preset_list, _("bw"), "bw")
    obs.obs_property_list_add_string(preset_list, _("bw_high_contrast"), "bw_high_contrast")
    obs.obs_property_list_add_string(preset_list, _("sepia"), "sepia")
    
    -- Button zum Anwenden des ausgewählten Presets
    local apply_preset_button = obs.obs_properties_add_button(preset_group, "apply_preset_button", _("apply_preset"), 
        function(properties, property)
            if data then
                local preset = obs.obs_data_get_string(data.settings, "preset_select")
                if preset ~= "" then
                    log_debug("Starte Anwendung von Preset: " .. preset)
                    -- Preset anwenden
                    local success = apply_preset(data, preset)
                    if success then
                        log_debug("Preset erfolgreich angewendet, UI wird aktualisiert")
                    else
                        log_debug("FEHLER: Preset konnte nicht angewendet werden")
                    end
                    return true
                else
                    log_debug("Kein Preset ausgewählt")
                end
            else
                log_debug("FEHLER: data-Objekt ist nil im Knopf-Callback")
            end
            return true
        end)
        
    obs.obs_properties_add_group(props, "std_presets", _("presets"), obs.OBS_GROUP_NORMAL, preset_group)
    
    -- Belichtung und Kontrast
    local exposure_group = obs.obs_properties_create()
    
    local prop_exposure = obs.obs_properties_add_float_slider(exposure_group, "exposure", _("exposure"), -1.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_exposure, "Gesamthelligkeit des Bildes. Positive Werte hellen das Bild auf, negative Werte dunkeln es ab.")
    
    local prop_contrast = obs.obs_properties_add_float_slider(exposure_group, "contrast", _("contrast"), -1.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_contrast, "Kontrast des Bildes. Positive Werte erhöhen den Kontrast, negative Werte verringern ihn.")
    
    local prop_highlight_fade = obs.obs_properties_add_float_slider(exposure_group, "highlight_fade", _("highlight_fade"), 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_highlight_fade, "Lichter ausbleichen. Höhere Werte lassen helle Bereiche weißer erscheinen.")
    
    local prop_shadow_fade = obs.obs_properties_add_float_slider(exposure_group, "shadow_fade", _("shadow_fade"), 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_shadow_fade, "Schatten ausbleichen. Höhere Werte lassen dunkle Bereiche heller erscheinen.")
    
    local prop_black_lift = obs.obs_properties_add_float_slider(exposure_group, "black_lift", _("black_lift"), 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_black_lift, "Schwarzwert-Anhebung. Höhere Werte heben den Schwarzpunkt an und machen dunkle Bereiche heller.")
    
    obs.obs_properties_add_group(props, "exposure", _("basic"), obs.OBS_GROUP_NORMAL, exposure_group)
    
    -- Weißabgleich
    local wb_group = obs.obs_properties_create()
    
    local prop_temperature = obs.obs_properties_add_float_slider(wb_group, "temperature", _("temperature"), -1.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_temperature, "Farbtemperatur des Bildes. Positive Werte machen das Bild wärmer, negative Werte kühler.")
    
    local prop_tint = obs.obs_properties_add_float_slider(wb_group, "tint", _("tint"), -1.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_tint, "Farbton des Bildes. Positive Werte fügen Magenta hinzu, negative Grün.")
    
    obs.obs_properties_add_group(props, "wb", _("wb"), obs.OBS_GROUP_NORMAL, wb_group)
    
    -- Farbe
    local color_group = obs.obs_properties_create()
    
    local prop_saturation = obs.obs_properties_add_float_slider(color_group, "saturation", _("saturation"), -1.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_saturation, "Sättigung des Bildes. Positive Werte erhöhen die Sättigung, negative Werte verringern sie.")
    
    local prop_vibrance = obs.obs_properties_add_float_slider(color_group, "vibrance", _("vibrance"), -1.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_vibrance, "Lebendigkeit des Bildes. Positive Werte erhöhen die Lebendigkeit, negative Werte verringern sie.")
    
    obs.obs_properties_add_group(props, "color", _("color"), obs.OBS_GROUP_NORMAL, color_group)
    
    -- Vignette
    local vignette_group = obs.obs_properties_create()
    
    local prop_vignette_amount = obs.obs_properties_add_float_slider(vignette_group, "vignette_amount", _("vignette_amount"), 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_vignette_amount, "Stärke der Vignette. Positive Werte erhöhen die Vignette, negative Werte verringern sie.")
    
    local prop_vignette_radius = obs.obs_properties_add_float_slider(vignette_group, "vignette_radius", _("vignette_radius"), 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_vignette_radius, "Radius der Vignette. Positive Werte erhöhen den Radius, negative Werte verringern ihn.")
    
    local prop_vignette_feather = obs.obs_properties_add_float_slider(vignette_group, "vignette_feather", _("vignette_feather"), 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_vignette_feather, _("Weichzeichnung der Vignette. Positive Werte erhöhen die Weichzeichnung, negative Werte verringern sie."))
    
    local prop_vignette_shape = obs.obs_properties_add_float_slider(vignette_group, "vignette_shape", _("vignette_shape"), 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_vignette_shape, _("Form der Vignette. 0 = Kreisförmig, 1 = Ovaler/Rechteckiger."))
    
    obs.obs_properties_add_group(props, "vignette", _("vignette"), obs.OBS_GROUP_NORMAL, vignette_group)
    
    -- Farbräder
    local color_wheels_group = obs.obs_properties_create()
    
    local prop_shadows_color_r = obs.obs_properties_add_float_slider(color_wheels_group, "shadows_color_r", _("shadows_color_r"), -1.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_shadows_color_r, _("Rotanteil der Schatten. Positive Werte erhöhen den Rotanteil, negative Werte verringern ihn."))
    obs.obs_property_set_long_description(prop_shadows_color_r, "Rotanteil der Schatten. Positive Werte erhöhen den Rotanteil, negative Werte verringern ihn.")
    
    local prop_shadows_color_g = obs.obs_properties_add_float_slider(color_wheels_group, "shadows_color_g", _("shadows_color_g"), -1.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_shadows_color_g, "Grünanteil der Schatten. Positive Werte erhöhen den Grünanteil, negative Werte verringern ihn.")
    
    local prop_shadows_color_b = obs.obs_properties_add_float_slider(color_wheels_group, "shadows_color_b", _("shadows_color_b"), -1.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_shadows_color_b, "Blausteil der Schatten. Positive Werte erhöhen den Blausteil, negative Werte verringern ihn.")
    
    local prop_midtones_color_r = obs.obs_properties_add_float_slider(color_wheels_group, "midtones_color_r", _("midtones_color_r"), -1.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_midtones_color_r, "Rotanteil der Mitteltöne. Positive Werte erhöhen den Rotanteil, negative Werte verringern ihn.")
    
    local prop_midtones_color_g = obs.obs_properties_add_float_slider(color_wheels_group, "midtones_color_g", _("midtones_color_g"), -1.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_midtones_color_g, "Grünanteil der Mitteltöne. Positive Werte erhöhen den Grünanteil, negative Werte verringern ihn.")
    
    local prop_midtones_color_b = obs.obs_properties_add_float_slider(color_wheels_group, "midtones_color_b", _("midtones_color_b"), -1.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_midtones_color_b, "Blausteil der Mitteltöne. Positive Werte erhöhen den Blausteil, negative Werte verringern ihn.")
    
    local prop_highlights_color_r = obs.obs_properties_add_float_slider(color_wheels_group, "highlights_color_r", _("highlights_color_r"), -1.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_highlights_color_r, "Rotanteil der Lichter. Positive Werte erhöhen den Rotanteil, negative Werte verringern ihn.")
    
    local prop_highlights_color_g = obs.obs_properties_add_float_slider(color_wheels_group, "highlights_color_g", _("highlights_color_g"), -1.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_highlights_color_g, "Grünanteil der Lichter. Positive Werte erhöhen den Grünanteil, negative Werte verringern ihn.")
    
    local prop_highlights_color_b = obs.obs_properties_add_float_slider(color_wheels_group, "highlights_color_b", _("highlights_color_b"), -1.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_highlights_color_b, "Blausteil der Lichter. Positive Werte erhöhen den Blausteil, negative Werte verringern ihn.")
    
    obs.obs_properties_add_group(props, "color_wheels", _("color_wheels"), obs.OBS_GROUP_NORMAL, color_wheels_group)
    
    -- Vignette-Einstellungen sind bereits in der Hauptgruppe enthalten
    
    -- Split-Toning-Gruppe
    local split_tone_group = obs.obs_properties_create()
    obs.obs_properties_add_group(props, "split_tone_group", _("split_toning"), obs.OBS_GROUP_NORMAL, split_tone_group)
    
    -- Schatten Split-Toning
    local ss_prop = obs.obs_properties_add_float_slider(split_tone_group, "ss_r", _("shadows_red"), -1.0, 1.0, 0.01)
    obs.obs_property_set_long_description(ss_prop, _("shadow_red_desc"))
    
    ss_prop = obs.obs_properties_add_float_slider(split_tone_group, "ss_g", _("shadows_green"), -1.0, 1.0, 0.01)
    obs.obs_property_set_long_description(ss_prop, _("shadow_green_desc"))
    
    ss_prop = obs.obs_properties_add_float_slider(split_tone_group, "ss_b", _("shadows_blue"), -1.0, 1.0, 0.01)
    obs.obs_property_set_long_description(ss_prop, _("shadow_blue_desc"))
    
    ss_prop = obs.obs_properties_add_float_slider(split_tone_group, "ss_sat", _("shadows_sat"), 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(ss_prop, _("shadow_sat_desc"))
    
    -- Lichter Split-Toning
    local sh_prop = obs.obs_properties_add_float_slider(split_tone_group, "sh_r", _("highlights_red"), -1.0, 1.0, 0.01)
    obs.obs_property_set_long_description(sh_prop, _("highlight_red_desc"))
    
    sh_prop = obs.obs_properties_add_float_slider(split_tone_group, "sh_g", _("highlights_green"), -1.0, 1.0, 0.01)
    obs.obs_property_set_long_description(sh_prop, _("highlight_green_desc"))
    
    sh_prop = obs.obs_properties_add_float_slider(split_tone_group, "sh_b", _("highlights_blue"), -1.0, 1.0, 0.01)
    obs.obs_property_set_long_description(sh_prop, _("highlight_blue_desc"))
    
    sh_prop = obs.obs_properties_add_float_slider(split_tone_group, "sh_sat", _("highlights_sat"), 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(sh_prop, _("highlight_sat_desc"))
    
    -- Kreative Effekte
    local fx_group = obs.obs_properties_create()
    obs.obs_properties_add_group(props, "fx_group", _("creative_fx"), obs.OBS_GROUP_NORMAL, fx_group)
    
    local fx_prop = obs.obs_properties_add_float_slider(fx_group, "sharpen", _("sharpen"), 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(fx_prop, _("sharpen_desc"))
    
    fx_prop = obs.obs_properties_add_float_slider(fx_group, "bloom", _("bloom"), 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(fx_prop, _("bloom_desc"))
    
    fx_prop = obs.obs_properties_add_float_slider(fx_group, "halation", _("halation"), 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(fx_prop, _("halation_desc"))
    
    -- LUT-Gruppe
    local lut_group = obs.obs_properties_create()
    obs.obs_properties_add_group(props, "lut_group", _("lut"), obs.OBS_GROUP_NORMAL, lut_group)
    
    local lut_path_prop = obs.obs_properties_add_path(lut_group, "lut_path", _("lut_file"), obs.OBS_PATH_FILE, 
                                                   "LUT-Dateien (*.cube *.png);;Alle Dateien (*.*)", nil)
    obs.obs_property_set_long_description(lut_path_prop, _("lut_file_desc"))
    
    local lut_str_prop = obs.obs_properties_add_float_slider(lut_group, "lut_strength", _("lut_strength"), 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(lut_str_prop, _("lut_strength_desc"))
    
    log_debug("Properties erstellt mit allen Reglern")
    return props
end

-- Standardwerte
source_info.get_defaults = function(settings)
    obs.obs_data_set_default_double(settings, "exposure", 0.0)
    obs.obs_data_set_default_double(settings, "contrast", 0.0)
    obs.obs_data_set_default_double(settings, "brightness", 0.0)
    obs.obs_data_set_default_double(settings, "highlights", 0.0)
    obs.obs_data_set_default_double(settings, "shadows", 0.0)
    obs.obs_data_set_default_double(settings, "whites", 0.0)
    obs.obs_data_set_default_double(settings, "blacks", 0.0)
    obs.obs_data_set_default_double(settings, "highlight_fade", 0.0)
    obs.obs_data_set_default_double(settings, "shadow_fade", 0.0)
    obs.obs_data_set_default_double(settings, "black_lift", 0.0)
    obs.obs_data_set_default_double(settings, "temperature", 0.0)
    obs.obs_data_set_default_double(settings, "tint", 0.0)
    obs.obs_data_set_default_double(settings, "saturation", 0.0)
    obs.obs_data_set_default_double(settings, "vibrance", 0.0)
    obs.obs_data_set_default_double(settings, "vignette_amount", 0.0)
    obs.obs_data_set_default_double(settings, "vignette_radius", 0.75)
    obs.obs_data_set_default_double(settings, "vignette_feather", 0.5)
    obs.obs_data_set_default_double(settings, "vignette_shape", 0.0)
    obs.obs_data_set_default_double(settings, "shadows_color_r", 0.0)
    obs.obs_data_set_default_double(settings, "shadows_color_g", 0.0)
    obs.obs_data_set_default_double(settings, "shadows_color_b", 0.0)
    obs.obs_data_set_default_double(settings, "midtones_color_r", 0.0)
    obs.obs_data_set_default_double(settings, "midtones_color_g", 0.0)
    obs.obs_data_set_default_double(settings, "midtones_color_b", 0.0)
    obs.obs_data_set_default_double(settings, "highlights_color_r", 0.0)
    obs.obs_data_set_default_double(settings, "highlights_color_g", 0.0)
    obs.obs_data_set_default_double(settings, "highlights_color_b", 0.0)
    
    -- Split-Toning Defaults
    obs.obs_data_set_default_double(settings, "ss_r", 0.0)
    obs.obs_data_set_default_double(settings, "ss_g", 0.0)
    obs.obs_data_set_default_double(settings, "ss_b", 0.0)
    obs.obs_data_set_default_double(settings, "ss_sat", 0.0)
    obs.obs_data_set_default_double(settings, "sh_r", 0.0)
    obs.obs_data_set_default_double(settings, "sh_g", 0.0)
    obs.obs_data_set_default_double(settings, "sh_b", 0.0)
    obs.obs_data_set_default_double(settings, "sh_sat", 0.0)
    
    -- Kreative Effekte Defaults
    obs.obs_data_set_default_double(settings, "sharpen", 0.0)
    obs.obs_data_set_default_double(settings, "bloom", 0.0)
    obs.obs_data_set_default_double(settings, "halation", 0.0)
    
    -- LUT Defaults
    obs.obs_data_set_default_string(settings, "lut_path", "")
    obs.obs_data_set_default_double(settings, "lut_strength", 0.0)
end

-- Update-Funktion für Filtereinstellungen
source_info.update = function(data, settings)
    if not data then return end
    
    data.settings = settings
    
    -- Werte auslesen
    data.exposure = obs.obs_data_get_double(settings, "exposure")
    data.contrast = obs.obs_data_get_double(settings, "contrast")
    data.brightness = obs.obs_data_get_double(settings, "brightness")
    data.highlights = obs.obs_data_get_double(settings, "highlights")
    data.shadows = obs.obs_data_get_double(settings, "shadows")
    data.whites = obs.obs_data_get_double(settings, "whites")
    data.blacks = obs.obs_data_get_double(settings, "blacks")
    data.temperature = obs.obs_data_get_double(settings, "temperature")
    data.tint = obs.obs_data_get_double(settings, "tint")
    data.saturation = obs.obs_data_get_double(settings, "saturation")
    data.vibrance = obs.obs_data_get_double(settings, "vibrance")
    data.vignette_amount = obs.obs_data_get_double(settings, "vignette_amount")
    data.vignette_radius = obs.obs_data_get_double(settings, "vignette_radius")
    data.vignette_feather = obs.obs_data_get_double(settings, "vignette_feather")
    data.vignette_shape = obs.obs_data_get_int(settings, "vignette_shape")
    data.highlight_fade = obs.obs_data_get_double(settings, "highlight_fade")
    data.shadow_fade = obs.obs_data_get_double(settings, "shadow_fade")
    data.black_lift = obs.obs_data_get_double(settings, "black_lift")
    
    -- Farbrad-Parameter
    data.shadows_color_r = obs.obs_data_get_double(settings, "shadows_color_r")
    data.shadows_color_g = obs.obs_data_get_double(settings, "shadows_color_g")
    data.shadows_color_b = obs.obs_data_get_double(settings, "shadows_color_b")
    data.midtones_color_r = obs.obs_data_get_double(settings, "midtones_color_r")
    data.midtones_color_g = obs.obs_data_get_double(settings, "midtones_color_g")
    data.midtones_color_b = obs.obs_data_get_double(settings, "midtones_color_b")
    data.highlights_color_r = obs.obs_data_get_double(settings, "highlights_color_r")
    data.highlights_color_g = obs.obs_data_get_double(settings, "highlights_color_g")
    data.highlights_color_b = obs.obs_data_get_double(settings, "highlights_color_b")
    
    -- Split-Toning
    data.ss_r = obs.obs_data_get_double(settings, "ss_r")
    data.ss_g = obs.obs_data_get_double(settings, "ss_g")
    data.ss_b = obs.obs_data_get_double(settings, "ss_b")
    data.ss_sat = obs.obs_data_get_double(settings, "ss_sat")
    data.sh_r = obs.obs_data_get_double(settings, "sh_r")
    data.sh_g = obs.obs_data_get_double(settings, "sh_g")
    data.sh_b = obs.obs_data_get_double(settings, "sh_b")
    data.sh_sat = obs.obs_data_get_double(settings, "sh_sat")
    
    -- Kreative Effekte
    data.sharpen = obs.obs_data_get_double(settings, "sharpen")
    data.bloom = obs.obs_data_get_double(settings, "bloom")
    data.halation = obs.obs_data_get_double(settings, "halation")
    
    -- LUT
    local new_lut_path = obs.obs_data_get_string(settings, "lut_path")
    if new_lut_path ~= data.lut_path then
        -- LUT-Pfad hat sich geändert, alte Textur freigeben und neue laden
        if data.lut_tex then
            obs.gs_texture_destroy(data.lut_tex)
            data.lut_tex = nil
        end
        
        data.lut_path = new_lut_path
        if data.lut_path and data.lut_path ~= "" then
            data.lut_tex = load_lut(data.lut_path)
            data.lut_bound = false -- Neu binden beim nächsten Render
        end
    end
    
    data.lut_strength = obs.obs_data_get_double(settings, "lut_strength")
    
    -- Einstellungen speichern
    data.settings = settings
    
    -- Flag setzen, damit neue Uniform-Werte übertragen werden
    data.dirty = true
end

-- Video-Rendering
source_info.video_render = function(data, _)
    if not data or not data.effect then
        obs.obs_source_skip_video_filter(data and data.source)
        return
    end
    
    if data.invalid then
        log_debug("Filter ungültig")
        obs.obs_source_skip_video_filter(data.source)
        return
    end
    
    -- Größe des Ziels ermitteln
    local target = obs.obs_filter_get_target(data.source)
    local width = obs.obs_source_get_base_width(target)
    local height = obs.obs_source_get_base_height(target)
    
    if (width == 0 or height == 0) then
        log_debug("Target hat keine gültige Größe: " .. tostring(width) .. "x" .. tostring(height))
        obs.obs_source_skip_video_filter(data.source)
        return
    end
    
    data.width = width
    data.height = height
    
    -- Sichere Fehlerbehandlung während des Renderings
    local success, err = pcall(function()
        -- Begin des Filter-Prozesses
        obs.obs_source_process_filter_begin(data.source, obs.GS_RGBA, obs.OBS_NO_DIRECT_RENDERING)
        
        -- **Pflicht-Loop**: aktiviert den Pass und bindet die Constant-Buffer
        while obs.gs_effect_loop(data.effect, "Draw") do
            -- Uniforms innerhalb der Schleife setzen, wenn cur_pass gültig ist
            -- Metal erfordert dies, da der Constant-Buffer erst hier bereitsteht
            set_shader_params(data)
            
            obs.gs_draw_sprite(nil, 0, width, height)   -- Sprite zeichnen
        end
        
        -- Filter sauber abschließen (ohne Effect-Parameter!)
        obs.obs_source_process_filter_end(data.source, data.effect, width, height)
    end)
    
    if not success then
        log_debug("Fehler beim Rendering: " .. tostring(err))
        obs.obs_source_skip_video_filter(data.source)
    end
end

-- Preview-Rendering-Funktion
source_info.video_render_preview = function(data)
    if not data or not data.effect or data.invalid then
        return
    end
    
    -- Sichere Fehlerbehandlung während des Preview-Renderings
    local success, err = pcall(function()
        -- Erstelle Preview-Textur, falls nicht vorhanden
        if not data.preview_texture then
            local width = data.width or 200
            local height = data.height or 200
            
            obs.obs_enter_graphics()
            data.preview_texture = obs.gs_texture_create(width, height, obs.GS_RGBA, 1, nil, obs.GS_TEXTURE_2D)
            obs.obs_leave_graphics()
        end
        
        -- Verwende den Effekt für die Vorschau
        data.target_texture = nil  -- Signalisieren dass wir im Preview-Modus sind
        
        -- Blend-State zurücksetzen
        obs.gs_reset_blend_state()
        
        -- Kanonisches OBS-Muster mit gs_effect_loop für Metal-Kompatibilität
        while obs.gs_effect_loop(data.effect, "Draw") do
            -- Uniforms innerhalb der Schleife setzen, wenn cur_pass gültig ist
            -- Metal erfordert dies, da der Constant-Buffer erst hier bereitsteht
            set_shader_params(data)
            
            obs.gs_draw_sprite(nil, 0, data.width, data.height)   -- Sprite zeichnen
        end
    end)
    
    if not success then
        log_debug("Fehler beim Preview-Rendering: " .. tostring(err))
    end
end

-- Filter erstellen mit allen Parametern
source_info.create = function(settings, source)
    local data = {}
    
    -- Quelle speichern
    data.source = source
    data.settings = settings
    data.width = 0
    data.height = 0
    
    -- Default-Werte setzen
    data.exposure = 0.0
    data.contrast = 0.0
    data.brightness = 0.0
    data.highlights = 0.0
    data.shadows = 0.0
    data.whites = 0.0
    data.blacks = 0.0
    data.highlight_fade = 0.0
    data.shadow_fade = 0.0
    data.black_lift = 0.0
    data.temperature = 0.0
    data.tint = 0.0
    data.saturation = 0.0
    data.vibrance = 0.0
    data.vignette_amount = 0.0
    data.vignette_radius = 0.75
    data.vignette_feather = 0.5
    data.vignette_shape = 0
    
    data.highlight_fade = 0.0
    data.shadow_fade = 0.0
    data.black_lift = 0.0
    
    -- Split-Toning Defaults
    data.ss_r = 0.0
    data.ss_g = 0.0
    data.ss_b = 0.0
    data.ss_sat = 0.0
    data.sh_r = 0.0
    data.sh_g = 0.0
    data.sh_b = 0.0
    data.sh_sat = 0.0
    
    -- Kreative Effekte Defaults
    data.sharpen = 0.0
    data.bloom = 0.0
    data.halation = 0.0
    
    -- LUT Defaults
    data.lut_path = ""
    data.lut_strength = 0.0
    data.lut_tex = nil
    data.lut_bound = false
    
    -- Farbrad-Parameter
    data.shadows_color_r = 0.0
    data.shadows_color_g = 0.0
    data.shadows_color_b = 0.0
    data.midtones_color_r = 0.0
    data.midtones_color_g = 0.0
    data.midtones_color_b = 0.0
    data.highlights_color_r = 0.0
    data.highlights_color_g = 0.0
    data.highlights_color_b = 0.0
    
    -- Dirty-Flag & Seed-Timestamp für Optimierungen
    data.dirty = true
    data.last_seed_ts = 0
    
    -- Shader erstellen und Parameter abrufen
    obs.obs_enter_graphics()
    
    local success, err = pcall(function()
        data.effect = obs.gs_effect_create(shader_code, "lumetric_shader", nil)
        
        if data.effect ~= nil then
            -- Parameter für den Shader abrufen
            data.params = {}
            
            data.params.exposure = obs.gs_effect_get_param_by_name(data.effect, "exposure")
            data.params.contrast = obs.gs_effect_get_param_by_name(data.effect, "contrast")
            data.params.brightness = obs.gs_effect_get_param_by_name(data.effect, "brightness")
            data.params.highlights = obs.gs_effect_get_param_by_name(data.effect, "highlights")
            data.params.shadows = obs.gs_effect_get_param_by_name(data.effect, "shadows")
            data.params.whites = obs.gs_effect_get_param_by_name(data.effect, "whites")
            data.params.blacks = obs.gs_effect_get_param_by_name(data.effect, "blacks")
            data.params.temperature = obs.gs_effect_get_param_by_name(data.effect, "temperature")
            data.params.tint = obs.gs_effect_get_param_by_name(data.effect, "tint")
            data.params.saturation = obs.gs_effect_get_param_by_name(data.effect, "saturation")
            data.params.vibrance = obs.gs_effect_get_param_by_name(data.effect, "vibrance")
            data.params.vignette_amount = obs.gs_effect_get_param_by_name(data.effect, "vignette_amount")
            data.params.vignette_radius = obs.gs_effect_get_param_by_name(data.effect, "vignette_radius")
            data.params.vignette_feather = obs.gs_effect_get_param_by_name(data.effect, "vignette_feather")
            data.params.vignette_shape = obs.gs_effect_get_param_by_name(data.effect, "vignette_shape")
            data.params.highlight_fade = obs.gs_effect_get_param_by_name(data.effect, "highlight_fade")
            data.params.shadow_fade = obs.gs_effect_get_param_by_name(data.effect, "shadow_fade")
            data.params.black_lift = obs.gs_effect_get_param_by_name(data.effect, "black_lift")
            data.params.image = obs.gs_effect_get_param_by_name(data.effect, "image")
            data.params.buffer_size = obs.gs_effect_get_param_by_name(data.effect, "buffer_size")
            
            -- Farbrad-Parameter als float3-Vektoren
            data.params.shadows_color = obs.gs_effect_get_param_by_name(data.effect, "shadows_color")
            data.params.midtones_color = obs.gs_effect_get_param_by_name(data.effect, "midtones_color")
            data.params.highlights_color = obs.gs_effect_get_param_by_name(data.effect, "highlights_color")
            
            -- Erweiterte Effekte
            data.params.sharpen_amount = obs.gs_effect_get_param_by_name(data.effect, "sharpen_amount")
            data.params.bloom_intensity = obs.gs_effect_get_param_by_name(data.effect, "bloom_intensity")
            data.params.halation = obs.gs_effect_get_param_by_name(data.effect, "halation")
            data.params.lut_strength = obs.gs_effect_get_param_by_name(data.effect, "lut_strength")
            data.params.split_shadow = obs.gs_effect_get_param_by_name(data.effect, "split_shadow")
            data.params.split_highlight = obs.gs_effect_get_param_by_name(data.effect, "split_highlight")
            data.params.lut_tex = obs.gs_effect_get_param_by_name(data.effect, "lut_tex")
            
            -- Debug: Wir können nicht mehr direkt prüfen, ob Parameter gültig sind
            -- Stattdessen verwenden wir pcall, um Parameter beim Setzen zu prüfen
            -- Hier loggen wir nur, dass wir die Parameter geladen haben
            local param_count = 0
            for k,v in pairs(data.params) do
                if v then param_count = param_count + 1 end
            end
            obs.blog(obs.LOG_INFO, "[Lumetric] " .. param_count .. " Shader-Parameter geladen")
        else
            log_debug("Fehler: Shader konnte nicht geladen werden")
            data.invalid = true
        end
    end)
    
    obs.obs_leave_graphics()
    
    if not success then
        log_debug("Fehler bei der Shader-Initialisierung: " .. tostring(err))
        data.invalid = true
    end
    
    -- Default-Werte aus den Settings übernehmen (wenn vorhanden)
    source_info.update(data, settings)
    
    return data
end

-- Filter zerstören
source_info.destroy = function(data)
    if not data then return end
    
    local success, err = pcall(function()
        if data.effect ~= nil then
            obs.obs_enter_graphics()
            obs.gs_effect_destroy(data.effect)
            if data.preview_texture then
                obs.gs_texture_destroy(data.preview_texture)
                data.preview_texture = nil
            end
            obs.obs_leave_graphics()
            data.effect = nil
        end
    end)
    
    if not success then
        log_debug("Fehler beim Zerstören des Filters: " .. tostring(err))
    else
        log_debug("Filter erfolgreich zerstört")
    end
end

-- Filter registrieren
function script_load(settings)
    log_debug("Lumetric Filter wird registriert...")
    obs.obs_register_source(source_info)
    log_debug("Shader-Filter erfolgreich geladen")
end

function script_unload()
    log_debug("Filter entladen")
end


function destroy(data)
    if data.effect then
        obs.obs_enter_graphics()
        obs.gs_effect_destroy(data.effect)
        obs.obs_leave_graphics()
        data.effect = nil
    end
    if data.preview_texture then
        obs.obs_enter_graphics()
        obs.gs_texture_destroy(data.preview_texture)
        obs.obs_leave_graphics()
        data.preview_texture = nil
    end
end
