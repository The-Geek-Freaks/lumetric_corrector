--[[
  Lumetric Corrector für OBS Studio
  Eine Farbkorrektur-Lösung inspiriert von Adobe Lumetri Color
  
  Autor: TheGeekFreaks
  Version: 1.0.0
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
        ["film_grain"] = "Film Grain",
        ["grain_amount"] = "Amount",
        ["grain_size"] = "Size",
        ["time_seed"] = "Time Seed",
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
        ["film_grain"] = "Filmkorn",
        ["grain_amount"] = "Stärke",
        ["grain_size"] = "Körnungsgröße",
        ["time_seed"] = "Zeit-Seed",
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
        ["cinematic"] = "Kinematisch",
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
        ["basic_presets"] = "--- GRUNDLEGENDE VOREINSTELLUNGEN ---",
        ["style_presets"] = "--- STIL-VOREINSTELLUNGEN ---",
        ["color_mood_presets"] = "--- FARBSTIMMUNG-VOREINSTELLUNGEN ---",
        ["era_presets"] = "--- ÄRA-VOREINSTELLUNGEN ---"
    }
}

-- Shader mit erweiterten Funktionen (Vignette und Film Grain)
local shader_code = [[
uniform float4x4 ViewProj;
uniform texture2d image;

// Grundlegende Korrekturen
uniform float exposure;
uniform float contrast;
uniform float brightness;
uniform float highlights;
uniform float shadows;
uniform float whites;
uniform float blacks;

// Weißabgleich
uniform float temperature;
uniform float tint;

// Farbe
uniform float saturation;
uniform float vibrance;

// Vignette-Effekt
uniform float vignette_amount;
uniform float vignette_radius;
uniform float vignette_feather;

// Film Grain
uniform float grain_amount;
uniform float grain_size;
uniform float time_seed;

// Einfache Farbräder (vereinfachte Version als direkter Farbkorrekturansatz)
uniform float shadows_color_r;
uniform float shadows_color_g;
uniform float shadows_color_b;
uniform float midtones_color_r;
uniform float midtones_color_g;
uniform float midtones_color_b;
uniform float highlights_color_r;
uniform float highlights_color_g;
uniform float highlights_color_b;

sampler_state textureSampler {
    Filter    = Linear;
    AddressU  = Clamp;
    AddressV  = Clamp;
};

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
float3 apply_vignette(float3 color, float2 uv, float amount, float radius, float feather) {
    float2 center = float2(0.5, 0.5);
    float dist = distance(uv, center);
    
    // Vignette stärke berechnen
    float vignette = smoothstep(radius, radius - feather, dist);
    
    // Auf Bild anwenden
    return color * lerp(1.0, vignette, amount);
}

// Film Grain anwenden
float3 apply_film_grain(float3 color, float2 uv, float amount, float grain_size, float seed) {
    // Einfaches Perlin-Noise für Körnung
    float2 coords = uv * grain_size;
    float x = (coords.x + 4.0) * (coords.y + 4.0) * (seed * 10.0 + 10.0);
    float random = frac(sin(x) * 43758.5453);
    
    // Rauscheffekt berechnen
    float grain = random * 2.0 - 1.0;
    float luma = dot(color, float3(0.2126, 0.7152, 0.0722));
    
    float grain_amount = amount * (0.5 + luma * 0.5); // In dunkleren Bildbereichen weniger Körnung
    
    return lerp(color, color * (0.9 + grain * 0.2), grain_amount);
}

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
float3 apply_color_balance(float3 color, float3 shadows_color, float3 midtones_color, float3 highlights_color) {
    float luma = dot(color, float3(0.2126, 0.7152, 0.0722));
    float3 weights = calculate_weights(luma);
    
    // Additive Farbmischung mit Gewichtung je nach Tonwertbereich
    float3 result = color;
    result += shadows_color * weights.x * 0.5;     // 50% Stärke für Schatten
    result += midtones_color * weights.y * 0.3;    // 30% Stärke für Mitteltöne
    result += highlights_color * weights.z * 0.5;  // 50% Stärke für Lichter
    
    return saturate(result); // Sicherstellen, dass die Farben im gültigen Bereich bleiben
}

float4 PSDefault(VertDataOut v_in) : TARGET
{
    float4 color = image.Sample(textureSampler, v_in.uv);
    float3 result = color.rgb;
    
    // Belichtung
    result *= pow(2.0, exposure);
    
    // Lichterwerte und Schatten
    if (highlights != 0.0) {
        float highlight_mask = smoothstep(0.5, 1.0, result);
        result = lerp(result, result * (1.0 + highlights), highlight_mask);
    }
    
    if (shadows != 0.0) {
        float shadow_mask = 1.0 - smoothstep(0.0, 0.5, result);
        result = lerp(result, result * (1.0 + shadows), shadow_mask);
    }
    
    // Weißpunkt und Schwarzpunkt
    if (whites != 0.0) {
        float whites_mask = smoothstep(0.7, 1.0, result);
        result = lerp(result, result + whites * 0.5, whites_mask);
    }
    
    if (blacks != 0.0) {
        float blacks_mask = 1.0 - smoothstep(0.0, 0.3, result);
        result = lerp(result, result + blacks * 0.5, blacks_mask);
    }
    
    // Helligkeit
    result = saturate(result + brightness);
    
    // Kontrast
    result = apply_contrast(result, contrast);
    
    // Farbtemperatur und Tint
    result = apply_temperature(result, temperature, tint);
    
    // Farbräder/Farbbalance anwenden
    float3 shadows_col = float3(shadows_color_r, shadows_color_g, shadows_color_b);
    float3 midtones_col = float3(midtones_color_r, midtones_color_g, midtones_color_b);
    float3 highlights_col = float3(highlights_color_r, highlights_color_g, highlights_color_b);
    result = apply_color_balance(result, shadows_col, midtones_col, highlights_col);
    
    // Sättigung und Lebendigkeit
    result = apply_saturation(result, saturation);
    result = apply_vibrance(result, vibrance);
    
    // Vignette anwenden
    if (vignette_amount > 0.0) {
        result = apply_vignette(result, v_in.uv, vignette_amount, vignette_radius, vignette_feather);
    }
    
    // Film Grain anwenden
    if (grain_amount > 0.0) {
        result = apply_film_grain(result, v_in.uv, grain_amount, grain_size, time_seed);
    }
    
    // Ergebnis sicherstellen
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

-- Parameter an den Shader übergeben
function set_shader_params(data)
    if not data or not data.params then 
        log_debug("Keine Daten oder Parameter verfügbar")
        return 
    end
    
    -- Alle Parameter setzen
    if data.params.exposure then 
        obs.gs_effect_set_float(data.params.exposure, data.exposure)
    end
    if data.params.contrast then 
        obs.gs_effect_set_float(data.params.contrast, data.contrast)
    end
    if data.params.brightness then 
        obs.gs_effect_set_float(data.params.brightness, data.brightness)
    end
    if data.params.highlights then 
        obs.gs_effect_set_float(data.params.highlights, data.highlights)
    end
    if data.params.shadows then 
        obs.gs_effect_set_float(data.params.shadows, data.shadows)
    end
    if data.params.whites then 
        obs.gs_effect_set_float(data.params.whites, data.whites)
    end
    if data.params.blacks then 
        obs.gs_effect_set_float(data.params.blacks, data.blacks)
    end
    if data.params.temperature then 
        obs.gs_effect_set_float(data.params.temperature, data.temperature)
    end
    if data.params.tint then 
        obs.gs_effect_set_float(data.params.tint, data.tint)
    end
    if data.params.saturation then 
        obs.gs_effect_set_float(data.params.saturation, data.saturation)
    end
    if data.params.vibrance then 
        obs.gs_effect_set_float(data.params.vibrance, data.vibrance)
    end
    if data.params.vignette_amount then 
        obs.gs_effect_set_float(data.params.vignette_amount, data.vignette_amount)
    end
    if data.params.vignette_radius then 
        obs.gs_effect_set_float(data.params.vignette_radius, data.vignette_radius)
    end
    if data.params.vignette_feather then 
        obs.gs_effect_set_float(data.params.vignette_feather, data.vignette_feather)
    end
    if data.params.grain_amount then 
        obs.gs_effect_set_float(data.params.grain_amount, data.grain_amount)
    end
    if data.params.grain_size then 
        obs.gs_effect_set_float(data.params.grain_size, data.grain_size)
    end
    if data.params.time_seed then 
        obs.gs_effect_set_float(data.params.time_seed, data.time_seed)
    end
    
    -- Farbrad-Parameter setzen (nur wenn sie existieren)
    if data.params.shadows_color_r and data.shadows_color_r ~= nil then 
        obs.gs_effect_set_float(data.params.shadows_color_r, data.shadows_color_r)
    end
    if data.params.shadows_color_g and data.shadows_color_g ~= nil then 
        obs.gs_effect_set_float(data.params.shadows_color_g, data.shadows_color_g)
    end
    if data.params.shadows_color_b and data.shadows_color_b ~= nil then 
        obs.gs_effect_set_float(data.params.shadows_color_b, data.shadows_color_b)
    end
    
    if data.params.midtones_color_r and data.midtones_color_r ~= nil then 
        obs.gs_effect_set_float(data.params.midtones_color_r, data.midtones_color_r)
    end
    if data.params.midtones_color_g and data.midtones_color_g ~= nil then 
        obs.gs_effect_set_float(data.params.midtones_color_g, data.midtones_color_g)
    end
    if data.params.midtones_color_b and data.midtones_color_b ~= nil then 
        obs.gs_effect_set_float(data.params.midtones_color_b, data.midtones_color_b)
    end
    
    if data.params.highlights_color_r and data.highlights_color_r ~= nil then 
        obs.gs_effect_set_float(data.params.highlights_color_r, data.highlights_color_r)
    end
    if data.params.highlights_color_g and data.highlights_color_g ~= nil then 
        obs.gs_effect_set_float(data.params.highlights_color_g, data.highlights_color_g)
    end
    if data.params.highlights_color_b and data.highlights_color_b ~= nil then 
        obs.gs_effect_set_float(data.params.highlights_color_b, data.highlights_color_b)
    end
    
    -- Nur für die Preview-Textur explizit setzen
    if data.target_texture == nil and data.params.image and data.preview_texture then
        obs.gs_effect_set_texture(data.params.image, data.preview_texture)
    end
end

-- Hilfsfunktion für Debug-Logging
local function log_debug(message)
    obs.blog(obs.LOG_INFO, "[Lumetric] " .. message)
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
    return _("lumetric_corrector") .. " - " .. "v1.0.0"
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
        obs.obs_data_set_double(settings, "grain_amount", 0.0)
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
        obs.obs_data_set_double(settings, "grain_amount", 0.2)
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
    obs.obs_property_set_long_description(prop_vignette_feather, "Weichzeichnung der Vignette. Positive Werte erhöhen die Weichzeichnung, negative Werte verringern sie.")
    
    obs.obs_properties_add_group(props, "vignette", _("vignette"), obs.OBS_GROUP_NORMAL, vignette_group)
    
    -- Film Grain
    local grain_group = obs.obs_properties_create()
    
    local prop_grain_amount = obs.obs_properties_add_float_slider(grain_group, "grain_amount", _("grain_amount"), 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_grain_amount, "Stärke des Filmkorns. Positive Werte erhöhen das Filmkorn, negative Werte verringern es.")
    
    local prop_grain_size = obs.obs_properties_add_float_slider(grain_group, "grain_size", _("grain_size"), 1.0, 100.0, 1.0)
    obs.obs_property_set_long_description(prop_grain_size, "Größe des Filmkorns. Positive Werte erhöhen die Größe, negative Werte verringern sie.")
    
    local prop_time_seed = obs.obs_properties_add_float_slider(grain_group, "time_seed", _("time_seed"), 0.0, 100.0, 1.0)
    obs.obs_property_set_long_description(prop_time_seed, "Zeit-Seed für das Filmkorn. Positive Werte ändern das Filmkorn-Muster.")
    
    obs.obs_properties_add_group(props, "film_grain", _("film_grain"), obs.OBS_GROUP_NORMAL, grain_group)
    
    -- Farbräder
    local color_wheels_group = obs.obs_properties_create()
    
    local prop_shadows_color_r = obs.obs_properties_add_float_slider(color_wheels_group, "shadows_color_r", _("shadows_color_r"), -1.0, 1.0, 0.01)
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
    obs.obs_data_set_default_double(settings, "temperature", 0.0)
    obs.obs_data_set_default_double(settings, "tint", 0.0)
    obs.obs_data_set_default_double(settings, "saturation", 0.0)
    obs.obs_data_set_default_double(settings, "vibrance", 0.0)
    obs.obs_data_set_default_double(settings, "vignette_amount", 0.0)
    obs.obs_data_set_default_double(settings, "vignette_radius", 0.75)
    obs.obs_data_set_default_double(settings, "vignette_feather", 0.5)
    obs.obs_data_set_default_double(settings, "grain_amount", 0.0)
    obs.obs_data_set_default_double(settings, "grain_size", 50.0)
    obs.obs_data_set_default_double(settings, "time_seed", 0.0)
    obs.obs_data_set_default_double(settings, "shadows_color_r", 0.0)
    obs.obs_data_set_default_double(settings, "shadows_color_g", 0.0)
    obs.obs_data_set_default_double(settings, "shadows_color_b", 0.0)
    obs.obs_data_set_default_double(settings, "midtones_color_r", 0.0)
    obs.obs_data_set_default_double(settings, "midtones_color_g", 0.0)
    obs.obs_data_set_default_double(settings, "midtones_color_b", 0.0)
    obs.obs_data_set_default_double(settings, "highlights_color_r", 0.0)
    obs.obs_data_set_default_double(settings, "highlights_color_g", 0.0)
    obs.obs_data_set_default_double(settings, "highlights_color_b", 0.0)
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
    data.grain_amount = obs.obs_data_get_double(settings, "grain_amount")
    data.grain_size = obs.obs_data_get_double(settings, "grain_size")
    data.time_seed = obs.obs_data_get_double(settings, "time_seed")
    
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
    
    -- Einstellungen speichern
    data.settings = settings
end

-- Video-Rendering
source_info.video_render = function(data, effect)
    if not data then
        log_debug("Keine Daten verfügbar")
        return
    end
    
    if not data.effect then
        log_debug("Kein Effekt verfügbar")
        if data and data.source then
            obs.obs_source_skip_video_filter(data.source)
        end
        return
    end
    
    if data.invalid then
        log_debug("Filter ungültig")
        obs.obs_source_skip_video_filter(data.source)
        return
    end
    
    -- Größe des Ziels ermitteln
    local target = obs.obs_filter_get_target(data.source)
    local width, height = 0, 0
    
    if target ~= nil then
        width = obs.obs_source_get_base_width(target)
        height = obs.obs_source_get_base_height(target)
    end
    
    if (width == 0 or height == 0) then
        log_debug("Target hat keine gültige Größe: " .. tostring(width) .. "x" .. tostring(height))
        obs.obs_source_skip_video_filter(data.source)
        return
    end
    
    data.width = width
    data.height = height
    
    -- Sichere Fehlerbehandlung während des Renderings
    local success, err = pcall(function()
        obs.obs_source_process_filter_begin(data.source, obs.GS_RGBA, obs.OBS_NO_DIRECT_RENDERING)
        
        -- Parameter an den Shader übergeben
        set_shader_params(data)
        
        -- Effekt anwenden
        local technique = obs.gs_effect_get_technique(data.effect, "Draw")
        if technique then
            obs.gs_technique_begin(technique)
            obs.gs_technique_begin_pass(technique, 0)
            
            obs.obs_source_process_filter_end(data.source, data.effect, width, height)
            
            obs.gs_technique_end_pass(technique)
            obs.gs_technique_end(technique)
        else
            log_debug("Technique nicht gefunden")
            obs.obs_source_process_filter_end(data.source, data.effect, width, height)
        end
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
        set_shader_params(data)
        
        local technique = obs.gs_effect_get_technique(data.effect, "Draw")
        if not technique then return end
        
        obs.gs_reset_blend_state()
        obs.gs_technique_begin(technique)
        obs.gs_technique_begin_pass(technique, 0)
        
        obs.gs_draw_sprite(nil, 0, data.width, data.height)
        
        obs.gs_technique_end_pass(technique)
        obs.gs_technique_end(technique)
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
    data.temperature = 0.0
    data.tint = 0.0
    data.saturation = 0.0
    data.vibrance = 0.0
    data.vignette_amount = 0.0
    data.vignette_radius = 0.75
    data.vignette_feather = 0.5
    data.grain_amount = 0.0
    data.grain_size = 50.0
    data.time_seed = 0.0
    
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
            data.params.grain_amount = obs.gs_effect_get_param_by_name(data.effect, "grain_amount")
            data.params.grain_size = obs.gs_effect_get_param_by_name(data.effect, "grain_size")
            data.params.time_seed = obs.gs_effect_get_param_by_name(data.effect, "time_seed")
            
            -- Farbrad-Parameter
            data.params.shadows_color_r = obs.gs_effect_get_param_by_name(data.effect, "shadows_color_r")
            data.params.shadows_color_g = obs.gs_effect_get_param_by_name(data.effect, "shadows_color_g")
            data.params.shadows_color_b = obs.gs_effect_get_param_by_name(data.effect, "shadows_color_b")
            data.params.midtones_color_r = obs.gs_effect_get_param_by_name(data.effect, "midtones_color_r")
            data.params.midtones_color_g = obs.gs_effect_get_param_by_name(data.effect, "midtones_color_g")
            data.params.midtones_color_b = obs.gs_effect_get_param_by_name(data.effect, "midtones_color_b")
            data.params.highlights_color_r = obs.gs_effect_get_param_by_name(data.effect, "highlights_color_r")
            data.params.highlights_color_g = obs.gs_effect_get_param_by_name(data.effect, "highlights_color_g")
            data.params.highlights_color_b = obs.gs_effect_get_param_by_name(data.effect, "highlights_color_b")
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
