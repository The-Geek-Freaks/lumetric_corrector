--[[
  Lumetric Corrector für OBS Studio
  Eine Farbkorrektur-Lösung inspiriert von Adobe Lumetri Color
  
  Autor: TheGeekFreaks
  Version: 1.3.0
  Lizenz: GPLv3
]]

-- OBS Modul einfügen
local obs = obslua

-- FFI für Plattformerkennung
local ffi = nil
local success, err = pcall(function()
    ffi = require("ffi")
end)
if not success then
    -- FFI nicht verfügbar, kein Problem, wir haben Fallbacks
    ffi = nil
end

-- JSON-Modul für Export/Import von Einstellungen
local json = {}

-- Einfache JSON-Implementierung für Lua
-- Vereinfachte Version ohne komplexe Escape-Sequenzen
do
    -- Bestimmt, ob ein Objekt ein Array oder eine Tabelle ist
    local function kind_of(obj)
        if type(obj) ~= 'table' then return type(obj) end
        local count = 0
        for _ in pairs(obj) do count = count + 1 end
        if count == 0 then return 'table' end
        
        local is_array = true
        for k, _ in pairs(obj) do
            if type(k) ~= 'number' or k <= 0 or math.floor(k) ~= k then
                is_array = false
                break
            end
        end
        if is_array then return 'array' else return 'table' end
    end
    
    -- Stringifiziert ein Objekt zu JSON
    function json.stringify(obj)
        local result = {}
        local t = type(obj)
        
        if t == 'table' then
            local k = kind_of(obj)
            if k == 'array' then
                result[#result+1] = '['
                for i, v in ipairs(obj) do
                    if i > 1 then result[#result+1] = ',' end
                    result[#result+1] = json.stringify(v)
                end
                result[#result+1] = ']'
            else
                result[#result+1] = '{'
                local first = true
                for k, v in pairs(obj) do
                    if not first then result[#result+1] = ',' end
                    first = false
                    result[#result+1] = '"' .. tostring(k) .. '":'
                    result[#result+1] = json.stringify(v)
                end
                result[#result+1] = '}'
            end
        elseif t == 'string' then
            -- Einfache String-Escape-Funktion
            local s = obj:gsub('\\', '\\\\')
            s = s:gsub('"', '\\"')
            s = s:gsub('\n', '\\n')
            s = s:gsub('\r', '\\r')
            s = s:gsub('\t', '\\t')
            result[#result+1] = '"' .. s .. '"'
        elseif t == 'number' then
            result[#result+1] = tostring(obj)
        elseif t == 'boolean' then
            result[#result+1] = tostring(obj)
        elseif t == 'nil' then
            result[#result+1] = 'null'
        else
            error('Nicht unterstützter Typ: ' .. t)
        end
        
        return table.concat(result)
    end

    -- JSON Parser Funktion
    function json.parse(str)
        local i = 1
        local t = {}
        
        -- Hilfsfunktionen für den Parser
        local function skip_whitespace()
            i = string.find(str, "[^%s]", i) or #str+1
        end
        
        local function parse_string()
            local start_i = i
            i = i + 1 -- Überspringe das öffnende Anführungszeichen
            local result = ""
            
            while i <= #str do
                local c = str:sub(i, i)
                
                if c == '"' then
                    i = i + 1
                    return result
                elseif c == '\\' and i < #str then
                    local next_c = str:sub(i+1, i+1)
                    if next_c == '"' then
                        result = result .. '"'
                    elseif next_c == '\\' then
                        result = result .. '\\'
                    elseif next_c == '/' then
                        result = result .. '/'
                    elseif next_c == 'b' then
                        result = result .. '\b'
                    elseif next_c == 'f' then
                        result = result .. '\f'
                    elseif next_c == 'n' then
                        result = result .. '\n'
                    elseif next_c == 'r' then
                        result = result .. '\r'
                    elseif next_c == 't' then
                        result = result .. '\t'
                    else
                        result = result .. next_c
                    end
                    i = i + 2
                else
                    result = result .. c
                    i = i + 1
                end
            end
            
            error("Unerwartetes Ende des Strings bei Position " .. start_i)
        end
        
        local function parse_number()
            local start_i = i
            local end_i = string.find(str, "[^-0-9.eE+]", i) or #str+1
            local num_str = str:sub(i, end_i-1)
            i = end_i
            
            local num = tonumber(num_str)
            if not num then
                error("Ungültige Zahl bei Position " .. start_i .. ": " .. num_str)
            end
            return num
        end
        
        local function parse_value()
            skip_whitespace()
            
            local c = str:sub(i, i)
            
            if c == '{' then
                return parse_object()
            elseif c == '[' then
                return parse_array()
            elseif c == '"' then
                return parse_string()
            elseif c == '-' or (c >= '0' and c <= '9') then
                return parse_number()
            elseif c == 't' and str:sub(i, i+3) == "true" then
                i = i + 4
                return true
            elseif c == 'f' and str:sub(i, i+4) == "false" then
                i = i + 5
                return false
            elseif c == 'n' and str:sub(i, i+3) == "null" then
                i = i + 4
                return nil
            else
                error("Unerwartetes Zeichen bei Position " .. i .. ": " .. c)
            end
        end
        
        function parse_object()
            local obj = {}
            i = i + 1 -- Überspringe das öffnende {
            
            skip_whitespace()
            if str:sub(i, i) == "}" then
                i = i + 1
                return obj
            end
            
            while i <= #str do
                skip_whitespace()
                
                if str:sub(i, i) ~= '"' then
                    error("Schlüssel erwartet bei Position " .. i)
                end
                
                local key = parse_string()
                
                skip_whitespace()
                if str:sub(i, i) ~= ':' then
                    error("':' erwartet bei Position " .. i)
                end
                i = i + 1
                
                local value = parse_value()
                obj[key] = value
                
                skip_whitespace()
                local c = str:sub(i, i)
                if c == "}" then
                    i = i + 1
                    return obj
                elseif c == "," then
                    i = i + 1
                else
                    error("',' oder '}' erwartet bei Position " .. i)
                end
            end
            
            error("Unerwartetes Ende des Objekts")
        end
        
        function parse_array()
            local arr = {}
            i = i + 1 -- Überspringe das öffnende [
            
            skip_whitespace()
            if str:sub(i, i) == "]" then
                i = i + 1
                return arr
            end
            
            while i <= #str do
                local value = parse_value()
                table.insert(arr, value)
                
                skip_whitespace()
                local c = str:sub(i, i)
                if c == "]" then
                    i = i + 1
                    return arr
                elseif c == "," then
                    i = i + 1
                else
                    error("',' oder ']' erwartet bei Position " .. i)
                end
            end
            
            error("Unerwartetes Ende des Arrays")
        end
        
        -- Starte den Parser
        local result = parse_value()
        skip_whitespace()
        
        if i <= #str then
            error("Unerwartete Zeichen nach Ende des JSON bei Position " .. i)
        end
        
        return result
    end
end

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

-- Schaltet Debug-Logs ein/aus
local DEBUG = true

-- Pfad für benutzerdefinierte Voreinstellungen
local function get_preset_directory()
    local platform = get_platform()
    local dir
    
    if platform == "windows" then
        dir = os.getenv("APPDATA") .. "\\obs-studio\\lumetric-presets\\"
    elseif platform == "macos" then
        dir = os.getenv("HOME") .. "/Library/Application Support/obs-studio/lumetric-presets/"
    else -- Linux
        dir = os.getenv("HOME") .. "/.config/obs-studio/lumetric-presets/"
    end
    
    -- Versuche, das Verzeichnis zu erstellen, falls es nicht existiert
    local success = os.execute("mkdir \"" .. dir .. "\"")
    
    return dir
end

-- Funktionen für Export/Import von Einstellungen
local function export_settings(data, preset_name)
    if not data then return false, "Keine Daten zum Exportieren vorhanden" end
    if not preset_name or preset_name == "" then return false, "Kein Preset-Name angegeben" end
    
    -- Erstelle ein Objekt mit allen relevanten Einstellungen
    local settings = {}
    
    -- Grundlegende Korrekturen
    settings.exposure = data.exposure or 0
    settings.contrast = data.contrast or 0
    settings.brightness = data.brightness or 0
    settings.highlights = data.highlights or 0
    settings.shadows = data.shadows or 0
    settings.whites = data.whites or 0
    settings.blacks = data.blacks or 0
    settings.highlight_fade = data.highlight_fade or 0
    settings.shadow_fade = data.shadow_fade or 0
    settings.black_lift = data.black_lift or 0
    
    -- Weißabgleich
    settings.temperature = data.temperature or 0
    settings.tint = data.tint or 0
    
    -- Farbe
    settings.saturation = data.saturation or 0
    settings.vibrance = data.vibrance or 0
    
    -- Split-Toning (neu)
    settings.split_shadows_hue = data.split_shadows_hue or 0
    settings.split_shadows_sat = data.split_shadows_sat or 0
    settings.split_highlights_hue = data.split_highlights_hue or 0
    settings.split_highlights_sat = data.split_highlights_sat or 0
    settings.split_balance = data.split_balance or 0
    
    -- Vignette
    settings.vignette_amount = data.vignette_amount or 0
    settings.vignette_radius = data.vignette_radius or 0.5
    settings.vignette_feather = data.vignette_feather or 0.5
    settings.vignette_shape = data.vignette_shape or 0
    
    -- Film Grain
    settings.grain_amount = data.grain_amount or 0
    settings.grain_size = data.grain_size or 0.5
    
    -- Schärfung (neu)
    settings.sharpen_amount = data.sharpen_amount or 0
    settings.sharpen_radius = data.sharpen_radius or 0.5
    
    -- Bloom (neu)
    settings.bloom_amount = data.bloom_amount or 0
    settings.bloom_threshold = data.bloom_threshold or 0.8
    
    -- Farbräder
    settings.shadows_color_r = data.shadows_color_r or 0
    settings.shadows_color_g = data.shadows_color_g or 0
    settings.shadows_color_b = data.shadows_color_b or 0
    settings.midtones_color_r = data.midtones_color_r or 0
    settings.midtones_color_g = data.midtones_color_g or 0
    settings.midtones_color_b = data.midtones_color_b or 0
    settings.highlights_color_r = data.highlights_color_r or 0
    settings.highlights_color_g = data.highlights_color_g or 0
    settings.highlights_color_b = data.highlights_color_b or 0
    
    -- Metadaten
    settings.name = preset_name
    settings.created = os.date("%Y-%m-%d %H:%M:%S")
    settings.version = "1.3.0"
    
    -- Konvertiere zu JSON
    local json_str = json.stringify(settings)
    
    -- Speichere in Datei
    local preset_dir = get_preset_directory()
    local filename = preset_dir .. preset_name .. ".json"
    
    local file = io.open(filename, "w")
    if not file then
        return false, "Konnte Datei nicht erstellen: " .. filename
    end
    
    file:write(json_str)
    file:close()
    
    return true, "Preset erfolgreich gespeichert: " .. preset_name
end

local function import_settings(preset_name)
    if not preset_name or preset_name == "" then return nil, "Kein Preset-Name angegeben" end
    
    local preset_dir = get_preset_directory()
    local filename = preset_dir .. preset_name .. ".json"
    
    local file = io.open(filename, "r")
    if not file then
        return nil, "Preset nicht gefunden: " .. preset_name
    end
    
    local content = file:read("*all")
    file:close()
    
    -- Parse JSON
    local success, settings = pcall(function() return json.parse(content) end)
    
    if not success then
        return nil, "Fehler beim Parsen des Presets: " .. tostring(settings)
    end
    
    return settings, "Preset erfolgreich geladen: " .. preset_name
end

local function list_custom_presets()
    local preset_dir = get_preset_directory()
    local presets = {}
    
    -- Versuche, alle .json-Dateien im Preset-Verzeichnis zu finden
    local handle
    local platform = get_platform()
    
    if platform == "windows" then
        local cmd = "dir /b \"" .. preset_dir .. "*.json\""
        handle = io.popen(cmd)
    else
        local cmd = "ls -1 \"" .. preset_dir .. "\" | grep \"\\.json$\""
        handle = io.popen(cmd)
    end
    
    if handle then
        for line in handle:lines() do
            -- Entferne .json-Erweiterung
            local preset_name = line:match("(.+)%.json")
            if preset_name then
                table.insert(presets, preset_name)
            end
        end
        handle:close()
    end
    
    return presets
end

-- Plattformerkennung
local function get_platform()
    local os_name = ffi and ffi.os or "Windows"
    if os_name == "Windows" then
        return "windows"
    elseif os_name == "OSX" or os_name == "Darwin" then
        return "macos"
    else
        return "linux"
    end
end

local PLATFORM = get_platform()
local IS_MACOS = PLATFORM == "macos"

-- Kompatible Zeitfunktion (Sekunden als float)
local function get_time_s()
    if obs.os_gettime_s then
        return obs.os_gettime_s()
    elseif obs.os_gettime_ns then
        return obs.os_gettime_ns() / 1000000000.0
    else
        return os.time()
    end
end

-- Hilfsfunktion zum Prüfen, ob eine Datei existiert
local function file_exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

-- Shader mit erweiterten Funktionen (Vignette und Film Grain)
-- Wir definieren verschiedene Shader-Versionen für verschiedene Plattformen

-- HLSL-Shader für Windows (Standard)
-- Direkt eingebetteter Shader-Code ohne externe Abhängigkeiten

-- Korrigierter HLSL-Shader-Code mit funktionierenden Split-Toning, Schärfung und Bloom-Effekten
local hlsl_shader_code = [[
uniform float4x4 ViewProj;
uniform texture2d image;

// Plattform-Kompatibilität: fehlende HLSL-Intrinsics für GLSL/macOS bereitstellen
#ifdef GS_PLATFORM_OPENGL
#ifndef saturate
#define saturate(x) clamp(x, 0.0, 1.0)
#endif
#ifndef lerp
#define lerp(a,b,t) mix(a,b,t)
#endif
#ifndef frac
#define frac(x) fract(x)
#endif
#endif

// Grundlegende Korrekturen
uniform float exposure;
uniform float contrast;
uniform float brightness;
uniform float highlights;
uniform float shadows;
uniform float whites;
uniform float blacks;
// Ausbleich-Effekte
uniform float highlight_fade;
uniform float shadow_fade;
uniform float black_lift;

// Weißabgleich
uniform float temperature;
uniform float tint;

// Farbe
uniform float saturation;
uniform float vibrance;

// Split-Toning (neu)
uniform float split_shadows_hue;
uniform float split_shadows_sat;
uniform float split_highlights_hue;
uniform float split_highlights_sat;
uniform float split_balance;

// Schärfung (neu)
uniform float sharpen_amount;
uniform float sharpen_radius;

// Bloom (neu)
uniform float bloom_amount;
uniform float bloom_threshold;

// Texel-Size für Schärfung und Bloom
uniform float width;
uniform float height;

// Vignette-Effekt
uniform float vignette_amount;
uniform float vignette_radius;
uniform float vignette_feather;
uniform float vignette_shape;  // 0.0 = Kreis, 1.0 = Mehr rechteckig

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

// Hilfsfunktion für Vibrance
float3 apply_vibrance(float3 color, float vibrance_value) {
    float luminance = dot(color, float3(0.2126, 0.7152, 0.0722));
    float maximum = max(max(color.r, color.g), color.b);
    float minimum = min(min(color.r, color.g), color.b);
    float saturation = (maximum - minimum) / max(maximum, 0.0001);
    
    return lerp(float3(luminance, luminance, luminance), color, 1.0 + (vibrance_value * (1.0 - saturation)));
}

// HSV <-> RGB Konvertierung für Split-Toning
float3 hsv_to_rgb(float3 hsv) {
    float h = hsv.x;
    float s = hsv.y;
    float v = hsv.z;
    
    if (s <= 0.0) return float3(v, v, v);
    
    h = frac(h) * 6.0;
    int i = int(h);
    float f = h - float(i);
    float p = v * (1.0 - s);
    float q = v * (1.0 - s * f);
    float t = v * (1.0 - s * (1.0 - f));
    
    if (i == 0) return float3(v, t, p);
    else if (i == 1) return float3(q, v, p);
    else if (i == 2) return float3(p, v, t);
    else if (i == 3) return float3(p, q, v);
    else if (i == 4) return float3(t, p, v);
    else return float3(v, p, q);
}

// Split-Toning anwenden
float3 apply_split_toning(float3 color, float shadows_hue, float shadows_sat, float highlights_hue, float highlights_sat, float balance) {
    float luminance = dot(color, float3(0.2126, 0.7152, 0.0722));
    
    // Balance-Faktor anwenden (-1 bis +1 zu 0 bis 1)
    float highlights_weight = saturate(luminance + balance * 0.5);
    float shadows_weight = 1.0 - highlights_weight;
    
    // Schatten-Farbe
    float3 shadows_color = hsv_to_rgb(float3(shadows_hue, shadows_sat, 1.0));
    
    // Lichter-Farbe
    float3 highlights_color = hsv_to_rgb(float3(highlights_hue, highlights_sat, 1.0));
    
    // Mische die Farben basierend auf Luminanz
    float3 toned_color = color * (1.0 - shadows_sat * shadows_weight - highlights_sat * highlights_weight)
                       + shadows_color * shadows_weight * shadows_sat
                       + highlights_color * highlights_weight * highlights_sat;
    
    return toned_color;
}

// Schärfung anwenden
float3 apply_sharpen(texture2d tex, float2 uv, float2 texel_size, float amount, float radius) {
    float3 center = tex.Sample(textureSampler, uv).rgb;
    
    // 5-Punkt-Laplace-Filter
    float3 blur = float3(0, 0, 0);
    blur += tex.Sample(textureSampler, uv + float2(-radius * texel_size.x, 0)).rgb;
    blur += tex.Sample(textureSampler, uv + float2(radius * texel_size.x, 0)).rgb;
    blur += tex.Sample(textureSampler, uv + float2(0, -radius * texel_size.y)).rgb;
    blur += tex.Sample(textureSampler, uv + float2(0, radius * texel_size.y)).rgb;
    blur *= 0.25;
    
    // Unschärfe-Maske
    float3 sharpen = center + (center - blur) * amount;
    
    return sharpen;
}

// Bloom-Effekt anwenden
float3 apply_bloom(texture2d tex, float2 uv, float2 texel_size, float amount, float threshold) {
    float3 color = tex.Sample(textureSampler, uv).rgb;
    
    // Extrahiere helle Bereiche über dem Schwellenwert
    float brightness = dot(color, float3(0.2126, 0.7152, 0.0722));
    float3 bright_pass = color * saturate(brightness - threshold);
    
    // Einfacher 9-Punkt-Blur für Bloom
    float3 bloom = float3(0, 0, 0);
    float total_weight = 0.0;
    
    for (int y = -2; y <= 2; y++) {
        for (int x = -2; x <= 2; x++) {
            float weight = 1.0 / (1.0 + x*x + y*y);
            float2 offset = float2(x, y) * texel_size * 2.0;
            bloom += tex.Sample(textureSampler, uv + offset).rgb * weight * saturate(brightness - threshold);
            total_weight += weight;
        }
    }
    
    bloom /= total_weight;
    
    // Addiere den Bloom-Effekt zur Originalfarbe
    return color + bloom * amount;
}

// Vignette-Effekt anwenden
float3 apply_vignette(float3 color, float2 uv, float amount, float radius, float feather, float shape) {
    // Zentriere die UV-Koordinaten
    float2 centered_uv = uv - 0.5;
    
    // Passe die Form an (0 = Kreis, 1 = mehr rechteckig)
    float2 shaped_uv = pow(abs(centered_uv), float2(2.0 - shape * 0.5, 2.0 - shape * 0.5));
    float dist = pow(shaped_uv.x + shaped_uv.y, 1.0 / (2.0 - shape * 0.5));
    
    // Berechne den Vignette-Faktor
    float vignette = smoothstep(radius, radius - feather, dist);
    vignette = 1.0 - (1.0 - vignette) * amount;
    
    return color * vignette;
}

// Farbrad-Anwendung
float3 apply_color_balance(float3 color, float3 shadows_color, float3 midtones_color, float3 highlights_color) {
    // Luminanz berechnen
    float luma = dot(color, float3(0.2126, 0.7152, 0.0722));
    
    // Gewichtung basierend auf Luminanz
    float3 weights;
    weights.x = saturate(1.0 - luma * 2.0);           // Schatten: 1.0 bei Luminanz 0, 0.0 bei Luminanz 0.5+
    weights.y = saturate(1.0 - abs(luma - 0.5) * 2.0); // Mitteltöne: 1.0 bei Luminanz 0.5, 0.0 bei 0 und 1
    weights.z = saturate((luma - 0.5) * 2.0);         // Lichter: 1.0 bei Luminanz 1, 0.0 bei Luminanz 0.5-
    
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
    
    // Schwarzwert-Anhebung (Black Lift)
    if (black_lift > 0.0) {
        float lift_amount = black_lift * 0.5; // Maximale Anhebung von 0.5
        float lift_mask = 1.0 - smoothstep(0.0, 0.4, result);
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
    float3 shadows_col = float3(shadows_color_r, shadows_color_g, shadows_color_b);
    float3 midtones_col = float3(midtones_color_r, midtones_color_g, midtones_color_b);
    float3 highlights_col = float3(highlights_color_r, highlights_color_g, highlights_color_b);
    result = apply_color_balance(result, shadows_col, midtones_col, highlights_col);
    
    // Sättigung und Lebendigkeit
    result = apply_saturation(result, saturation);
    result = apply_vibrance(result, vibrance);
    
    // Split-Toning anwenden
    if (split_shadows_sat > 0.0 || split_highlights_sat > 0.0) {
        result = apply_split_toning(result, split_shadows_hue, split_shadows_sat, split_highlights_hue, split_highlights_sat, split_balance);
    }
    
    // Schärfung anwenden
    if (sharpen_amount > 0.0) {
        float2 texel_size = float2(1.0 / width, 1.0 / height);
        result = apply_sharpen(image, v_in.uv, texel_size, sharpen_amount, sharpen_radius);
    }
    
    // Bloom anwenden
    if (bloom_amount > 0.0) {
        float2 texel_size = float2(1.0 / width, 1.0 / height);
        result = apply_bloom(image, v_in.uv, texel_size, bloom_amount, bloom_threshold);
    }
    
    // Vignette anwenden
    if (vignette_amount > 0.0) {
        result = apply_vignette(result, v_in.uv, vignette_amount, vignette_radius, vignette_feather, vignette_shape);
    }
    
    // Film Grain wurde entfernt - es verursachte "tickendes" Verhalten
    
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

-- Wir verwenden keinen Metal-Shader mehr, da er zu Syntaxproblemen führt

-- Verbesserter GLSL-Shader für macOS mit erweiterten Kompatibilitätsdefinitionen
local glsl_shader_code = [[
uniform mat4 ViewProj;
uniform sampler2d image;

// Erweiterte Kompatibilitätsdefinitionen für macOS GLSL
#ifdef GS_PLATFORM_OPENGL
#ifndef saturate
#define saturate(x) clamp(x, 0.0, 1.0)
#endif
#ifndef lerp
#define lerp(a,b,t) mix(a,b,t)
#endif
#ifndef frac
#define frac(x) fract(x)
#endif
#ifndef float2
#define float2 vec2
#endif
#ifndef float3
#define float3 vec3
#endif
#ifndef float4
#define float4 vec4
#endif
#ifndef float4x4
#define float4x4 mat4
#endif
#ifndef texture2d
#define texture2d sampler2D
#endif
#ifndef sampler_state
#define sampler_state
#endif
#ifndef Sample
#define Sample(texture, coord) texture(texture, coord)
#endif
#ifndef TARGET
#define TARGET
#endif
#endif

// Uniforms für Farbkorrektur
uniform float exposure;
uniform float contrast;
uniform float brightness;
uniform float highlights;
uniform float shadows;
uniform float whites;
uniform float blacks;
uniform float highlight_fade;
uniform float shadow_fade;
uniform float black_lift;
uniform float temperature;
uniform float tint;
uniform float saturation;
uniform float vibrance;
uniform float vignette_amount;
uniform float vignette_radius;
uniform float vignette_feather;
uniform float vignette_shape;
uniform float grain_amount;
uniform float grain_size;
uniform float time_seed;
// Split-Toning
uniform float split_shadows_hue;
uniform float split_shadows_sat;
uniform float split_highlights_hue;
uniform float split_highlights_sat;
uniform float split_balance;
// Schärfung
uniform float sharpen_amount;
uniform float sharpen_radius;
// Bloom
uniform float bloom_amount;
uniform float bloom_threshold;
// Texel-Size
uniform float width;
uniform float height;

// Farbrad-Parameter
uniform float shadows_color_r;
uniform float shadows_color_g;
uniform float shadows_color_b;
uniform float midtones_color_r;
uniform float midtones_color_g;
uniform float midtones_color_b;
uniform float highlights_color_r;
uniform float highlights_color_g;
uniform float highlights_color_b;

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

// Hilfsfunktionen
float3 rgb_to_hsv(float3 rgb)
{
    float4 K = float4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
    float4 p = mix(float4(rgb.bg, K.wz), float4(rgb.gb, K.xy), step(rgb.b, rgb.g));
    float4 q = mix(float4(p.xyw, rgb.r), float4(rgb.r, p.yzx), step(p.x, rgb.r));
    
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 hsv_to_rgb(float3 hsv)
{
    float4 K = float4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    float3 p = abs(frac(hsv.xxx + K.xyz) * 6.0 - K.www);
    return hsv.z * mix(K.xxx, saturate(p - K.xxx), hsv.y);
}

float3 apply_contrast(float3 color, float contrast_value)
{
    float midpoint = 0.5;
    return saturate((color - midpoint) * (1.0 + contrast_value) + midpoint);
}

float3 apply_temperature(float3 color, float temp, float tint_value)
{
    // Temperatur-Anpassung
    float3 warm = float3(0.95, 0.92, 0.88);
    float3 cool = float3(0.88, 0.92, 0.95);
    float3 target = (temp > 0.0) ? warm : cool;
    float temp_abs = abs(temp);
    color = lerp(color, color * target, temp_abs * 0.1);
    
    // Tint-Anpassung (Grün-Magenta)
    float3 tint_target = (tint_value > 0.0) ? float3(0.96, 1.0, 0.96) : float3(1.0, 0.96, 1.0);
    float tint_abs = abs(tint_value);
    color = lerp(color, color * tint_target, tint_abs * 0.1);
    
    return color;
}

float3 apply_saturation(float3 color, float sat)
{
    float luma = dot(color, float3(0.2126, 0.7152, 0.0722));
    return lerp(float3(luma, luma, luma), color, 1.0 + sat);
}

float3 apply_vibrance(float3 color, float vib)
{
    float max_color = max(color.r, max(color.g, color.b));
    float min_color = min(color.r, min(color.g, color.b));
    float sat = (max_color - min_color) / max(max_color, 0.001);
    float vibrance_amount = 1.0 + (vib * (1.0 - sat));
    return lerp(float3(dot(color, float3(0.299, 0.587, 0.114))), color, vibrance_amount);
}

float3 apply_vignette(float3 color, float2 uv, float amount, float radius, float feather, float shape)
{
    float2 center = float2(0.5, 0.5);
    float2 coord = uv - center;
    
    // Elliptische Form basierend auf shape-Parameter
    float aspect = 16.0 / 9.0; // Standard-Seitenverhältnis
    coord.x *= lerp(1.0, aspect, shape);
    
    float dist = length(coord);
    float vignette_mask = smoothstep(radius, radius - feather, dist);
    vignette_mask = pow(vignette_mask, 2.0); // Für weichere Kanten
    
    return color * (1.0 - amount + vignette_mask * amount);
}

// Farbbalance basierend auf Luminanz
float3 apply_color_balance(float3 color, float3 shadows_col, float3 midtones_col, float3 highlights_col)
{
    float luma = dot(color, float3(0.2126, 0.7152, 0.0722));
    
    // Gewichtung für Schatten, Mitteltöne und Lichter
    float shadows_weight = 1.0 - smoothstep(0.0, 0.5, luma);
    float highlights_weight = smoothstep(0.5, 1.0, luma);
    float midtones_weight = 1.0 - shadows_weight - highlights_weight;
    
    // Farbbalance anwenden
    float3 shadows_adj = lerp(float3(1.0, 1.0, 1.0), shadows_col, shadows_weight * 0.2);
    float3 midtones_adj = lerp(float3(1.0, 1.0, 1.0), midtones_col, midtones_weight * 0.2);
    float3 highlights_adj = lerp(float3(1.0, 1.0, 1.0), highlights_col, highlights_weight * 0.2);
    
    return color * shadows_adj * midtones_adj * highlights_adj;
}

float3 apply_split_toning(float3 color, float shadows_hue, float shadows_sat, float highlights_hue, float highlights_sat, float balance)
{
    float luminance = dot(color, float3(0.2126, 0.7152, 0.0722));
    float highlights_weight = saturate(luminance + balance * 0.5);
    float shadows_weight = 1.0 - highlights_weight;
    float3 shadows_color = hsv_to_rgb(float3(shadows_hue, shadows_sat, 1.0));
    float3 highlights_color = hsv_to_rgb(float3(highlights_hue, highlights_sat, 1.0));
    float3 toned_color = color * (1.0 - shadows_sat * shadows_weight - highlights_sat * highlights_weight)
                       + shadows_color * shadows_weight * shadows_sat
                       + highlights_color * highlights_weight * highlights_sat;
    return toned_color;
}

float3 apply_sharpen(sampler2D tex, vec2 uv, vec2 texel_size, float amount, float radius)
{
    vec3 center = texture(tex, uv).rgb;
    vec3 blur = vec3(0.0);
    blur += texture(tex, uv + vec2(-radius * texel_size.x, 0.0)).rgb;
    blur += texture(tex, uv + vec2( radius * texel_size.x, 0.0)).rgb;
    blur += texture(tex, uv + vec2(0.0, -radius * texel_size.y)).rgb;
    blur += texture(tex, uv + vec2(0.0,  radius * texel_size.y)).rgb;
    blur *= 0.25;
    return center + (center - blur) * amount;
}

float3 apply_bloom(sampler2D tex, vec2 uv, vec2 texel_size, float amount, float threshold)
{
    vec3 color = texture(tex, uv).rgb;
    float brightness = dot(color, vec3(0.2126, 0.7152, 0.0722));
    vec3 bloom = vec3(0.0);
    float total_weight = 0.0;
    for (int y = -2; y <= 2; y++) {
        for (int x = -2; x <= 2; x++) {
            float weight = 1.0 / (1.0 + x*x + y*y);
            vec2 offset = vec2(x, y) * texel_size * 2.0;
            bloom += texture(tex, uv + offset).rgb * weight * saturate(brightness - threshold);
            total_weight += weight;
        }
    }
    bloom /= total_weight;
    return color + bloom * amount;
}

float4 PSDefault(VertDataOut v_in) : TARGET
{
    float4 color = texture(image, v_in.uv);
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
        float whites_amount = whites * 0.05;
        float whites_mask = smoothstep(0.7, 1.0, result);
        result = lerp(result, saturate(result + whites_amount), whites_mask);
    }
    if (blacks != 0.0) {
        float blacks_amount = blacks * 0.05;
        float blacks_mask = 1.0 - smoothstep(0.0, 0.3, result);
        result = lerp(result, saturate(result - blacks_amount), blacks_mask);
    }

    // Schwarzanhebung
    if (black_lift > 0.0) {
        float lift_amount = black_lift * 0.5; // Maximale Anhebung von 0.5
        float lift_mask = 1.0 - smoothstep(0.0, 0.4, result);
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
    float3 shadows_col = float3(shadows_color_r, shadows_color_g, shadows_color_b);
    float3 midtones_col = float3(midtones_color_r, midtones_color_g, midtones_color_b);
    float3 highlights_col = float3(highlights_color_r, highlights_color_g, highlights_color_b);
    result = apply_color_balance(result, shadows_col, midtones_col, highlights_col);

    // Sättigung und Lebendigkeit
    result = apply_saturation(result, saturation);
    result = apply_vibrance(result, vibrance);

    // Split-Toning anwenden
    if (split_shadows_sat > 0.0 || split_highlights_sat > 0.0) {
        result = apply_split_toning(result, split_shadows_hue, split_shadows_sat, split_highlights_hue, split_highlights_sat, split_balance);
    }

    // Schärfung anwenden
    if (sharpen_amount > 0.0) {
        vec2 texel_size = vec2(1.0 / width, 1.0 / height);
        result = apply_sharpen(image, v_in.uv, texel_size, sharpen_amount, sharpen_radius);
    }

    // Bloom anwenden
    if (bloom_amount > 0.0) {
        vec2 texel_size = vec2(1.0 / width, 1.0 / height);
        result = apply_bloom(image, v_in.uv, texel_size, bloom_amount, bloom_threshold);
    }

    // Vignette anwenden
    if (vignette_amount > 0.0) {
        result = apply_vignette(result, v_in.uv, vignette_amount, vignette_radius, vignette_feather, vignette_shape);
    }
    
    // Film Grain wurde entfernt - es verursachte "tickendes" Verhalten
    
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
        if data.last_exposure ~= data.exposure then
            obs.gs_effect_set_float(data.params.exposure, data.exposure)
            data.last_exposure = data.exposure
        end
    end
    if data.params.contrast then 
        if data.last_contrast ~= data.contrast then
            obs.gs_effect_set_float(data.params.contrast, data.contrast)
            data.last_contrast = data.contrast
        end
    end
    if data.params.brightness then 
        if data.last_brightness ~= data.brightness then
            obs.gs_effect_set_float(data.params.brightness, data.brightness)
            data.last_brightness = data.brightness
        end
    end
    if data.params.highlights then 
        if data.last_highlights ~= data.highlights then
            obs.gs_effect_set_float(data.params.highlights, data.highlights)
            data.last_highlights = data.highlights
        end
    end
    if data.params.shadows then 
        if data.last_shadows ~= data.shadows then
            obs.gs_effect_set_float(data.params.shadows, data.shadows)
            data.last_shadows = data.shadows
        end
    end
    if data.params.whites then 
        if data.last_whites ~= data.whites then
            obs.gs_effect_set_float(data.params.whites, data.whites)
            data.last_whites = data.whites
        end
    end
    if data.params.blacks then 
        if data.last_blacks ~= data.blacks then
            obs.gs_effect_set_float(data.params.blacks, data.blacks)
            data.last_blacks = data.blacks
        end
    end
    if data.params.temperature then 
        if data.last_temperature ~= data.temperature then
            obs.gs_effect_set_float(data.params.temperature, data.temperature)
            data.last_temperature = data.temperature
        end
    end
    if data.params.tint then 
        if data.last_tint ~= data.tint then
            obs.gs_effect_set_float(data.params.tint, data.tint)
            data.last_tint = data.tint
        end
    end
    if data.params.saturation then 
        if data.last_saturation ~= data.saturation then
            obs.gs_effect_set_float(data.params.saturation, data.saturation)
            data.last_saturation = data.saturation
        end
    end
    if data.params.vibrance then 
        if data.last_vibrance ~= data.vibrance then
            obs.gs_effect_set_float(data.params.vibrance, data.vibrance)
            data.last_vibrance = data.vibrance
        end
    end
    if data.params.vignette_amount then 
        if data.last_vignette_amount ~= data.vignette_amount then
            obs.gs_effect_set_float(data.params.vignette_amount, data.vignette_amount)
            data.last_vignette_amount = data.vignette_amount
        end
    end
    if data.params.vignette_radius then 
        if data.last_vignette_radius ~= data.vignette_radius then
            obs.gs_effect_set_float(data.params.vignette_radius, data.vignette_radius)
            data.last_vignette_radius = data.vignette_radius
        end
    end
    if data.params.vignette_feather then 
        if data.last_vignette_feather ~= data.vignette_feather then
            obs.gs_effect_set_float(data.params.vignette_feather, data.vignette_feather)
            data.last_vignette_feather = data.vignette_feather
        end
    end
    if data.params.vignette_shape then 
        if data.last_vignette_shape ~= data.vignette_shape then
            obs.gs_effect_set_float(data.params.vignette_shape, data.vignette_shape)
            data.last_vignette_shape = data.vignette_shape
        end
    end
    if data.params.grain_amount then 
        if data.last_grain_amount ~= data.grain_amount then
            obs.gs_effect_set_float(data.params.grain_amount, data.grain_amount)
            data.last_grain_amount = data.grain_amount
        end
    end
    if data.params.grain_size then 
        if data.last_grain_size ~= data.grain_size then
            obs.gs_effect_set_float(data.params.grain_size, data.grain_size)
            data.last_grain_size = data.grain_size
        end
    end
    if data.params.highlight_fade then 
        if data.last_highlight_fade ~= data.highlight_fade then
            obs.gs_effect_set_float(data.params.highlight_fade, data.highlight_fade)
            data.last_highlight_fade = data.highlight_fade
        end
    end
    if data.params.shadow_fade then 
        if data.last_shadow_fade ~= data.shadow_fade then
            obs.gs_effect_set_float(data.params.shadow_fade, data.shadow_fade)
            data.last_shadow_fade = data.shadow_fade
        end
    end
    if data.params.time_seed then 
        if data.last_time_seed ~= data.time_seed then
            obs.gs_effect_set_float(data.params.time_seed, data.time_seed)
            data.last_time_seed = data.time_seed
        end
    end
    
    if data.params.black_lift then 
        if data.last_black_lift ~= data.black_lift then
            obs.gs_effect_set_float(data.params.black_lift, data.black_lift)
            data.last_black_lift = data.black_lift
        end
    end
    
    -- Split-Toning Parameter setzen
    if data.params.split_shadows_hue then 
        if data.last_split_shadows_hue ~= data.split_shadows_hue then
            obs.gs_effect_set_float(data.params.split_shadows_hue, data.split_shadows_hue)
            data.last_split_shadows_hue = data.split_shadows_hue
        end
    end
    
    if data.params.split_shadows_sat then 
        if data.last_split_shadows_sat ~= data.split_shadows_sat then
            obs.gs_effect_set_float(data.params.split_shadows_sat, data.split_shadows_sat)
            data.last_split_shadows_sat = data.split_shadows_sat
        end
    end
    
    if data.params.split_highlights_hue then 
        if data.last_split_highlights_hue ~= data.split_highlights_hue then
            obs.gs_effect_set_float(data.params.split_highlights_hue, data.split_highlights_hue)
            data.last_split_highlights_hue = data.split_highlights_hue
        end
    end
    
    if data.params.split_highlights_sat then 
        if data.last_split_highlights_sat ~= data.split_highlights_sat then
            obs.gs_effect_set_float(data.params.split_highlights_sat, data.split_highlights_sat)
            data.last_split_highlights_sat = data.split_highlights_sat
        end
    end
    
    if data.params.split_balance then 
        if data.last_split_balance ~= data.split_balance then
            obs.gs_effect_set_float(data.params.split_balance, data.split_balance)
            data.last_split_balance = data.split_balance
        end
    end
    
    -- Schärfung und Bloom Parameter setzen
    if data.params.sharpen_amount then 
        if data.last_sharpen_amount ~= data.sharpen_amount then
            obs.gs_effect_set_float(data.params.sharpen_amount, data.sharpen_amount)
            data.last_sharpen_amount = data.sharpen_amount
        end
    end
    
    if data.params.sharpen_radius then 
        if data.last_sharpen_radius ~= data.sharpen_radius then
            obs.gs_effect_set_float(data.params.sharpen_radius, data.sharpen_radius)
            data.last_sharpen_radius = data.sharpen_radius
        end
    end
    
    if data.params.bloom_amount then 
        if data.last_bloom_amount ~= data.bloom_amount then
            obs.gs_effect_set_float(data.params.bloom_amount, data.bloom_amount)
            data.last_bloom_amount = data.bloom_amount
        end
    end
    
    if data.params.bloom_threshold then 
        if data.last_bloom_threshold ~= data.bloom_threshold then
            obs.gs_effect_set_float(data.params.bloom_threshold, data.bloom_threshold)
            data.last_bloom_threshold = data.bloom_threshold
        end
    end
    
    -- Texel-Size für Schärfung und Bloom
    local width_param = obs.gs_effect_get_param_by_name(data.effect, "width")
    local height_param = obs.gs_effect_get_param_by_name(data.effect, "height")
    
    if width_param and height_param then
        local source = obs.obs_filter_get_target(data.source)
        local source_width = 1920  -- Fallback
        local source_height = 1080 -- Fallback
        
        if source then
            source_width = obs.obs_source_get_base_width(source)
            source_height = obs.obs_source_get_base_height(source)
        end
        
        if source_width <= 0 or source_height <= 0 then
            -- Versuche es mit der Parent-Quelle
            local parent = obs.obs_filter_get_parent(data.source)
            if parent then
                source_width = obs.obs_source_get_base_width(parent)
                source_height = obs.obs_source_get_base_height(parent)
            end
            
            -- Wenn immer noch ungültig, verwende Fallback und reduziere Log-Spam
            if source_width <= 0 or source_height <= 0 then
                -- Nur alle 5 Sekunden loggen, um Spam zu vermeiden
                local current_time = get_time_s()
                if not data.last_size_log_time or (current_time - data.last_size_log_time) > 5 then
                    log_debug("Target hat keine gültige Größe, verwende Fallback: 1920x1080")
                    data.last_size_log_time = current_time
                end
                source_width = 1920
                source_height = 1080
            end
        end
        
        obs.gs_effect_set_float(width_param, source_width)
        obs.gs_effect_set_float(height_param, source_height)
    end
    
    -- Farbrad-Parameter setzen (nur wenn sie existieren)
    if data.params.shadows_color_r and data.shadows_color_r ~= nil then 
        if data.last_shadows_color_r ~= data.shadows_color_r then
            obs.gs_effect_set_float(data.params.shadows_color_r, data.shadows_color_r)
            data.last_shadows_color_r = data.shadows_color_r
        end
    end
    if data.params.shadows_color_g and data.shadows_color_g ~= nil then 
        if data.last_shadows_color_g ~= data.shadows_color_g then
            obs.gs_effect_set_float(data.params.shadows_color_g, data.shadows_color_g)
            data.last_shadows_color_g = data.shadows_color_g
        end
    end
    if data.params.shadows_color_b and data.shadows_color_b ~= nil then 
        if data.last_shadows_color_b ~= data.shadows_color_b then
            obs.gs_effect_set_float(data.params.shadows_color_b, data.shadows_color_b)
            data.last_shadows_color_b = data.shadows_color_b
        end
    end
    
    if data.params.midtones_color_r and data.midtones_color_r ~= nil then 
        if data.last_midtones_color_r ~= data.midtones_color_r then
            obs.gs_effect_set_float(data.params.midtones_color_r, data.midtones_color_r)
            data.last_midtones_color_r = data.midtones_color_r
        end
    end
    if data.params.midtones_color_g and data.midtones_color_g ~= nil then 
        if data.last_midtones_color_g ~= data.midtones_color_g then
            obs.gs_effect_set_float(data.params.midtones_color_g, data.midtones_color_g)
            data.last_midtones_color_g = data.midtones_color_g
        end
    end
    if data.params.midtones_color_b and data.midtones_color_b ~= nil then 
        if data.last_midtones_color_b ~= data.midtones_color_b then
            obs.gs_effect_set_float(data.params.midtones_color_b, data.midtones_color_b)
            data.last_midtones_color_b = data.midtones_color_b
        end
    end
    
    if data.params.highlights_color_r and data.highlights_color_r ~= nil then 
        if data.last_highlights_color_r ~= data.highlights_color_r then
            obs.gs_effect_set_float(data.params.highlights_color_r, data.highlights_color_r)
            data.last_highlights_color_r = data.highlights_color_r
        end
    end
    if data.params.highlights_color_g and data.highlights_color_g ~= nil then 
        if data.last_highlights_color_g ~= data.highlights_color_g then
            obs.gs_effect_set_float(data.params.highlights_color_g, data.highlights_color_g)
            data.last_highlights_color_g = data.highlights_color_g
        end
    end
    if data.params.highlights_color_b and data.highlights_color_b ~= nil then 
        if data.last_highlights_color_b ~= data.highlights_color_b then
            obs.gs_effect_set_float(data.params.highlights_color_b, data.highlights_color_b)
            data.last_highlights_color_b = data.highlights_color_b
        end
    end
    
    -- Nur für die Preview-Textur explizit setzen
    if data.target_texture == nil and data.params.image and data.preview_texture then
        obs.gs_effect_set_texture(data.params.image, data.preview_texture)
    end
end

-- Hilfsfunktion für Debug-Log-Funktion mit erweiterten Informationen
local function log_debug(message)
    if DEBUG then
        local platform_info = IS_MACOS and "[macOS]" or "[Windows]"
        print("[Lumetric Corrector] " .. platform_info .. " " .. message)
    end
end

-- Erweiterte Fehlerbehandlung für Shader
local function handle_shader_error()
    local error = obs.gs_get_last_error()
    if error ~= nil then
        log_debug("Shader-Fehler: " .. error)
        return error
    else
        log_debug("Unbekannter Shader-Fehler ohne Fehlermeldung")
        return "Unbekannter Fehler"
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
    return _("lumetric_corrector") .. " - " .. "v1.3.0"
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
    
    -- Instanzspezifischen Zeitsamen aktualisieren
    -- time_seed nur 1× pro Sekunde aktualisieren
    local now = get_time_s()
    if (not data.last_seed_ts) or ((now - data.last_seed_ts) >= 1) then
        data.time_seed    = now
        data.last_seed_ts = now
        data.dirty        = true
    end
    
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
    
    local prop_highlight_fade = obs.obs_properties_add_float_slider(exposure_group, "highlight_fade", _("highlight_fade"), 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_highlight_fade, "Lichter ausbleichen. Höhere Werte lassen helle Bereiche weißer erscheinen.")
    
    local prop_shadow_fade = obs.obs_properties_add_float_slider(exposure_group, "shadow_fade", _("shadow_fade"), 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_shadow_fade, "Schatten ausbleichen. Höhere Werte lassen dunkle Bereiche heller erscheinen.")
    
    local prop_black_lift = obs.obs_properties_add_float_slider(exposure_group, "black_lift", _("black_lift"), 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_black_lift, "Schwarzwert-Anhebung. Höhere Werte heben den Schwarzpunkt an und machen dunkle Bereiche heller.")
    
    -- Gruppen-ID nicht wie Parameter benennen, um Konflikte zu vermeiden
    obs.obs_properties_add_group(props, "basic_settings", _("basic"), obs.OBS_GROUP_NORMAL, exposure_group)
    
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
    
    -- Split-Toning
    local split_toning_group = obs.obs_properties_create()
    
    local prop_split_shadows_hue = obs.obs_properties_add_float_slider(split_toning_group, "split_shadows_hue", "Schatten Farbton", 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_split_shadows_hue, "Farbton für die Schatten beim Split-Toning. 0=Rot, 0.33=Grün, 0.66=Blau.")
    
    local prop_split_shadows_sat = obs.obs_properties_add_float_slider(split_toning_group, "split_shadows_sat", "Schatten Sättigung", 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_split_shadows_sat, "Sättigung der Farbe für die Schatten beim Split-Toning.")
    
    local prop_split_highlights_hue = obs.obs_properties_add_float_slider(split_toning_group, "split_highlights_hue", "Lichter Farbton", 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_split_highlights_hue, "Farbton für die Lichter beim Split-Toning. 0=Rot, 0.33=Grün, 0.66=Blau.")
    
    local prop_split_highlights_sat = obs.obs_properties_add_float_slider(split_toning_group, "split_highlights_sat", "Lichter Sättigung", 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_split_highlights_sat, "Sättigung der Farbe für die Lichter beim Split-Toning.")
    
    local prop_split_balance = obs.obs_properties_add_float_slider(split_toning_group, "split_balance", "Balance", -1.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_split_balance, "Balance zwischen Schatten und Lichtern beim Split-Toning. Negative Werte verschieben die Balance zu den Schatten, positive zu den Lichtern.")
    
    obs.obs_properties_add_group(props, "split_toning", "Split-Toning", obs.OBS_GROUP_NORMAL, split_toning_group)
    
    -- Schärfung und Bloom
    local effects_group = obs.obs_properties_create()
    
    local prop_sharpen_amount = obs.obs_properties_add_float_slider(effects_group, "sharpen_amount", "Schärfung", 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_sharpen_amount, "Stärke der Schärfung. Höhere Werte führen zu schärferen Kanten.")
    
    local prop_sharpen_radius = obs.obs_properties_add_float_slider(effects_group, "sharpen_radius", "Schärfungsradius", 1.0, 3.0, 0.1)
    obs.obs_property_set_long_description(prop_sharpen_radius, "Radius der Schärfung. Höhere Werte führen zu breiteren Kanten.")
    
    local prop_bloom_amount = obs.obs_properties_add_float_slider(effects_group, "bloom_amount", "Bloom-Stärke", 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_bloom_amount, "Stärke des Bloom-Effekts. Höhere Werte führen zu stärkerem Leuchten.")
    
    local prop_bloom_threshold = obs.obs_properties_add_float_slider(effects_group, "bloom_threshold", "Bloom-Schwellenwert", 0.5, 0.95, 0.01)
    obs.obs_property_set_long_description(prop_bloom_threshold, "Schwellenwert für den Bloom-Effekt. Nur Pixel über diesem Helligkeitswert werden zum Leuchten gebracht.")
    
    obs.obs_properties_add_group(props, "effects", "Effekte", obs.OBS_GROUP_NORMAL, effects_group)
    
    -- Vignette
    local vignette_group = obs.obs_properties_create()
    
    local prop_vignette_amount = obs.obs_properties_add_float_slider(vignette_group, "vignette_amount", _("vignette_amount"), 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_vignette_amount, "Stärke der Vignette. Positive Werte erhöhen die Vignette, negative Werte verringern sie.")
    
    local prop_vignette_radius = obs.obs_properties_add_float_slider(vignette_group, "vignette_radius", _("vignette_radius"), 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_vignette_radius, "Radius der Vignette. Positive Werte erhöhen den Radius, negative Werte verringern ihn.")
    
    local prop_vignette_feather = obs.obs_properties_add_float_slider(vignette_group, "vignette_feather", _("vignette_feather"), 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_vignette_feather, "Weichzeichnung der Vignette. Positive Werte erhöhen die Weichzeichnung, negative Werte verringern sie.")
    
    local prop_vignette_shape = obs.obs_properties_add_float_slider(vignette_group, "vignette_shape", "Vignette Form", 0.0, 1.0, 0.01)
    obs.obs_property_set_long_description(prop_vignette_shape, "Form der Vignette. 0 = Kreisförmig, 1 = Ovaler/Rechteckiger.")
    
    obs.obs_properties_add_group(props, "vignette", _("vignette"), obs.OBS_GROUP_NORMAL, vignette_group)
    
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
    obs.obs_data_set_default_double(settings, "vignette_shape", 0.0)
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
    
    -- Split-Toning Standardwerte
    obs.obs_data_set_default_double(settings, "split_shadows_hue", 0.6) -- Bläulich
    obs.obs_data_set_default_double(settings, "split_shadows_sat", 0.0)
    obs.obs_data_set_default_double(settings, "split_highlights_hue", 0.1) -- Gelblich/Orange
    obs.obs_data_set_default_double(settings, "split_highlights_sat", 0.0)
    obs.obs_data_set_default_double(settings, "split_balance", 0.0)
    
    -- Effekte Standardwerte
    obs.obs_data_set_default_double(settings, "sharpen_amount", 0.0)
    obs.obs_data_set_default_double(settings, "sharpen_radius", 1.0)
    obs.obs_data_set_default_double(settings, "bloom_amount", 0.0)
    obs.obs_data_set_default_double(settings, "bloom_threshold", 0.8)
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
    data.vignette_shape = obs.obs_data_get_double(settings, "vignette_shape")
    data.grain_amount = obs.obs_data_get_double(settings, "grain_amount")
    data.grain_size = obs.obs_data_get_double(settings, "grain_size")
    data.highlight_fade = obs.obs_data_get_double(settings, "highlight_fade")
    data.shadow_fade = obs.obs_data_get_double(settings, "shadow_fade")
    data.black_lift = obs.obs_data_get_double(settings, "black_lift")
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
    
    -- Split-Toning Parameter
    data.split_shadows_hue = obs.obs_data_get_double(settings, "split_shadows_hue")
    data.split_shadows_sat = obs.obs_data_get_double(settings, "split_shadows_sat")
    data.split_highlights_hue = obs.obs_data_get_double(settings, "split_highlights_hue")
    data.split_highlights_sat = obs.obs_data_get_double(settings, "split_highlights_sat")
    data.split_balance = obs.obs_data_get_double(settings, "split_balance")
    
    -- Effekt-Parameter
    data.sharpen_amount = obs.obs_data_get_double(settings, "sharpen_amount")
    data.sharpen_radius = obs.obs_data_get_double(settings, "sharpen_radius")
    data.bloom_amount = obs.obs_data_get_double(settings, "bloom_amount")
    data.bloom_threshold = obs.obs_data_get_double(settings, "bloom_threshold")
    
    -- Einstellungen speichern
    data.settings = settings

    -- Flag setzen, damit neue Uniform-Werte übertragen werden
    data.dirty = true

    -- Parameter sofort aktualisieren, damit Slider direkt wirken
    if data.effect and data.params then
        set_shader_params(data)
        data.dirty = false
    end
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
        if data.dirty then
            set_shader_params(data)
            data.dirty = false
        end
        
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
        if data.dirty then
            set_shader_params(data)
        end
        
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
    data.vignette_shape = 0.0
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
    
    -- Dirty-Flag & Seed-Timestamp für Optimierungen
    data.dirty = true
    data.last_seed_ts = 0
    
    -- Shader erstellen und Parameter abrufen
    obs.obs_enter_graphics()
    
    local function create_shader()
        local shader_code_to_use = hlsl_shader_code -- Standard für Windows
        local shader_type = "HLSL"
        
        -- Plattformspezifische Shader-Auswahl
        local platform = get_platform()
        if platform == "macos" then
            log_debug("macOS erkannt, verwende verbesserten GLSL-Shader")
            shader_code_to_use = glsl_shader_code
            shader_type = "GLSL"
        end
        
        -- Direkt eingebetteter korrigierter Shader-Code ohne externe Abhängigkeiten
        obs.blog(obs.LOG_INFO, "Verwende eingebetteten korrigierten Shader-Code")
        
        -- HLSL (Windows) oder GLSL (macOS) verwenden
        log_debug("Erstelle " .. shader_type .. "-Shader")
        local effect = obs.gs_effect_create(shader_code_to_use, "lumetric_shader", nil)
        if effect == nil then
            log_debug("Fehler beim Erstellen des " .. shader_type .. "-Shaders: " .. handle_shader_error())
        else
            log_debug(shader_type .. "-Shader erfolgreich erstellt")
        end
        return effect, shader_type
    end
    
    local success, err = pcall(function()
        data.effect, data.shader_type = create_shader()
        
        if data.effect ~= nil then
            log_debug("Shader vom Typ '" .. (data.shader_type or "unbekannt") .. "' wird verwendet")
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
            data.params.grain_amount = obs.gs_effect_get_param_by_name(data.effect, "grain_amount")
            data.params.grain_size = obs.gs_effect_get_param_by_name(data.effect, "grain_size")
            data.params.time_seed = obs.gs_effect_get_param_by_name(data.effect, "time_seed")
            data.params.highlight_fade = obs.gs_effect_get_param_by_name(data.effect, "highlight_fade")
            data.params.shadow_fade = obs.gs_effect_get_param_by_name(data.effect, "shadow_fade")
            data.params.black_lift = obs.gs_effect_get_param_by_name(data.effect, "black_lift")
            
            -- Split-Toning Parameter
            data.params.split_shadows_hue = obs.gs_effect_get_param_by_name(data.effect, "split_shadows_hue")
            data.params.split_shadows_sat = obs.gs_effect_get_param_by_name(data.effect, "split_shadows_sat")
            data.params.split_highlights_hue = obs.gs_effect_get_param_by_name(data.effect, "split_highlights_hue")
            data.params.split_highlights_sat = obs.gs_effect_get_param_by_name(data.effect, "split_highlights_sat")
            data.params.split_balance = obs.gs_effect_get_param_by_name(data.effect, "split_balance")
            
            -- Schärfung und Bloom Parameter
            data.params.sharpen_amount = obs.gs_effect_get_param_by_name(data.effect, "sharpen_amount")
            data.params.sharpen_radius = obs.gs_effect_get_param_by_name(data.effect, "sharpen_radius")
            data.params.bloom_amount = obs.gs_effect_get_param_by_name(data.effect, "bloom_amount")
            data.params.bloom_threshold = obs.gs_effect_get_param_by_name(data.effect, "bloom_threshold")
            
            -- Texel-Size Parameter für Schärfung und Bloom
            data.params.width = obs.gs_effect_get_param_by_name(data.effect, "width")
            data.params.height = obs.gs_effect_get_param_by_name(data.effect, "height")
            
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
