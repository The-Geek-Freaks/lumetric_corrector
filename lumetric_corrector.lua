--[[
  Lumetric Corrector für OBS Studio
  Farbkorrektur und Color Grading inspiriert von Adobe Lumetri Color

  Autor:   TheGeekFreaks
  Version: 3.0.0
  Lizenz:  GPLv3
  Quelle:  https://github.com/The-Geek-Freaks/lumetric_corrector
]]

local obs = obslua

local VERSION = "3.0.0"
local DEBUG = false

-- ---------------------------------------------------------------------------
-- Logging
-- ---------------------------------------------------------------------------
local function log_debug(msg) if DEBUG then obs.blog(obs.LOG_INFO, "[Lumetric] " .. tostring(msg)) end end
local function log_info(msg)  obs.blog(obs.LOG_INFO,    "[Lumetric] " .. tostring(msg)) end
local function log_warn(msg)  obs.blog(obs.LOG_WARNING, "[Lumetric] " .. tostring(msg)) end
local function log_error(msg) obs.blog(obs.LOG_ERROR,   "[Lumetric] " .. tostring(msg)) end

-- ---------------------------------------------------------------------------
-- Übersetzungen (Labels + Tooltips)
-- ---------------------------------------------------------------------------
local L10N = {
    ["en-US"] = {
        lumetric_corrector = "Lumetric Corrector",
        -- Gruppen
        presets = "Presets", tone = "Tone", fade = "Fade & Lift", wb = "White Balance", color = "Color",
        wheels = "Color Wheels (Lift / Gamma / Gain)", split = "Split Toning", fx = "Creative Effects",
        vignette = "Vignette", mask = "Mask (apply only inside a region)", lut = "3D LUT", looks = "Looks & LUT Export",
        -- Presets
        select_preset = "Preset", select_preset_desc = "Choosing a preset applies it immediately. Mask and LUT settings are kept.",
        apply_preset = "Apply preset again", reset_all = "Reset all settings",
        cat_basic = "── Basic ──", cat_style = "── Style ──", cat_mood = "── Mood ──", cat_era = "── Era ──", cat_creative = "── Creative ──",
        -- Regler
        exposure = "Exposure", exposure_desc = "Overall exposure in stops. +1 doubles the light, -1 halves it.",
        contrast = "Contrast", contrast_desc = "Expands or compresses tones around mid grey.",
        brightness = "Brightness", brightness_desc = "Shifts all tones up or down without changing contrast.",
        highlights = "Highlights", highlights_desc = "Brightens or recovers the bright parts of the image.",
        shadows = "Shadows", shadows_desc = "Lifts or deepens the dark parts of the image.",
        whites = "Whites", whites_desc = "Moves the white point. Negative values keep highlights from clipping.",
        blacks = "Blacks", blacks_desc = "Moves the black point. Negative values give denser blacks.",
        highlight_fade = "Highlight Fade", highlight_fade_desc = "Washes bright areas towards white (bleach look).",
        shadow_fade = "Shadow Fade", shadow_fade_desc = "Washes dark areas towards white for a soft, faded look.",
        black_lift = "Black Lift", black_lift_desc = "Raises the black point for a matte film look.",
        temperature = "Temperature", temperature_desc = "Positive = warmer (orange), negative = cooler (blue).",
        tint = "Tint", tint_desc = "Positive = magenta, negative = green.",
        saturation = "Saturation", saturation_desc = "Intensity of all colors. -1 gives black & white.",
        vibrance = "Vibrance", vibrance_desc = "Boosts muted colors more than already saturated ones.",
        shadows_color_r = "Shadows Red", shadows_color_g = "Shadows Green", shadows_color_b = "Shadows Blue",
        midtones_color_r = "Midtones Red", midtones_color_g = "Midtones Green", midtones_color_b = "Midtones Blue",
        highlights_color_r = "Highlights Red", highlights_color_g = "Highlights Green", highlights_color_b = "Highlights Blue",
        wheels_desc = "Adds or removes this color component in the given tonal range.",
        ss_r = "Shadows Red", ss_g = "Shadows Green", ss_b = "Shadows Blue", ss_sat = "Shadows Strength",
        sh_r = "Highlights Red", sh_g = "Highlights Green", sh_b = "Highlights Blue", sh_sat = "Highlights Strength",
        split_color_desc = "Color that is toned into this range. Only visible when the strength is above 0.",
        split_sat_desc = "How strongly the toning color is applied.",
        sharpen = "Sharpen", sharpen_desc = "Local sharpness (unsharp mask).",
        bloom = "Bloom", bloom_desc = "Soft glow around bright areas.",
        halation = "Halation", halation_desc = "Warm, reddish glow around highlights, like analog film.",
        grain_amount = "Film Grain", grain_amount_desc = "Animated film grain. Stronger in shadows than in highlights.",
        grain_size = "Grain Size", grain_size_desc = "Size of the grain in pixels (relative to 1080p).",
        vignette_amount = "Amount", vignette_amount_desc = "Darkening of the image corners.",
        vignette_radius = "Radius", vignette_radius_desc = "Where the darkening starts. Larger = smaller vignette.",
        vignette_feather = "Feather", vignette_feather_desc = "Softness of the vignette edge.",
        vignette_shape = "Shape", vignette_shape_desc = "0 = circular, 1 = wide oval.",
        mask_shape = "Shape", mask_round = "Ellipse", mask_rect = "Rectangle",
        mask_x = "Center X", mask_y = "Center Y", mask_width = "Width", mask_height = "Height",
        mask_feather = "Feather", mask_pos_desc = "Position of the mask center (0..1 of the image).",
        mask_size_desc = "Half size of the mask (0..1 of the image).", mask_feather_desc = "Soft edge of the mask.",
        lut_path = "LUT File", lut_path_desc = ".cube (any size) or .png (OBS 512x512 grid or N*N x N strip). Converted .cube files are cached in the OBS plugin_config folder.",
        lut_strength = "LUT Strength", lut_strength_desc = "Blend between the graded image and the LUT result.",
        lut_status = "LUT status",
        lut_export_path = "LUT export file", lut_export_path_desc = ".cube writes a 33x33x33 LUT, .png writes a 512x512 OBS-compatible LUT.",
        export_lut = "Export current look as LUT", export_lut_desc = "Bakes all color settings into a LUT. Spatial effects (bloom, halation, sharpen, grain, vignette, mask) cannot be part of a LUT.",
        look_export_path = "Look export file", save_look = "Save look (JSON)",
        look_import_path = "Look import file", load_look = "Load look (JSON)",
        look_desc = "Looks contain all color settings and can be shared between scenes, profiles and computers.",
        info_text = "Lumetric Corrector v%s — Tip: start with a preset, then fine-tune. Bloom, halation, sharpen and grain cost the most GPU time; leave them at 0 if you do not need them.",
    },
    ["de-DE"] = {
        lumetric_corrector = "Lumetric Korrektor",
        presets = "Voreinstellungen", tone = "Tonwerte", fade = "Ausbleichen & Anheben", wb = "Weißabgleich", color = "Farbe",
        wheels = "Farbräder (Lift / Gamma / Gain)", split = "Split-Toning", fx = "Kreative Effekte",
        vignette = "Vignette", mask = "Maske (nur innerhalb eines Bereichs anwenden)", lut = "3D LUT", looks = "Looks & LUT-Export",
        select_preset = "Voreinstellung", select_preset_desc = "Eine Voreinstellung wird sofort angewendet. Maske und LUT bleiben erhalten.",
        apply_preset = "Voreinstellung erneut anwenden", reset_all = "Alle Einstellungen zurücksetzen",
        cat_basic = "── Grundlegend ──", cat_style = "── Stil ──", cat_mood = "── Stimmung ──", cat_era = "── Ära ──", cat_creative = "── Kreativ ──",
        exposure = "Belichtung", exposure_desc = "Gesamtbelichtung in Blendenstufen. +1 verdoppelt das Licht, -1 halbiert es.",
        contrast = "Kontrast", contrast_desc = "Dehnt oder staucht die Tonwerte um Mittelgrau.",
        brightness = "Helligkeit", brightness_desc = "Verschiebt alle Tonwerte, ohne den Kontrast zu ändern.",
        highlights = "Lichter", highlights_desc = "Hellt die hellen Bildbereiche auf oder holt sie zurück.",
        shadows = "Schatten", shadows_desc = "Hebt die dunklen Bildbereiche an oder vertieft sie.",
        whites = "Weiß", whites_desc = "Verschiebt den Weißpunkt. Negative Werte verhindern Clipping in den Lichtern.",
        blacks = "Schwarz", blacks_desc = "Verschiebt den Schwarzpunkt. Negative Werte ergeben satteres Schwarz.",
        highlight_fade = "Lichter ausbleichen", highlight_fade_desc = "Zieht helle Bereiche Richtung Weiß (Bleach-Look).",
        shadow_fade = "Schatten ausbleichen", shadow_fade_desc = "Zieht dunkle Bereiche Richtung Weiß für einen weichen, verblassten Look.",
        black_lift = "Schwarzwert anheben", black_lift_desc = "Hebt den Schwarzpunkt an, matter Film-Look.",
        temperature = "Temperatur", temperature_desc = "Positiv = wärmer (orange), negativ = kühler (blau).",
        tint = "Farbton", tint_desc = "Positiv = Magenta, negativ = Grün.",
        saturation = "Sättigung", saturation_desc = "Intensität aller Farben. -1 ergibt Schwarz-Weiß.",
        vibrance = "Lebendigkeit", vibrance_desc = "Verstärkt blasse Farben stärker als bereits gesättigte.",
        shadows_color_r = "Schatten Rot", shadows_color_g = "Schatten Grün", shadows_color_b = "Schatten Blau",
        midtones_color_r = "Mitteltöne Rot", midtones_color_g = "Mitteltöne Grün", midtones_color_b = "Mitteltöne Blau",
        highlights_color_r = "Lichter Rot", highlights_color_g = "Lichter Grün", highlights_color_b = "Lichter Blau",
        wheels_desc = "Fügt diesen Farbanteil im jeweiligen Tonwertbereich hinzu oder entfernt ihn.",
        ss_r = "Schatten Rot", ss_g = "Schatten Grün", ss_b = "Schatten Blau", ss_sat = "Schatten Stärke",
        sh_r = "Lichter Rot", sh_g = "Lichter Grün", sh_b = "Lichter Blau", sh_sat = "Lichter Stärke",
        split_color_desc = "Farbe, die in diesen Bereich getont wird. Erst sichtbar, wenn die Stärke über 0 liegt.",
        split_sat_desc = "Wie stark die Tonungsfarbe angewendet wird.",
        sharpen = "Schärfen", sharpen_desc = "Lokale Schärfe (Unscharfmaskierung).",
        bloom = "Bloom", bloom_desc = "Weiches Leuchten um helle Bereiche.",
        halation = "Halation", halation_desc = "Warmer, rötlicher Schimmer um Lichter wie bei analogem Film.",
        grain_amount = "Filmkorn", grain_amount_desc = "Animiertes Filmkorn. In Schatten stärker als in Lichtern.",
        grain_size = "Korngröße", grain_size_desc = "Größe des Korns in Pixeln (bezogen auf 1080p).",
        vignette_amount = "Stärke", vignette_amount_desc = "Abdunkelung der Bildecken.",
        vignette_radius = "Radius", vignette_radius_desc = "Ab wo die Abdunkelung beginnt. Größer = kleinere Vignette.",
        vignette_feather = "Weichheit", vignette_feather_desc = "Weichheit der Vignettenkante.",
        vignette_shape = "Form", vignette_shape_desc = "0 = kreisförmig, 1 = breites Oval.",
        mask_shape = "Form", mask_round = "Ellipse", mask_rect = "Rechteck",
        mask_x = "Mitte X", mask_y = "Mitte Y", mask_width = "Breite", mask_height = "Höhe",
        mask_feather = "Weichheit", mask_pos_desc = "Position der Maskenmitte (0..1 des Bildes).",
        mask_size_desc = "Halbe Größe der Maske (0..1 des Bildes).", mask_feather_desc = "Weiche Kante der Maske.",
        lut_path = "LUT-Datei", lut_path_desc = ".cube (beliebige Größe) oder .png (OBS-Raster 512x512 oder Streifen N*N x N). Konvertierte .cube-Dateien werden im OBS-Ordner plugin_config zwischengespeichert.",
        lut_strength = "LUT-Stärke", lut_strength_desc = "Mischung zwischen gegradetem Bild und LUT-Ergebnis.",
        lut_status = "LUT-Status",
        lut_export_path = "LUT-Exportdatei", lut_export_path_desc = ".cube schreibt eine 33x33x33-LUT, .png schreibt eine OBS-kompatible 512x512-LUT.",
        export_lut = "Aktuellen Look als LUT exportieren", export_lut_desc = "Backt alle Farbeinstellungen in eine LUT. Räumliche Effekte (Bloom, Halation, Schärfen, Korn, Vignette, Maske) können nicht Teil einer LUT sein.",
        look_export_path = "Look-Exportdatei", save_look = "Look speichern (JSON)",
        look_import_path = "Look-Importdatei", load_look = "Look laden (JSON)",
        look_desc = "Looks enthalten alle Farbeinstellungen und lassen sich zwischen Szenen, Profilen und Rechnern austauschen.",
        info_text = "Lumetric Korrektor v%s — Tipp: Mit einer Voreinstellung starten, dann feinjustieren. Bloom, Halation, Schärfen und Korn kosten am meisten GPU-Zeit; auf 0 lassen, wenn nicht benötigt.",
    },
}

-- Preset-Namen (gleich in beiden Sprachen, außer wo eine Übersetzung sinnvoll ist)
local PRESET_NAMES = {
    ["en-US"] = {
        neutral = "Neutral", warm = "Warm", cool = "Cool", bright = "Bright", dark = "Dark",
        contrast_boost = "Contrast Boost", contrast_reduce = "Contrast Reduce",
        cinematic = "Cinematic", filmic = "Filmic", dramatic = "Dramatic Contrast", vibrant = "Vibrant", muted = "Muted",
        warm_contrast = "Warm Contrast", cool_contrast = "Cool Contrast", bleach_bypass = "Bleach Bypass",
        faded_shadows = "Faded Shadows", cross_process = "Cross Process", crisp_clarity = "Crisp Clarity",
        highlights_warm = "Warm Highlights", shadows_blue = "Blue Shadows", shadows_green = "Green Shadows",
        sunset = "Sunset Glow", moonlight = "Moonlight", vivid_warm = "Vivid Warm", moody_blue = "Moody Blue",
        warm_portrait = "Warm Portrait", day_for_night = "Day For Night", night_enhancer = "Night Enhancer",
        forest_green = "Forest Green", desert_heat = "Desert Heat", arctic_chill = "Arctic Chill", horror_atmosphere = "Horror Atmosphere",
        vintage = "Vintage Film", retro_film = "Retro Film", film_70s = "70s Film", retro_80s = "80s Retro", vhs_90s = "90s VHS",
        analog_vhs = "Analog VHS", sepia = "Sepia Tone", bw = "Black & White", bw_high_contrast = "B&W High Contrast",
        neo_noir = "Neo Noir", cyberpunk = "Cyberpunk", teal_orange = "Teal & Orange", dreamy_bloom = "Dreamy Bloom",
        pastel_dreams = "Pastel Dreams", game_stream = "Game Stream",
    },
    ["de-DE"] = {
        neutral = "Neutral", warm = "Warm", cool = "Kühl", bright = "Hell", dark = "Dunkel",
        contrast_boost = "Kontrast-Boost", contrast_reduce = "Kontrast-Reduzierung",
        cinematic = "Cinematisch", filmic = "Filmisch", dramatic = "Dramatischer Kontrast", vibrant = "Lebendig", muted = "Gedämpft",
        warm_contrast = "Warmer Kontrast", cool_contrast = "Kühler Kontrast", bleach_bypass = "Bleach Bypass",
        faded_shadows = "Verblasste Schatten", cross_process = "Cross Process", crisp_clarity = "Klare Schärfe",
        highlights_warm = "Warme Lichter", shadows_blue = "Blaue Schatten", shadows_green = "Grüne Schatten",
        sunset = "Sonnenuntergang", moonlight = "Mondlicht", vivid_warm = "Lebendig Warm", moody_blue = "Moody Blue",
        warm_portrait = "Warmes Porträt", day_for_night = "Day For Night", night_enhancer = "Nacht-Aufheller",
        forest_green = "Waldgrün", desert_heat = "Wüstenhitze", arctic_chill = "Arktische Kälte", horror_atmosphere = "Horror-Atmosphäre",
        vintage = "Vintage-Film", retro_film = "Retro-Film", film_70s = "70er Film", retro_80s = "80er Retro", vhs_90s = "90er VHS",
        analog_vhs = "Analog VHS", sepia = "Sepia", bw = "Schwarz-Weiß", bw_high_contrast = "S/W Hochkontrast",
        neo_noir = "Neo Noir", cyberpunk = "Cyberpunk", teal_orange = "Teal & Orange", dreamy_bloom = "Traumhafter Bloom",
        pastel_dreams = "Pastell-Träume", game_stream = "Spiele-Stream",
    },
}

local function current_lang()
    local locale = obs.obs_get_locale and obs.obs_get_locale() or "en-US"
    if type(locale) == "string" and locale:sub(1, 2):lower() == "de" then
        return "de-DE"
    end
    return "en-US"
end

local function tr(key)
    local lang = current_lang()
    return (L10N[lang] and L10N[lang][key]) or L10N["en-US"][key] or key
end

local function preset_name(id)
    local lang = current_lang()
    return (PRESET_NAMES[lang] and PRESET_NAMES[lang][id]) or PRESET_NAMES["en-US"][id] or id
end

-- ---------------------------------------------------------------------------
-- Parameter-Definitionen: eine Tabelle steuert Defaults, UI, Update und Shader
-- key = Settings-Schlüssel, shader = Uniform-Name (nil = Teil eines Vektors)
-- ---------------------------------------------------------------------------
local PARAMS = {
    -- Tonwerte
    { key = "exposure",       group = "tone", min = -1, max = 1, step = 0.01, def = 0,    shader = "exposure",   desc = "exposure_desc" },
    { key = "contrast",       group = "tone", min = -1, max = 1, step = 0.01, def = 0,    shader = "contrast",   desc = "contrast_desc" },
    { key = "brightness",     group = "tone", min = -1, max = 1, step = 0.01, def = 0,    shader = "brightness", desc = "brightness_desc" },
    { key = "highlights",     group = "tone", min = -1, max = 1, step = 0.01, def = 0,    shader = "highlights", desc = "highlights_desc" },
    { key = "shadows",        group = "tone", min = -1, max = 1, step = 0.01, def = 0,    shader = "shadows",    desc = "shadows_desc" },
    { key = "whites",         group = "tone", min = -1, max = 1, step = 0.01, def = 0,    shader = "whites",     desc = "whites_desc" },
    { key = "blacks",         group = "tone", min = -1, max = 1, step = 0.01, def = 0,    shader = "blacks",     desc = "blacks_desc" },
    -- Ausbleichen
    { key = "highlight_fade", group = "fade", min = 0,  max = 1, step = 0.01, def = 0,    shader = "highlight_fade", desc = "highlight_fade_desc" },
    { key = "shadow_fade",    group = "fade", min = 0,  max = 1, step = 0.01, def = 0,    shader = "shadow_fade",    desc = "shadow_fade_desc" },
    { key = "black_lift",     group = "fade", min = 0,  max = 1, step = 0.01, def = 0,    shader = "black_lift",     desc = "black_lift_desc" },
    -- Weißabgleich
    { key = "temperature",    group = "wb",   min = -1, max = 1, step = 0.01, def = 0,    shader = "temperature", desc = "temperature_desc" },
    { key = "tint",           group = "wb",   min = -1, max = 1, step = 0.01, def = 0,    shader = "tint",        desc = "tint_desc" },
    -- Farbe
    { key = "saturation",     group = "color", min = -1, max = 1, step = 0.01, def = 0,   shader = "saturation", desc = "saturation_desc" },
    { key = "vibrance",       group = "color", min = -1, max = 1, step = 0.01, def = 0,   shader = "vibrance",   desc = "vibrance_desc" },
    -- Farbräder
    { key = "shadows_color_r",    group = "wheels", min = -1, max = 1, step = 0.01, def = 0, desc = "wheels_desc" },
    { key = "shadows_color_g",    group = "wheels", min = -1, max = 1, step = 0.01, def = 0, desc = "wheels_desc" },
    { key = "shadows_color_b",    group = "wheels", min = -1, max = 1, step = 0.01, def = 0, desc = "wheels_desc" },
    { key = "midtones_color_r",   group = "wheels", min = -1, max = 1, step = 0.01, def = 0, desc = "wheels_desc" },
    { key = "midtones_color_g",   group = "wheels", min = -1, max = 1, step = 0.01, def = 0, desc = "wheels_desc" },
    { key = "midtones_color_b",   group = "wheels", min = -1, max = 1, step = 0.01, def = 0, desc = "wheels_desc" },
    { key = "highlights_color_r", group = "wheels", min = -1, max = 1, step = 0.01, def = 0, desc = "wheels_desc" },
    { key = "highlights_color_g", group = "wheels", min = -1, max = 1, step = 0.01, def = 0, desc = "wheels_desc" },
    { key = "highlights_color_b", group = "wheels", min = -1, max = 1, step = 0.01, def = 0, desc = "wheels_desc" },
    -- Split-Toning
    { key = "ss_r",   group = "split", min = -1, max = 1, step = 0.01, def = 0, desc = "split_color_desc" },
    { key = "ss_g",   group = "split", min = -1, max = 1, step = 0.01, def = 0, desc = "split_color_desc" },
    { key = "ss_b",   group = "split", min = -1, max = 1, step = 0.01, def = 0, desc = "split_color_desc" },
    { key = "ss_sat", group = "split", min = 0,  max = 1, step = 0.01, def = 0, desc = "split_sat_desc" },
    { key = "sh_r",   group = "split", min = -1, max = 1, step = 0.01, def = 0, desc = "split_color_desc" },
    { key = "sh_g",   group = "split", min = -1, max = 1, step = 0.01, def = 0, desc = "split_color_desc" },
    { key = "sh_b",   group = "split", min = -1, max = 1, step = 0.01, def = 0, desc = "split_color_desc" },
    { key = "sh_sat", group = "split", min = 0,  max = 1, step = 0.01, def = 0, desc = "split_sat_desc" },
    -- Kreative Effekte
    { key = "sharpen",      group = "fx", min = 0, max = 1, step = 0.01, def = 0, shader = "sharpen_amount",  desc = "sharpen_desc" },
    { key = "bloom",        group = "fx", min = 0, max = 1, step = 0.01, def = 0, shader = "bloom_intensity", desc = "bloom_desc" },
    { key = "halation",     group = "fx", min = 0, max = 1, step = 0.01, def = 0, shader = "halation",        desc = "halation_desc" },
    { key = "grain_amount", group = "fx", min = 0, max = 1, step = 0.01, def = 0, shader = "grain_amount",    desc = "grain_amount_desc" },
    { key = "grain_size",   group = "fx", min = 1, max = 8, step = 0.1,  def = 2, shader = "grain_size",      desc = "grain_size_desc" },
    -- Vignette
    { key = "vignette_amount",  group = "vignette", min = 0, max = 1, step = 0.01, def = 0,    shader = "vignette_amount",  desc = "vignette_amount_desc" },
    { key = "vignette_radius",  group = "vignette", min = 0, max = 1, step = 0.01, def = 0.75, shader = "vignette_radius",  desc = "vignette_radius_desc" },
    { key = "vignette_feather", group = "vignette", min = 0, max = 1, step = 0.01, def = 0.5,  shader = "vignette_feather", desc = "vignette_feather_desc" },
    { key = "vignette_shape",   group = "vignette", min = 0, max = 1, step = 0.01, def = 0,    shader = "vignette_shape",   desc = "vignette_shape_desc" },
    -- Maske (Position/Größe; enable_mask und mask_shape sind keine Slider)
    { key = "mask_x",       group = "mask", min = 0, max = 1,   step = 0.01, def = 0.5,  desc = "mask_pos_desc" },
    { key = "mask_y",       group = "mask", min = 0, max = 1,   step = 0.01, def = 0.5,  desc = "mask_pos_desc" },
    { key = "mask_width",   group = "mask", min = 0, max = 1,   step = 0.01, def = 0.25, desc = "mask_size_desc" },
    { key = "mask_height",  group = "mask", min = 0, max = 1,   step = 0.01, def = 0.25, desc = "mask_size_desc" },
    { key = "mask_feather", group = "mask", min = 0, max = 0.5, step = 0.01, def = 0.1,  shader = "mask_feather", desc = "mask_feather_desc" },
    -- LUT
    { key = "lut_strength", group = "lut", min = 0, max = 1, step = 0.01, def = 1, shader = "lut_strength", desc = "lut_strength_desc" },
}

local PARAM_BY_KEY = {}
for _, p in ipairs(PARAMS) do PARAM_BY_KEY[p.key] = p end

-- Vektor-Uniforms, die aus mehreren Settings zusammengesetzt werden
local VEC4_PARAMS = {
    { shader = "shadows_color",    keys = { "shadows_color_r",    "shadows_color_g",    "shadows_color_b" } },
    { shader = "midtones_color",   keys = { "midtones_color_r",   "midtones_color_g",   "midtones_color_b" } },
    { shader = "highlights_color", keys = { "highlights_color_r", "highlights_color_g", "highlights_color_b" } },
    { shader = "split_shadow",     keys = { "ss_r", "ss_g", "ss_b", "ss_sat" } },
    { shader = "split_highlight",  keys = { "sh_r", "sh_g", "sh_b", "sh_sat" } },
}

-- Typen der Shader-Parameter, die nicht aus PARAMS hervorgehen (für die Initialisierung)
local VEC2_PARAM_NAMES = { mask_pos = true, mask_size = true }
local VEC4_PARAM_NAMES = { buffer_size = true, lut_info = true }
for _, vec in ipairs(VEC4_PARAMS) do VEC4_PARAM_NAMES[vec.shader] = true end
local TEXTURE_PARAM_NAMES = { lut_tex = true }

-- Schlüssel, die Presets und "Zurücksetzen" anfassen (Maske und LUT bleiben unberührt)
local function is_look_key(key)
    local p = PARAM_BY_KEY[key]
    return p ~= nil and p.group ~= "mask" and p.group ~= "lut"
end

-- Alte Versionen haben interne Felder in den Szenen-Settings abgelegt. Diese
-- Schlüssel werden beim ersten Update einer alten Szene entfernt.
local LEGACY_JUNK_KEYS = {
    "dirty", "width", "height", "invalid", "lut_bound", "preview_width", "preview_height",
    "last_seed_ts", "last_time_seed", "last_grain_amount", "last_grain_size", "last_vignette_shape",
    "shadows_red", "shadows_green", "shadows_blue", "shadows_sat",
    "highlights_red", "highlights_green", "highlights_blue", "highlights_sat",
}
for _, p in ipairs(PARAMS) do table.insert(LEGACY_JUNK_KEYS, "last_" .. p.key) end

-- ---------------------------------------------------------------------------
-- Presets (Werte beziehen sich auf echte Settings-Schlüssel)
-- ---------------------------------------------------------------------------
local PRESET_CATEGORIES = {
    { id = "cat_basic", presets = {
        { id = "neutral", v = {} },
        { id = "warm", v = { temperature = 0.2, tint = 0.05 } },
        { id = "cool", v = { temperature = -0.2, tint = -0.05 } },
        { id = "bright", v = { exposure = 0.1, highlights = 0.05, shadows = 0.1 } },
        { id = "dark", v = { exposure = -0.1, shadows = -0.05, blacks = -0.05 } },
        { id = "contrast_boost", v = { contrast = 0.15, highlights = 0.1, shadows = -0.1, blacks = -0.05 } },
        { id = "contrast_reduce", v = { contrast = -0.1, highlights = -0.05, shadows = 0.05 } },
    } },
    { id = "cat_style", presets = {
        { id = "cinematic", v = { contrast = 0.2, highlights = -0.1, shadows = 0.05, saturation = -0.1, midtones_color_b = 0.05, shadows_color_b = 0.1, vignette_amount = 0.15, vignette_feather = 0.8 } },
        { id = "filmic", v = { contrast = 0.15, highlights = -0.05, shadows = 0.05, saturation = -0.05, vignette_amount = 0.1, vignette_feather = 0.7 } },
        { id = "dramatic", v = { contrast = 0.25, highlights = -0.1, shadows = -0.15, blacks = -0.1, saturation = 0.1, vignette_amount = 0.25, vignette_radius = 0.7 } },
        { id = "vibrant", v = { saturation = 0.2, vibrance = 0.15, contrast = 0.1, highlights = 0.05 } },
        { id = "muted", v = { saturation = -0.15, vibrance = -0.1, contrast = -0.05 } },
        { id = "warm_contrast", v = { temperature = 0.15, contrast = 0.15, highlights = 0.05, shadows = -0.05 } },
        { id = "cool_contrast", v = { temperature = -0.15, contrast = 0.15, highlights = 0.05, shadows = -0.05 } },
        { id = "bleach_bypass", v = { saturation = -0.45, contrast = 0.3, highlights = -0.1, blacks = -0.1, highlight_fade = 0.1 } },
        { id = "faded_shadows", v = { black_lift = 0.35, contrast = -0.05, saturation = -0.1, shadow_fade = 0.1 } },
        { id = "cross_process", v = { contrast = 0.15, saturation = 0.15, shadows_color_g = 0.08, shadows_color_b = 0.15, highlights_color_r = 0.1, highlights_color_g = 0.1, highlights_color_b = -0.1 } },
        { id = "crisp_clarity", v = { contrast = 0.2, highlights = -0.05, shadows = -0.05, blacks = -0.05, vibrance = 0.1, sharpen = 0.4, vignette_amount = 0.1 } },
    } },
    { id = "cat_mood", presets = {
        { id = "highlights_warm", v = { highlights_color_r = 0.1, highlights_color_g = 0.05 } },
        { id = "shadows_blue", v = { shadows_color_b = 0.15 } },
        { id = "shadows_green", v = { shadows_color_g = 0.15 } },
        { id = "sunset", v = { temperature = 0.2, highlights_color_r = 0.15, highlights_color_g = 0.05, shadows_color_b = 0.1 } },
        { id = "moonlight", v = { temperature = -0.3, exposure = -0.1, highlights_color_b = 0.1, midtones_color_b = 0.05, shadows = -0.1, contrast = 0.1 } },
        { id = "vivid_warm", v = { temperature = 0.15, saturation = 0.15, vibrance = 0.1, contrast = 0.1 } },
        { id = "moody_blue", v = { temperature = -0.25, saturation = -0.2, contrast = 0.15, shadows_color_b = 0.15, midtones_color_b = 0.08, vignette_amount = 0.2 } },
        { id = "warm_portrait", v = { temperature = 0.12, tint = 0.03, contrast = -0.05, highlights = -0.08, shadows = 0.08, vibrance = 0.12, saturation = -0.05, highlights_color_r = 0.05, midtones_color_r = 0.04 } },
        { id = "day_for_night", v = { exposure = -0.6, contrast = 0.2, saturation = -0.35, temperature = -0.4, shadows_color_b = 0.2, midtones_color_b = 0.1, highlights = -0.3, vignette_amount = 0.3 } },
        { id = "night_enhancer", v = { exposure = 0.3, shadows = 0.4, black_lift = 0.15, contrast = 0.05, blacks = 0.1, vibrance = 0.1, sharpen = 0.1 } },
        { id = "forest_green", v = { temperature = -0.05, midtones_color_g = 0.1, shadows_color_g = 0.06, shadows_color_b = 0.04, highlights_color_g = 0.04, saturation = 0.05, vibrance = 0.1 } },
        { id = "desert_heat", v = { temperature = 0.35, tint = 0.05, contrast = 0.1, highlights_color_r = 0.1, highlights_color_g = 0.06, midtones_color_r = 0.06, saturation = 0.05, whites = 0.05 } },
        { id = "arctic_chill", v = { temperature = -0.35, tint = -0.03, exposure = 0.05, highlights_color_b = 0.1, midtones_color_b = 0.06, saturation = -0.15, whites = 0.1 } },
        { id = "horror_atmosphere", v = { temperature = -0.2, saturation = -0.3, contrast = 0.2, highlights = -0.1, shadows = -0.2, blacks = -0.15, vignette_amount = 0.4, vignette_feather = 0.5, ss_b = 0.15, ss_sat = 0.2, sharpen = 0.15 } },
    } },
    { id = "cat_era", presets = {
        { id = "vintage", v = { temperature = 0.15, contrast = 0.1, saturation = -0.15, shadows_color_r = 0.05, shadows_color_b = -0.1, highlights_color_r = 0.1, highlights_color_b = -0.05, vignette_amount = 0.2, grain_amount = 0.15, grain_size = 2.5 } },
        { id = "retro_film", v = { temperature = 0.1, saturation = -0.2, contrast = 0.15, highlights = -0.1, shadows = 0.05, vignette_amount = 0.25, halation = 0.4, sh_r = 0.15, sh_sat = 0.3, grain_amount = 0.2, grain_size = 2.5 } },
        { id = "film_70s", v = { temperature = 0.25, tint = 0.05, contrast = 0.05, saturation = -0.1, highlights_color_r = 0.12, highlights_color_g = 0.08, shadows_color_r = 0.05, shadows_color_g = 0.03, black_lift = 0.15, grain_amount = 0.25, grain_size = 3, vignette_amount = 0.2 } },
        { id = "retro_80s", v = { saturation = 0.25, vibrance = 0.1, contrast = 0.05, highlights = 0.05, ss_r = 0.1, ss_b = 0.1, ss_sat = 0.25, sh_r = 0.15, sh_g = 0.05, sh_sat = 0.25, bloom = 0.2 } },
        { id = "vhs_90s", v = { saturation = 0.05, contrast = -0.05, bloom = 0.15, halation = 0.3, grain_amount = 0.35, grain_size = 3.5, shadows_color_b = 0.05, highlights_color_r = 0.05, black_lift = 0.1 } },
        { id = "analog_vhs", v = { saturation = 0.1, contrast = 0.1, highlights = -0.1, shadows = -0.05, halation = 0.5, sh_r = 0.1, sh_sat = 0.2, ss_b = 0.1, ss_sat = 0.2, grain_amount = 0.3, grain_size = 3 } },
        { id = "sepia", v = { saturation = -0.8, temperature = 0.3, contrast = 0.05, highlights_color_r = 0.1, highlights_color_g = 0.05, shadows_color_r = 0.1, shadows_color_g = 0.05 } },
        { id = "bw", v = { saturation = -1, contrast = 0.1, highlights = 0.05, shadows = -0.05, blacks = -0.05 } },
        { id = "bw_high_contrast", v = { saturation = -1, contrast = 0.2, highlights = 0.1, shadows = -0.1, blacks = -0.1 } },
    } },
    { id = "cat_creative", presets = {
        { id = "neo_noir", v = { saturation = -0.9, contrast = 0.25, blacks = -0.15, vignette_amount = 0.4, vignette_feather = 0.6, ss_b = 0.2, ss_sat = 0.3, sharpen = 0.2 } },
        { id = "cyberpunk", v = { contrast = 0.2, blacks = -0.1, vibrance = 0.3, sh_b = 0.3, sh_sat = 0.5, ss_r = 0.2, ss_sat = 0.4, bloom = 0.4, halation = 0.2 } },
        { id = "teal_orange", v = { contrast = 0.2, vibrance = 0.1, sh_r = 0.25, sh_g = 0.1, sh_sat = 0.4, ss_b = 0.25, ss_g = 0.1, ss_sat = 0.4, sharpen = 0.15 } },
        { id = "dreamy_bloom", v = { contrast = -0.05, highlights = 0.1, shadows = 0.1, saturation = 0.05, bloom = 0.5, halation = 0.3, sh_r = 0.1, sh_g = 0.05, sh_sat = 0.2 } },
        { id = "pastel_dreams", v = { contrast = -0.1, highlights = 0.1, shadows = 0.1, saturation = -0.1, vibrance = 0.1, sh_r = 0.1, sh_b = 0.1, sh_sat = 0.3, ss_b = 0.15, ss_sat = 0.3, bloom = 0.2 } },
        { id = "game_stream", v = { contrast = 0.15, highlights = -0.05, shadows = 0.05, vibrance = 0.2, saturation = 0.1, sharpen = 0.3, vignette_amount = 0.15, vignette_feather = 0.7 } },
    } },
}

local PRESET_BY_ID = {}
local PRESET_COUNT = 0
for _, cat in ipairs(PRESET_CATEGORIES) do
    for _, preset in ipairs(cat.presets) do
        PRESET_BY_ID[preset.id] = preset
        PRESET_COUNT = PRESET_COUNT + 1
    end
end

-- ---------------------------------------------------------------------------
-- Shader (HLSL-Dialekt; libobs übersetzt für OpenGL/Metal)
-- Die nicht-räumlichen Stufen in grade_color werden vom LUT-Export 1:1 in Lua
-- nachgebildet (siehe grade_pixel weiter unten).
-- ---------------------------------------------------------------------------
local shader_code = [[
uniform float4x4 ViewProj;
uniform texture2d image;
uniform float4 buffer_size;      // x = width, y = height, z = 1/width, w = 1/height

// --- tone -------------------------------------------------------------------
uniform float exposure;
uniform float contrast;
uniform float brightness;
uniform float highlights;
uniform float shadows;
uniform float whites;
uniform float blacks;
uniform float black_lift;
uniform float highlight_fade;
uniform float shadow_fade;

// --- white balance / colour ---------------------------------------------------
uniform float temperature;
uniform float tint;
uniform float saturation;
uniform float vibrance;

// --- colour wheels (rgb offsets per tonal range, w unused) --------------------
uniform float4 shadows_color;
uniform float4 midtones_color;
uniform float4 highlights_color;

// --- split toning (rgb offset + strength in w) --------------------------------
uniform float4 split_shadow;
uniform float4 split_highlight;

// --- creative fx --------------------------------------------------------------
uniform float sharpen_amount;
uniform float bloom_intensity;
uniform float halation;
uniform float grain_amount;
uniform float grain_size;
uniform float grain_time;

// --- vignette -----------------------------------------------------------------
uniform float vignette_amount;
uniform float vignette_radius;
uniform float vignette_feather;
uniform float vignette_shape;

// --- mask ---------------------------------------------------------------------
uniform float enable_mask;
uniform float2 mask_pos;
uniform float2 mask_size;
uniform float mask_feather;
uniform float mask_roundness;

// --- 3D LUT stored as a 2D atlas of size*size tiles -----------------------------
uniform float lut_strength;
uniform float4 lut_info;         // x = cube size, y = tiles per row, z = 1/tex_w, w = 1/tex_h
uniform texture2d lut_tex;

sampler_state imageSampler {
    Filter   = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler_state lutSampler {
    Filter   = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
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

float luma_of(float3 c)
{
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

// Non-spatial pipeline (mirrored 1:1 by the Lua LUT exporter)
float3 grade_color(float3 c)
{
    // 1. exposure
    c *= pow(2.0, exposure);

    // 2. tonal ranges, weighted by luminance so hues do not drift
    float l  = luma_of(c);
    float hw = smoothstep(0.5, 1.0, l);
    float sw = 1.0 - smoothstep(0.0, 0.5, l);
    float ww = smoothstep(0.7, 1.0, l);
    float bw = 1.0 - smoothstep(0.0, 0.3, l);
    float lw = 1.0 - smoothstep(0.0, 0.4, l);
    c *= (1.0 + highlights * hw) * (1.0 + shadows * sw);
    c += whites * 0.5 * ww + blacks * 0.5 * bw + black_lift * 0.5 * lw;

    // 3. brightness, 4. contrast (pivot at mid grey)
    c += brightness;
    c = (c - 0.5) * (1.0 + contrast) + 0.5;

    // 5. white balance: + temperature = warmer, + tint = magenta
    c += temperature * float3(0.1, 0.0, -0.1) + tint * float3(0.05, -0.1, 0.05);
    c = saturate(c);

    // 6. fades towards white (film bleach look)
    l = luma_of(c);
    c = lerp(c, float3(1.0, 1.0, 1.0), smoothstep(0.7, 1.0, l) * highlight_fade);
    c = lerp(c, float3(1.0, 1.0, 1.0), (1.0 - smoothstep(0.0, 0.3, l)) * shadow_fade);

    // 7. colour wheels
    l = luma_of(c);
    float w_sh  = 1.0 - smoothstep(0.0, 0.5, l);
    float w_hi  = smoothstep(0.5, 1.0, l);
    float w_mid = 1.0 - w_sh - w_hi;
    c = saturate(c + shadows_color.rgb * w_sh * 0.5 + midtones_color.rgb * w_mid * 0.3 + highlights_color.rgb * w_hi * 0.5);

    // 8. split toning
    l = luma_of(c);
    float wS = saturate(1.0 - l * 2.0);
    float wH = saturate((l - 0.5) * 2.0);
    c = lerp(c, saturate(c + split_shadow.rgb),    split_shadow.w    * wS);
    c = lerp(c, saturate(c + split_highlight.rgb), split_highlight.w * wH);

    // 9. saturation
    float g = luma_of(c);
    c = lerp(float3(g, g, g), c, 1.0 + saturation);

    // 10. vibrance (boosts low-saturation colours more than saturated ones)
    float lum = luma_of(c);
    float mx  = max(max(c.r, c.g), c.b);
    float mn  = min(min(c.r, c.g), c.b);
    float sat = (mx - mn) / max(mx, 0.0001);
    c = lerp(float3(lum, lum, lum), c, 1.0 + vibrance * (1.0 - sat));

    return c;
}

// LUT lookup: trilinear via two bilinear fetches in the 2D atlas.
float3 sample_lut(float3 c)
{
    float size  = lut_info.x;
    float tiles = lut_info.y;
    c = saturate(c);
    float bf = c.b * (size - 1.0);
    float b0 = floor(bf);
    float b1 = min(b0 + 1.0, size - 1.0);
    float f  = bf - b0;
    float2 rg = c.rg * (size - 1.0) + 0.5;
    float2 t0 = float2(b0 - floor(b0 / tiles) * tiles, floor(b0 / tiles));
    float2 t1 = float2(b1 - floor(b1 / tiles) * tiles, floor(b1 / tiles));
    float2 uv0 = (t0 * size + rg) * lut_info.zw;
    float2 uv1 = (t1 * size + rg) * lut_info.zw;
    float3 s0 = lut_tex.Sample(lutSampler, uv0).rgb;
    float3 s1 = lut_tex.Sample(lutSampler, uv1).rgb;
    return lerp(s0, s1, f);
}

// 9-tap glow kernel on the input image, radius scales with resolution.
float3 glow_sample(float2 uv)
{
    float2 px = buffer_size.zw * (buffer_size.y / 1080.0) * 6.0;
    float2 dg = px * 0.7071;
    float3 s = image.Sample(imageSampler, uv).rgb * 2.0;
    s += image.Sample(imageSampler, uv + float2( px.x, 0.0)).rgb;
    s += image.Sample(imageSampler, uv + float2(-px.x, 0.0)).rgb;
    s += image.Sample(imageSampler, uv + float2(0.0,  px.y)).rgb;
    s += image.Sample(imageSampler, uv + float2(0.0, -px.y)).rgb;
    s += image.Sample(imageSampler, uv + dg).rgb;
    s += image.Sample(imageSampler, uv - dg).rgb;
    s += image.Sample(imageSampler, uv + float2( dg.x, -dg.y)).rgb;
    s += image.Sample(imageSampler, uv + float2(-dg.x,  dg.y)).rgb;
    return s / 10.0;
}

float3 unsharp_mask(float2 uv, float3 base, float amt)
{
    float2 px = buffer_size.zw;
    float3 blur = (image.Sample(imageSampler, uv + px).rgb +
                   image.Sample(imageSampler, uv - px).rgb +
                   image.Sample(imageSampler, uv + float2( px.x, -px.y)).rgb +
                   image.Sample(imageSampler, uv + float2(-px.x,  px.y)).rgb) * 0.25;
    return saturate(base + (base - blur) * amt);
}

float hash12(float2 p)
{
    float3 p3 = float3(p.x, p.y, p.x) * 0.1031;
    p3 = p3 - floor(p3);
    p3 += dot(p3, float3(p3.y, p3.z, p3.x) + 33.33);
    float h = (p3.x + p3.y) * p3.z;
    return h - floor(h);
}

float4 PSDefault(VertDataOut v_in) : TARGET
{
    float4 src = image.Sample(imageSampler, v_in.uv);
    float3 c = grade_color(src.rgb);

    if (bloom_intensity > 0.001 || halation > 0.001) {
        float3 glow = glow_sample(v_in.uv);
        float3 bright = glow * smoothstep(0.45, 0.9, luma_of(glow));
        c += bright * bloom_intensity * 0.8;
        c += float3(0.30, 0.10, 0.03) * bright.r * halation;
    }

    if (sharpen_amount > 0.001) {
        c = unsharp_mask(v_in.uv, c, sharpen_amount);
    }

    if (lut_strength > 0.001) {
        c = lerp(c, sample_lut(c), lut_strength);
    }

    if (vignette_amount > 0.0) {
        float2 d = abs(v_in.uv - float2(0.5, 0.5));
        float dist = lerp(length(d), sqrt(d.x * d.x * 1.5 + d.y * d.y * 0.5), vignette_shape);
        float feather = max(vignette_feather, 0.001);
        float vig = 1.0 - smoothstep(vignette_radius - feather, vignette_radius, dist);
        c *= lerp(1.0, vig, vignette_amount);
    }

    if (grain_amount > 0.0) {
        float scale = max(grain_size, 1.0) * max(buffer_size.y / 1080.0, 0.5);
        float2 cell = floor(v_in.uv * buffer_size.xy / scale);
        float n1 = hash12(cell + float2(grain_time * 61.0, grain_time * 37.0));
        float n2 = hash12(cell * 1.7 + float2(grain_time * 23.0, 11.0));
        float g = n1 + n2 - 1.0;
        float lw = 1.0 - smoothstep(0.5, 1.0, luma_of(c));
        c += g * grain_amount * 0.15 * (0.4 + 0.6 * lw);
    }

    if (enable_mask > 0.5) {
        float2 size = max(mask_size, float2(0.0001, 0.0001));
        float2 rel = (v_in.uv - mask_pos) / size;
        float dist = lerp(max(abs(rel.x), abs(rel.y)), length(rel), mask_roundness);
        float feather = max(mask_feather, 0.001);
        float m = 1.0 - smoothstep(1.0 - feather, 1.0, dist);
        c = lerp(src.rgb, c, m);
    }

    return float4(saturate(c), src.a);
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

-- ===== MODULE: png_encoder (dev/lua/png_encoder.lua) ========================
local png_encoder = (function()
--[[
  png_encoder.lua - pure Lua 5.1 / LuaJIT PNG encoder for 8/16-bit RGBA images.

  Produces a valid, spec-compliant PNG:
    - PNG signature
    - IHDR (colour type 6 = RGBA, compression 0, filter 0, interlace 0)
    - IDAT: a zlib stream (RFC 1950) wrapping "stored" (uncompressed) DEFLATE
      blocks (RFC 1951, BTYPE=00), each scanline prefixed with filter byte 0
    - IEND

  No os/io, no ffi, no C modules - safe to inline into an OBS Lua script.
  Uses LuaJIT's `bit` library for CRC-32 (table-driven).  `bit` operations
  return signed 32-bit Lua numbers; every value that is written out as bytes
  or compared/returned as a checksum is renormalised to the unsigned range
  [0, 2^32-1] via plain arithmetic (`% 4294967296`) before use, since LuaJIT's
  bit ops treat their operand only as a 32-bit *pattern* (band/rshift work
  identically either way), but returned/displayed numbers must be unsigned.
]]

local bit_ok, bit = pcall(require, "bit")
if not bit_ok then bit = bit32 or _G.bit end -- fallback, still no globals leak
local band, bxor, rshift = bit.band, bit.bxor, bit.rshift

local M = {}

--------------------------------------------------------------------------
-- byte helpers (plain arithmetic, values are always non-negative here)
--------------------------------------------------------------------------

local function u32be(n)
  n = n % 4294967296
  local b4 = n % 256; n = (n - b4) / 256
  local b3 = n % 256; n = (n - b3) / 256
  local b2 = n % 256; n = (n - b2) / 256
  local b1 = n % 256
  return string.char(b1, b2, b3, b4)
end

local function u16le(n)
  local b1 = n % 256
  local b2 = (n - b1) / 256
  return string.char(b1, b2)
end

--------------------------------------------------------------------------
-- CRC-32 (table-driven, LuaJIT bit library)
--------------------------------------------------------------------------

local CRC_POLY = 0xEDB88320
local crc_table = {}
do
  for n = 0, 255 do
    local c = n
    for _ = 1, 8 do
      if band(c, 1) ~= 0 then
        c = bxor(CRC_POLY, rshift(c, 1))
      else
        c = rshift(c, 1)
      end
    end
    crc_table[n] = c
  end
end

--- CRC-32 (IEEE 802.3) of `str`. Returns an unsigned integer 0..2^32-1.
function M.crc32(str)
  local crc = -1 -- 0xFFFFFFFF as a 32-bit bit pattern
  local byte = string.byte
  local t = crc_table
  local len = #str
  for i = 1, len do
    crc = bxor(t[band(bxor(crc, byte(str, i)), 0xFF)], rshift(crc, 8))
  end
  crc = bxor(crc, -1)
  if crc < 0 then crc = crc + 4294967296 end
  return crc
end

--------------------------------------------------------------------------
-- Adler-32 (RFC 1950), plain arithmetic - no bit ops needed
--------------------------------------------------------------------------

local ADLER_MOD = 65521
local NMAX = 5552 -- largest n such that 255*n*(n+1)/2 + (n+1)*(65520) <= 2^32-1

--- Adler-32 checksum of `str`. Returns an unsigned integer 0..2^32-1.
function M.adler32(str)
  local a, b = 1, 0
  local byte = string.byte
  local len = #str
  local i = 1
  while i <= len do
    local blockEnd = i + NMAX - 1
    if blockEnd > len then blockEnd = len end
    for j = i, blockEnd do
      a = a + byte(str, j)
      b = b + a
    end
    a = a % ADLER_MOD
    b = b % ADLER_MOD
    i = blockEnd + 1
  end
  return b * 65536 + a
end

--------------------------------------------------------------------------
-- DEFLATE (stored blocks only, RFC 1951 section 3.2.4)
--------------------------------------------------------------------------

local STORED_MAX = 65535

-- Appends one or more "stored" DEFLATE blocks encoding `data` to `parts`.
local function append_stored_blocks(parts, pi, data)
  local len = #data
  if len == 0 then
    parts[pi + 1] = string.char(1) -- BFINAL=1, BTYPE=00, rest padding zero bits
    parts[pi + 2] = u16le(0)
    parts[pi + 3] = u16le(0xFFFF)
    return pi + 3
  end
  local pos = 1
  while pos <= len do
    local remaining = len - pos + 1
    local blen = remaining > STORED_MAX and STORED_MAX or remaining
    local is_last = (pos + blen - 1 == len)
    parts[pi + 1] = string.char(is_last and 1 or 0)
    parts[pi + 2] = u16le(blen)
    parts[pi + 3] = u16le(0xFFFF - blen) -- one's complement of a 16-bit value
    parts[pi + 4] = string.sub(data, pos, pos + blen - 1)
    pi = pi + 4
    pos = pos + blen
  end
  return pi
end

--------------------------------------------------------------------------
-- PNG chunk assembly
--------------------------------------------------------------------------

local PNG_SIGNATURE = string.char(137, 80, 78, 71, 13, 10, 26, 10)

local function write_chunk(chunk_type, data)
  local crc_input = chunk_type .. data
  return u32be(#data) .. crc_input .. u32be(M.crc32(crc_input))
end

--------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------

--- Encode an RGBA raster as a PNG byte string.
-- @param width    image width in pixels (integer > 0)
-- @param height   image height in pixels (integer > 0)
-- @param rows     1-based array of `height` scanline strings; each scanline
--                 holds raw RGBA samples in PNG byte order (8-bit: 4
--                 bytes/pixel; 16-bit: 8 bytes/pixel, big-endian samples)
-- @param bitdepth 8 or 16
-- @return the encoded PNG file contents as a Lua string
function M.encode_rgba(width, height, rows, bitdepth)
  if type(width) ~= "number" or width < 1 or width % 1 ~= 0 then
    error("png_encoder: width must be a positive integer", 2)
  end
  if type(height) ~= "number" or height < 1 or height % 1 ~= 0 then
    error("png_encoder: height must be a positive integer", 2)
  end
  if bitdepth ~= 8 and bitdepth ~= 16 then
    error("png_encoder: bitdepth must be 8 or 16, got " .. tostring(bitdepth), 2)
  end
  if type(rows) ~= "table" then
    error("png_encoder: rows must be a table of scanline strings", 2)
  end
  if #rows ~= height then
    error(("png_encoder: rows has %d entries, expected height=%d"):format(#rows, height), 2)
  end

  local bytes_per_pixel = 4 * (bitdepth / 8)
  local expected_row_len = width * bytes_per_pixel

  -- Build the zlib "uncompressed data": each scanline prefixed with a
  -- filter-type byte (0 = None), concatenated for every row.
  local raw_parts = {}
  local rp = 0
  for y = 1, height do
    local row = rows[y]
    if type(row) ~= "string" or #row ~= expected_row_len then
      error(("png_encoder: row %d has length %s, expected %d (width=%d * %d bytes/px)")
        :format(y, type(row) == "string" and tostring(#row) or type(row), expected_row_len, width, bytes_per_pixel), 2)
    end
    rp = rp + 1; raw_parts[rp] = "\0"
    rp = rp + 1; raw_parts[rp] = row
  end
  local raw_data = table.concat(raw_parts)

  local adler = M.adler32(raw_data)

  -- zlib stream: 2-byte header, stored DEFLATE blocks, 4-byte Adler-32 (BE)
  local zlib_parts = {}
  zlib_parts[1] = string.char(0x78, 0x01)
  local zp = append_stored_blocks(zlib_parts, 1, raw_data)
  zlib_parts[zp + 1] = u32be(adler)
  local zlib_stream = table.concat(zlib_parts)

  local ihdr = u32be(width) .. u32be(height) .. string.char(bitdepth, 6, 0, 0, 0)

  return table.concat({
    PNG_SIGNATURE,
    write_chunk("IHDR", ihdr),
    write_chunk("IDAT", zlib_stream),
    write_chunk("IEND", ""),
  })
end

return M
end)()

-- ===== MODULE: cube_lut (dev/lua/cube_lut.lua) ==============================
local cube_lut = (function()
-- cube_lut.lua
-- Utilities for 3D LUTs in Adobe/Resolve .cube format and for the 2D atlas
-- texture layout consumed by the Lumetric Corrector shader (see
-- dev/shader_spec.effect, function sample_lut). Pure Lua 5.1 / LuaJIT; the
-- only non-core dependency is the LuaJIT-builtin `bit` library (not ffi).

-- LuaJIT (OBS) provides `bit`; guard anyway so a plain Lua 5.2+ host with bit32 still loads.
local bit_ok, bit = pcall(require, "bit")
if not bit_ok then bit = bit32 or _G.bit end
local bxor = bit and bit.bxor or function(a, b)
  -- portable fallback (slow, only used when no bit library exists)
  local r, m = 0, 1
  while a > 0 or b > 0 do
    local x, y = a % 2, b % 2
    if x ~= y then r = r + m end
    a, b, m = (a - x) / 2, (b - y) / 2, m * 2
  end
  return r
end

local floor = math.floor
local M = {}

-- ---------------------------------------------------------------------------
-- .cube parsing
-- ---------------------------------------------------------------------------

--- Parse an Adobe/Resolve .cube 3D LUT.
-- @param text  full file contents as a string
-- @return lut = { size, data, domain_min, domain_max, title } or nil, errmsg
function M.parse_cube(text)
  if type(text) ~= "string" then
    return nil, "cube text must be a string"
  end

  -- Normalise line endings, then strip '#' comments (to end of line, anywhere).
  text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
  text = text:gsub("#[^\n]*", "")

  local title
  text = text:gsub('TITLE%s+"([^"\n]*)"', function(t)
    title = t
    return ""
  end)

  if text:find("LUT_1D_SIZE") then
    return nil, "LUT_1D_SIZE files are not supported (3D LUTs only)"
  end

  local size_str
  text = text:gsub("LUT_3D_SIZE%s+(%d+)", function(s)
    size_str = s
    return ""
  end)
  if not size_str then
    return nil, "missing LUT_3D_SIZE"
  end
  local size = tonumber(size_str)
  if not size or size < 2 or size > 256 then
    return nil, "LUT_3D_SIZE must be an integer between 2 and 256"
  end

  local domain_min = { 0.0, 0.0, 0.0 }
  local domain_max = { 1.0, 1.0, 1.0 }
  -- Resolve/IRIDAS variant: LUT_3D_INPUT_RANGE lo hi (applies to all channels)
  text = text:gsub("LUT_3D_INPUT_RANGE%s+(%S+)%s+(%S+)", function(lo, hi)
    local l, h = tonumber(lo), tonumber(hi)
    if l and h then
      domain_min = { l, l, l }
      domain_max = { h, h, h }
    end
    return ""
  end)
  text = text:gsub("DOMAIN_MIN%s+(%S+)%s+(%S+)%s+(%S+)", function(a, b, c)
    domain_min = { tonumber(a) or 0.0, tonumber(b) or 0.0, tonumber(c) or 0.0 }
    return ""
  end)
  text = text:gsub("DOMAIN_MAX%s+(%S+)%s+(%S+)%s+(%S+)", function(a, b, c)
    domain_max = { tonumber(a) or 1.0, tonumber(b) or 1.0, tonumber(c) or 1.0 }
    return ""
  end)

  -- Remaining text is pure numeric data (plus whitespace/blank lines).
  -- Single gmatch pass over the whole string, no per-line table churn.
  local expected = size * size * size * 3
  local data = {}
  local n = 0
  for tok in text:gmatch("%S+") do
    local v = tonumber(tok)
    if not v then
      return nil, ("non-numeric token in LUT data: '%s'"):format(tok)
    end
    n = n + 1
    if n > expected then
      return nil, ("too many data values (expected %d)"):format(expected)
    end
    data[n] = v
  end
  if n < expected then
    return nil, ("too few data values (expected %d, got %d)"):format(expected, n)
  end

  return {
    size = size,
    data = data,
    domain_min = domain_min,
    domain_max = domain_max,
    title = title,
  }
end

-- ---------------------------------------------------------------------------
-- shared indexing helper (.cube data order: r fastest, then g, then b)
-- ---------------------------------------------------------------------------

local function get_rgb(lut, r, g, b)
  local n = lut.size
  local base = (r + g * n + b * n * n) * 3
  local d = lut.data
  return d[base + 1], d[base + 2], d[base + 3]
end

-- ---------------------------------------------------------------------------
-- atlas (strip layout) for the shader
-- ---------------------------------------------------------------------------

local function quantize(v, maxv)
  local q = floor(v * maxv + 0.5)
  if q < 0 then q = 0 elseif q > maxv then q = maxv end
  return q
end

--- Build strip-layout atlas rows (width = N*N, height = N, T = N tiles per
--- row) ready for png_encoder.encode_rgba. 8-bit -> 4 bytes/pixel RGBA,
--- 16-bit -> 8 bytes/pixel big-endian RGBA. Alpha is always fully opaque
--- (the max representable value for the bit depth).
function M.atlas_rows(lut, bitdepth)
  local n = lut.size
  local n2 = n * n
  local data = lut.data
  local dmin, dmax = lut.domain_min, lut.domain_max
  local den1 = dmax[1] - dmin[1]
  local den2 = dmax[2] - dmin[2]
  local den3 = dmax[3] - dmin[3]
  if den1 == 0 then den1 = 1 end
  if den2 == 0 then den2 = 1 end
  if den3 == 0 then den3 = 1 end

  local width, height = n2, n
  local is16 = (bitdepth == 16)
  local rows = {}
  local char = string.char

  for gy = 0, height - 1 do
    local parts = {}
    for x = 0, width - 1 do
      local bx = floor(x / n)
      local rx = x - bx * n
      local base = (rx + gy * n + bx * n2) * 3
      local rv = (data[base + 1] - dmin[1]) / den1
      local gv = (data[base + 2] - dmin[2]) / den2
      local bv = (data[base + 3] - dmin[3]) / den3
      if rv < 0 then rv = 0 elseif rv > 1 then rv = 1 end
      if gv < 0 then gv = 0 elseif gv > 1 then gv = 1 end
      if bv < 0 then bv = 0 elseif bv > 1 then bv = 1 end

      if is16 then
        local rq, gq, bq = quantize(rv, 65535), quantize(gv, 65535), quantize(bv, 65535)
        parts[x + 1] = char(
          floor(rq / 256), rq % 256,
          floor(gq / 256), gq % 256,
          floor(bq / 256), bq % 256,
          255, 255)
      else
        parts[x + 1] = char(quantize(rv, 255), quantize(gv, 255), quantize(bv, 255), 255)
      end
    end
    rows[gy + 1] = table.concat(parts)
  end

  return rows, width, height
end

-- ---------------------------------------------------------------------------
-- atlas layout detection (strip or square-grid) from texture dimensions
-- ---------------------------------------------------------------------------

--- Detect atlas layout from texture pixel dimensions.
-- @return size, tiles or nil, errmsg
function M.layout_from_dims(w, h)
  if type(w) ~= "number" or type(h) ~= "number" then
    return nil, "width/height must be numbers"
  end
  w, h = floor(w), floor(h)
  if w < 1 or h < 1 then
    return nil, "invalid dimensions"
  end

  -- strip: width == height*height, T == size == h
  if h >= 2 and w == h * h then
    return h, h
  end

  -- square grid: width == height, T tiles per row/col, size*size*size == w*h
  if w == h then
    local n = floor((w * h) ^ (1 / 3) + 0.5)
    if n >= 2 and n * n * n == w * h and w % n == 0 then
      return n, w / n
    end
  end

  return nil, "dimensions do not match a known atlas layout"
end

-- ---------------------------------------------------------------------------
-- trilinear sampling (mirrors sample_lut in shader_spec.effect)
-- ---------------------------------------------------------------------------

local function clamp01(v)
  if v < 0 then return 0 elseif v > 1 then return 1 end
  return v
end

local function lerp(a, b, t)
  return a + (b - a) * t
end

--- Trilinear-interpolate the LUT at (r, g, b), inputs clamped to 0..1.
--- Returns the raw (unclamped) interpolated LUT output.
function M.sample(lut, r, g, b)
  local n = lut.size
  r, g, b = clamp01(r), clamp01(g), clamp01(b)

  local rf = r * (n - 1)
  local r0 = floor(rf)
  local r1 = r0 + 1; if r1 > n - 1 then r1 = n - 1 end
  local fr = rf - r0

  local gf = g * (n - 1)
  local g0 = floor(gf)
  local g1 = g0 + 1; if g1 > n - 1 then g1 = n - 1 end
  local fg = gf - g0

  local bf = b * (n - 1)
  local b0 = floor(bf)
  local b1 = b0 + 1; if b1 > n - 1 then b1 = n - 1 end
  local fb = bf - b0

  local r000, g000, b000 = get_rgb(lut, r0, g0, b0)
  local r100, g100, b100 = get_rgb(lut, r1, g0, b0)
  local r010, g010, b010 = get_rgb(lut, r0, g1, b0)
  local r110, g110, b110 = get_rgb(lut, r1, g1, b0)
  local r001, g001, b001 = get_rgb(lut, r0, g0, b1)
  local r101, g101, b101 = get_rgb(lut, r1, g0, b1)
  local r011, g011, b011 = get_rgb(lut, r0, g1, b1)
  local r111, g111, b111 = get_rgb(lut, r1, g1, b1)

  -- blue plane b0: bilinear over r then g
  local rTop0, gTop0, bTop0 = lerp(r000, r100, fr), lerp(g000, g100, fr), lerp(b000, b100, fr)
  local rBot0, gBot0, bBot0 = lerp(r010, r110, fr), lerp(g010, g110, fr), lerp(b010, b110, fr)
  local planeR0, planeG0, planeB0 = lerp(rTop0, rBot0, fg), lerp(gTop0, gBot0, fg), lerp(bTop0, bBot0, fg)

  -- blue plane b1
  local rTop1, gTop1, bTop1 = lerp(r001, r101, fr), lerp(g001, g101, fr), lerp(b001, b101, fr)
  local rBot1, gBot1, bBot1 = lerp(r011, r111, fr), lerp(g011, g111, fr), lerp(b011, b111, fr)
  local planeR1, planeG1, planeB1 = lerp(rTop1, rBot1, fg), lerp(gTop1, gBot1, fg), lerp(bTop1, bBot1, fg)

  -- interpolate between the two blue planes
  return lerp(planeR0, planeR1, fb), lerp(planeG0, planeG1, fb), lerp(planeB0, planeB1, fb)
end

-- ---------------------------------------------------------------------------
-- FNV-1a 32-bit hash -> lowercase 8-hex-char string
-- ---------------------------------------------------------------------------

local FNV_C_HI, FNV_C_LO = 0x0100, 0x0193 -- 16777619 (FNV prime) split into 16-bit halves

--- FNV-1a 32-bit hash of str, returned as an 8-char lowercase hex string.
--- Uses only bxor plus plain arithmetic (h stays an unsigned value < 2^32).
function M.fnv1a(str)
  local h = 0x811c9dc5
  local byte = string.byte
  for i = 1, #str do
    h = bxor(h, byte(str, i)) % 4294967296
    -- 32-bit multiply h * 16777619 mod 2^32, split into 16-bit halves to
    -- avoid double-precision overflow.
    local h_lo = h % 65536
    local h_hi = (h - h_lo) / 65536
    local low = h_lo * FNV_C_LO
    local mid = (h_lo * FNV_C_HI + h_hi * FNV_C_LO) % 65536
    h = (low + mid * 65536) % 4294967296
  end
  return string.format("%08x", h)
end

--- Fast 32-bit content checksum for cache keys (multiplicative rolling hash,
--- exact in double precision). ~10x faster than fnv1a on multi-MB strings.
function M.checksum(str)
  local h = 2166136261
  local byte = string.byte
  local n = #str
  local i = 1
  while i + 3 <= n do
    local a, b, c, d = byte(str, i, i + 3)
    h = (h * 31 + a) % 4294967296
    h = (h * 31 + b) % 4294967296
    h = (h * 31 + c) % 4294967296
    h = (h * 31 + d) % 4294967296
    i = i + 4
  end
  while i <= n do
    h = (h * 31 + byte(str, i)) % 4294967296
    i = i + 1
  end
  return string.format("%08x", h)
end

--- Cheap size probe without a full parse: LUT_3D_SIZE value or nil.
function M.peek_size(text)
  if type(text) ~= "string" then return nil end
  local s = text:match("LUT_3D_SIZE%s+(%d+)")
  return s and tonumber(s) or nil
end

return M
end)()

-- ===== MODULE: grade_pixel (dev/lua/grade_pixel.lua) ========================
local grade_pixel = (function()
-- grade_pixel.lua
-- Pure-Lua (5.1 / LuaJIT compatible) port of the NON-spatial colour pipeline defined
-- in dev/shader_spec.effect: grade_color() stages 1-10, followed by the LUT blend
-- stage and the final saturate from PSDefault(). Used to bake the current look into
-- a .cube LUT that matches the on-screen image.
--
-- Skipped on purpose (cannot be baked into a colour-only LUT, see shader_spec.effect
-- header comment): bloom, halation, sharpen (unsharp_mask), vignette, grain, mask.
-- Those all need neighbouring pixels and/or per-pixel screen position (uv), not just
-- the pixel's own colour.
--
-- No globals: require()/dofile() this file, it returns a module table.

local M = {}

-- saturate(x) = clamp(x, 0, 1), matching HLSL's per-component saturate().
local function saturate(x)
    if x < 0.0 then return 0.0 end
    if x > 1.0 then return 1.0 end
    return x
end

-- lerp(a, b, t) = a + (b - a) * t, matching HLSL's lerp().
local function lerp(a, b, t)
    return a + (b - a) * t
end

-- smoothstep(e0, e1, x): t = clamp((x-e0)/(e1-e0), 0, 1); return t*t*(3-2t).
local function smoothstep(e0, e1, x)
    local t = (x - e0) / (e1 - e0)
    if t < 0.0 then
        t = 0.0
    elseif t > 1.0 then
        t = 1.0
    end
    return t * t * (3.0 - 2.0 * t)
end

M.saturate = saturate
M.lerp = lerp
M.smoothstep = smoothstep

-- luma_of(c) = dot(c, float3(0.2126, 0.7152, 0.0722))  -- Rec.709, used in grade_color.
local function luma709(r, g, b)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

-- number parameter, default 0 when nil
local function num(v)
    return v or 0.0
end

-- {r, g, b} colour table (index 1..3), default {0,0,0} when nil
local function col3(v)
    if v == nil then
        return 0.0, 0.0, 0.0
    end
    return v[1] or 0.0, v[2] or 0.0, v[3] or 0.0
end

-- {r, g, b, w} colour+strength table (index 1..4), default {0,0,0,0} when nil
local function col4(v)
    if v == nil then
        return 0.0, 0.0, 0.0, 0.0
    end
    return v[1] or 0.0, v[2] or 0.0, v[3] or 0.0, v[4] or 0.0
end

--- grade_color(p, r, g, b) -> r, g, b
--- Exact port of grade_color() in shader_spec.effect (stages 1-10). Exposed mainly
--- for tests; M.grade() is the public entry point.
local function grade_color(p, r, g, b)
    local exposure = num(p.exposure)
    local contrast = num(p.contrast)
    local brightness = num(p.brightness)
    local highlights = num(p.highlights)
    local shadows = num(p.shadows)
    local whites = num(p.whites)
    local blacks = num(p.blacks)
    local black_lift = num(p.black_lift)
    local highlight_fade = num(p.highlight_fade)
    local shadow_fade = num(p.shadow_fade)
    local temperature = num(p.temperature)
    local tint = num(p.tint)
    local saturation = num(p.saturation)
    local vibrance = num(p.vibrance)

    local sh_r, sh_g, sh_b = col3(p.shadows_color)
    local mid_r, mid_g, mid_b = col3(p.midtones_color)
    local hi_r, hi_g, hi_b = col3(p.highlights_color)
    local ss_r, ss_g, ss_b, ss_w = col4(p.split_shadow)
    local sh2_r, sh2_g, sh2_b, sh2_w = col4(p.split_highlight)

    -- 1. exposure
    local factor = 2.0 ^ exposure
    r = r * factor
    g = g * factor
    b = b * factor

    -- 2. tonal ranges, weighted by luminance so hues do not drift
    local l = luma709(r, g, b)
    local hw = smoothstep(0.5, 1.0, l)
    local sw = 1.0 - smoothstep(0.0, 0.5, l)
    local ww = smoothstep(0.7, 1.0, l)
    local bw = 1.0 - smoothstep(0.0, 0.3, l)
    local lw = 1.0 - smoothstep(0.0, 0.4, l)
    local mult = (1.0 + highlights * hw) * (1.0 + shadows * sw)
    r = r * mult
    g = g * mult
    b = b * mult
    local add = whites * 0.5 * ww + blacks * 0.5 * bw + black_lift * 0.5 * lw
    r = r + add
    g = g + add
    b = b + add

    -- 3. brightness, 4. contrast (pivot at mid grey)
    r = r + brightness
    g = g + brightness
    b = b + brightness
    local cf = 1.0 + contrast
    r = (r - 0.5) * cf + 0.5
    g = (g - 0.5) * cf + 0.5
    b = (b - 0.5) * cf + 0.5

    -- 5. white balance: + temperature = warmer, + tint = magenta
    r = r + temperature * 0.1 + tint * 0.05
    g = g + temperature * 0.0 + tint * (-0.1)
    b = b + temperature * (-0.1) + tint * 0.05
    r, g, b = saturate(r), saturate(g), saturate(b)

    -- 6. fades towards white (film bleach look) -- both weights are sampled from the
    -- SAME luma l (computed once before either lerp), exactly as in the .effect.
    l = luma709(r, g, b)
    local t_hi = smoothstep(0.7, 1.0, l) * highlight_fade
    r, g, b = lerp(r, 1.0, t_hi), lerp(g, 1.0, t_hi), lerp(b, 1.0, t_hi)
    local t_sh = (1.0 - smoothstep(0.0, 0.3, l)) * shadow_fade
    r, g, b = lerp(r, 1.0, t_sh), lerp(g, 1.0, t_sh), lerp(b, 1.0, t_sh)

    -- 7. colour wheels
    l = luma709(r, g, b)
    local w_sh = 1.0 - smoothstep(0.0, 0.5, l)
    local w_hi = smoothstep(0.5, 1.0, l)
    local w_mid = 1.0 - w_sh - w_hi
    r = saturate(r + sh_r * w_sh * 0.5 + mid_r * w_mid * 0.3 + hi_r * w_hi * 0.5)
    g = saturate(g + sh_g * w_sh * 0.5 + mid_g * w_mid * 0.3 + hi_g * w_hi * 0.5)
    b = saturate(b + sh_b * w_sh * 0.5 + mid_b * w_mid * 0.3 + hi_b * w_hi * 0.5)

    -- 8. split toning (sequential: the highlight lerp reads the shadow-toned colour)
    l = luma709(r, g, b)
    local wS = saturate(1.0 - l * 2.0)
    local wH = saturate((l - 0.5) * 2.0)
    do
        local tr, tg, tb = saturate(r + ss_r), saturate(g + ss_g), saturate(b + ss_b)
        local t = ss_w * wS
        r, g, b = lerp(r, tr, t), lerp(g, tg, t), lerp(b, tb, t)
    end
    do
        local tr, tg, tb = saturate(r + sh2_r), saturate(g + sh2_g), saturate(b + sh2_b)
        local t = sh2_w * wH
        r, g, b = lerp(r, tr, t), lerp(g, tg, t), lerp(b, tb, t)
    end

    -- 9. saturation
    local gl = luma709(r, g, b)
    local sf = 1.0 + saturation
    r, g, b = lerp(gl, r, sf), lerp(gl, g, sf), lerp(gl, b, sf)

    -- 10. vibrance (boosts low-saturation colours more than saturated ones)
    local lum = luma709(r, g, b)
    local mx = math.max(r, g, b)
    local mn = math.min(r, g, b)
    local sat = (mx - mn) / math.max(mx, 0.0001)
    local vf = 1.0 + vibrance * (1.0 - sat)
    r, g, b = lerp(lum, r, vf), lerp(lum, g, vf), lerp(lum, b, vf)

    return r, g, b
end

M.grade_color = grade_color

--- M.grade(p, r, g, b) -> r, g, b
--- Full non-spatial pipeline used to bake a LUT: grade_color() stages 1-10, then (if
--- p.lut_strength > 0.001 and both p.lut and p.lut_sample are given) the LUT blend
---   c = lerp(c, lut_sample(lut, saturate(c)), lut_strength)
--- (mirroring sample_lut()'s internal saturate of its input), then the final
--- saturate that PSDefault() applies before writing the pixel. Spatial stages
--- (bloom, halation, sharpen, vignette, grain, mask) are intentionally not
--- reproduced -- see file header.
function M.grade(p, r, g, b)
    r, g, b = grade_color(p, r, g, b)

    local lut_strength = num(p.lut_strength)
    if lut_strength > 0.001 and p.lut and p.lut_sample then
        local sr, sg, sb = saturate(r), saturate(g), saturate(b)
        local lr, lg, lb = p.lut_sample(p.lut, sr, sg, sb)
        r = lerp(r, lr, lut_strength)
        g = lerp(g, lg, lut_strength)
        b = lerp(b, lb, lut_strength)
    end

    return saturate(r), saturate(g), saturate(b)
end

return M
end)()

-- ---------------------------------------------------------------------------
-- Datei- und Grafik-Hilfsfunktionen
-- ---------------------------------------------------------------------------

-- Führt eine Grafikoperation aus und gibt den Grafik-Lock auch bei Lua-Fehlern frei.
local function graphics_call(callback)
    obs.obs_enter_graphics()
    local ok, result = pcall(callback)
    obs.obs_leave_graphics()
    if not ok then log_warn("Fehler im Grafik-Kontext: " .. tostring(result)) end
    return ok, result
end

local function file_extension(path)
    return (path or ""):match("%.([%w]+)$")
end

local function read_text_file(path)
    local fh = io.open(path, "rb")
    if fh then
        local text = fh:read("*a")
        fh:close()
        return text
    end
    -- io.open kann auf Windows an Nicht-ASCII-Pfaden scheitern; libobs liest UTF-8-Pfade.
    if obs.os_quick_read_utf8_file then
        local text = obs.os_quick_read_utf8_file(path)
        if text and text ~= "" then return text end
    end
    return nil
end

local function write_binary_file(path, bytes)
    local fh, err = io.open(path, "wb")
    if fh then
        local ok, werr = fh:write(bytes)
        fh:close()
        if ok then return true end
        os.remove(path)   -- keine halbe Datei zurücklassen
        return false, werr
    end
    -- io.open scheitert auf Windows an Nicht-ASCII-Pfaden; libobs schreibt UTF-8-Pfade.
    -- Die Länge wird explizit übergeben, daher sind NUL-Bytes (PNG) unproblematisch.
    if obs.os_quick_write_utf8_file then
        local ok = pcall(obs.os_quick_write_utf8_file, path, bytes, #bytes, false)
        if ok then return true end
    end
    return false, err
end

local function write_text_file(path, text)
    if obs.os_quick_write_utf8_file then
        local ok = obs.os_quick_write_utf8_file(path, text, #text, false)
        if ok then return true end
    end
    return write_binary_file(path, text)
end

local function file_exists(path)
    if obs.os_file_exists then return obs.os_file_exists(path) end
    local fh = io.open(path, "rb")
    if fh then fh:close() return true end
    return false
end

local function path_separator()
    return package.config:sub(1, 1)
end

-- Cache-Ordner für konvertierte LUTs; ein Treffer wird gemerkt, ein Fehlschlag nicht
-- (sonst würde ein einmaliger IO-Fehler LUTs für die ganze Sitzung blockieren).
local cache_dir_cache = nil
local function lut_cache_dir()
    if cache_dir_cache then return cache_dir_cache end
    local candidates = {}
    if obs.os_get_config_path_ptr then
        local ok, dir = pcall(obs.os_get_config_path_ptr, "obs-studio/plugin_config/lumetric_corrector")
        if ok and type(dir) == "string" and dir ~= "" then table.insert(candidates, dir) end
    end
    local tmp = os.getenv("TEMP") or os.getenv("TMP") or os.getenv("TMPDIR") or "/tmp"
    table.insert(candidates, tmp .. path_separator() .. "lumetric_corrector")
    for _, dir in ipairs(candidates) do
        if obs.os_mkdirs then pcall(obs.os_mkdirs, dir) end
        local probe = dir .. path_separator() .. ".write_test"
        if write_binary_file(probe, "ok") then
            os.remove(probe)
            cache_dir_cache = dir
            return dir
        end
    end
    return nil
end

local function default_documents_path(filename)
    local home = os.getenv("USERPROFILE") or os.getenv("HOME") or ""
    local sep = path_separator()
    local docs = home .. sep .. "Documents"
    if obs.os_file_exists and not obs.os_file_exists(docs) then
        docs = home   -- z. B. Linux ohne XDG-Dokumentenordner
    end
    return docs .. sep .. filename
end

-- ---------------------------------------------------------------------------
-- LUT laden. Zwei Schritte, damit der UI-Thread nie den Grafik-Kontext braucht:
--   prepare_lut  (update, CPU):  .cube parsen und als PNG-Atlas im Cache ablegen
--   apply_lut    (render, GPU):  Textur aus der PNG-Datei erzeugen und binden
-- ---------------------------------------------------------------------------
local function lut_display_name(path)
    return path:match("([^/\\]+)$") or path
end

local function set_lut_error(data, path, err)
    data.lut_status = "LUT error: " .. tostring(err)
    data.lut_error = true
    log_error("LUT load failed (" .. tostring(path) .. "): " .. tostring(err))
end

-- Liefert eine Beschreibung der zu ladenden Textur oder nil bei Fehler.
local function prepare_lut(data, path)
    data.lut_error = false
    if not path or path == "" then
        data.lut_status = ""
        return nil
    end
    local ext = (file_extension(path) or ""):lower()
    if ext == "png" then
        return { path = path, candidates = { { png = path, bits = nil } }, detect_layout = true }
    end
    if ext ~= "cube" then
        set_lut_error(data, path, "unsupported file type ." .. ext .. " (use .cube or .png)")
        return nil
    end
    local text = read_text_file(path)
    if not text then
        set_lut_error(data, path, "file not readable")
        return nil
    end
    local dir = lut_cache_dir()
    if not dir then
        set_lut_error(data, path, "no writable cache folder")
        return nil
    end
    -- Cache-Schlüssel über den kompletten Inhalt: eine geänderte Datei erzeugt einen neuen Atlas.
    local size = cube_lut.peek_size(text)
    local key = cube_lut.checksum(text) .. cube_lut.fnv1a(path)
    local candidates = {}
    local lut = nil
    for _, bits in ipairs({ 16, 8 }) do
        local png_path = dir .. path_separator() .. string.format("lut_%s_%s_%dbit.png", key, tostring(size), bits)
        if not file_exists(png_path) then
            if not lut then
                local err
                lut, err = cube_lut.parse_cube(text)   -- nur bei Cache-Fehltreffer parsen
                if not lut then
                    set_lut_error(data, path, err)
                    return nil
                end
                size = lut.size
            end
            local rows, w, h = cube_lut.atlas_rows(lut, bits)
            local ok, werr = write_binary_file(png_path, png_encoder.encode_rgba(w, h, rows, bits))
            if not ok then
                set_lut_error(data, path, "cannot write cache file: " .. tostring(werr))
                return nil
            end
        end
        candidates[#candidates + 1] = { png = png_path, bits = bits }
    end
    if not size then
        set_lut_error(data, path, "missing LUT_3D_SIZE")
        return nil
    end
    data.lut_status = lut_display_name(path) .. ": prepared"
    return { path = path, candidates = candidates, size = size, tiles = size, is_cube = true }
end

-- Nur im Grafik-Kontext aufrufen (video_render oder graphics_call).
local function release_lut_texture(data)
    if data.lut and data.lut.tex then
        pcall(obs.gs_texture_destroy, data.lut.tex)
    end
    data.lut = nil
end

-- Nur im Grafik-Kontext aufrufen.
local function apply_pending_lut(data)
    local pending = data.lut_pending
    data.lut_pending = nil
    release_lut_texture(data)
    data.dirty = true
    if not pending then return end
    for _, cand in ipairs(pending.candidates) do
        local ok, tex = pcall(obs.gs_texture_create_from_file, cand.png)
        if ok and tex then
            local w, h = obs.gs_texture_get_width(tex), obs.gs_texture_get_height(tex)
            local size, tiles = pending.size, pending.tiles
            if pending.detect_layout then
                local err
                size, tiles, err = cube_lut.layout_from_dims(w, h)
                if not size then
                    pcall(obs.gs_texture_destroy, tex)
                    set_lut_error(data, pending.path, string.format("unsupported PNG layout %dx%d (expected 512x512 grid or N*N x N strip)", w, h))
                    return
                end
            end
            data.lut = { tex = tex, size = size, tiles = tiles, w = w, h = h, path = pending.path, is_cube = pending.is_cube, bits = cand.bits }
            data.lut_status = string.format("%s: %dx%dx%d", lut_display_name(pending.path), size, size, size)
            log_info("LUT loaded: " .. data.lut_status)
            return
        end
        log_warn("LUT texture could not be created from " .. tostring(cand.png) .. ", trying next candidate")
        if pending.is_cube then os.remove(cand.png) end   -- defekte Cache-Datei nicht wiederverwenden
    end
    set_lut_error(data, pending.path, "texture creation failed")
end

-- ---------------------------------------------------------------------------
-- Look- und LUT-Export
-- ---------------------------------------------------------------------------
local function build_grade_params(data)
    local v = data.v
    local p = {}
    for _, def in ipairs(PARAMS) do
        if def.shader then p[def.shader] = v[def.key] end
    end
    -- grade_pixel erwartet die Settings-Namen der Tonwerte
    for _, key in ipairs({ "exposure", "contrast", "brightness", "highlights", "shadows", "whites", "blacks",
                           "black_lift", "highlight_fade", "shadow_fade", "temperature", "tint", "saturation", "vibrance" }) do
        p[key] = v[key]
    end
    p.shadows_color    = { v.shadows_color_r,    v.shadows_color_g,    v.shadows_color_b }
    p.midtones_color   = { v.midtones_color_r,   v.midtones_color_g,   v.midtones_color_b }
    p.highlights_color = { v.highlights_color_r, v.highlights_color_g, v.highlights_color_b }
    p.split_shadow     = { v.ss_r, v.ss_g, v.ss_b, v.ss_sat }
    p.split_highlight  = { v.sh_r, v.sh_g, v.sh_b, v.sh_sat }
    p.lut_strength = v.lut_strength
    if data.lut and v.lut_strength > 0.001 then
        local cube = nil
        if data.lut.is_cube then
            local text = read_text_file(data.lut.path)
            cube = text and cube_lut.parse_cube(text) or nil   -- für den Export frisch parsen
        end
        if cube then
            p.lut = cube
            p.lut_sample = cube_lut.sample
        else
            log_warn("LUT export: the loaded LUT could not be baked into the export (PNG LUT or unreadable file), it is skipped")
        end
    end
    return p
end

local function export_lut_cube(data, path)
    local p = build_grade_params(data)
    local size = 33
    local out = {
        "# Created with Lumetric Corrector " .. VERSION .. " for OBS Studio",
        "# " .. os.date("%Y-%m-%d %H:%M:%S"),
        'TITLE "Lumetric Corrector look"',
        "LUT_3D_SIZE " .. size,
        "DOMAIN_MIN 0.0 0.0 0.0",
        "DOMAIN_MAX 1.0 1.0 1.0",
        "",
    }
    local n = size - 1
    for b = 0, n do
        for g = 0, n do
            for r = 0, n do
                local ro, go, bo = grade_pixel.grade(p, r / n, g / n, b / n)
                out[#out + 1] = string.format("%.6f %.6f %.6f", ro, go, bo)
            end
        end
    end
    out[#out + 1] = ""
    return write_text_file(path, table.concat(out, "\n"))
end

-- OBS-kompatibles 512x512-Raster (64³, 8 Kacheln pro Zeile, 8 Bit)
local function export_lut_png(data, path)
    local p = build_grade_params(data)
    local size, tiles = 64, 8
    local n = size - 1
    local rows = {}
    local char = string.char
    for y = 0, size * tiles - 1 do
        local g = y % size
        local tile_row = math.floor(y / size)
        local row = {}
        for x = 0, size * tiles - 1 do
            local r = x % size
            local b = tile_row * tiles + math.floor(x / size)
            local ro, go, bo = grade_pixel.grade(p, r / n, g / n, b / n)
            row[#row + 1] = char(math.floor(ro * 255 + 0.5), math.floor(go * 255 + 0.5), math.floor(bo * 255 + 0.5), 255)
        end
        rows[#rows + 1] = table.concat(row)
    end
    local png = png_encoder.encode_rgba(size * tiles, size * tiles, rows, 8)
    return write_binary_file(path, png)
end

local function export_lut(data, path)
    if not path or path == "" then return false, "no path" end
    local ext = (file_extension(path) or ""):lower()
    if ext ~= "cube" and ext ~= "png" then
        path = path .. ".cube"
        ext = "cube"
    end
    local ok, err
    if ext == "png" then ok, err = export_lut_png(data, path) else ok, err = export_lut_cube(data, path) end
    if ok then
        log_info("LUT exported: " .. path)
    else
        log_error("LUT export failed (" .. path .. "): " .. tostring(err))
    end
    return ok, err
end

local function export_look(data, path)
    if not path or path == "" then return false end
    if not path:lower():match("%.json$") then path = path .. ".json" end
    local d = obs.obs_data_create()
    obs.obs_data_set_string(d, "lumetric_look_version", VERSION)
    for _, def in ipairs(PARAMS) do
        if is_look_key(def.key) then obs.obs_data_set_double(d, def.key, data.v[def.key]) end
    end
    local ok = obs.obs_data_save_json_safe(d, path, "tmp", "bak")
    obs.obs_data_release(d)
    if ok then log_info("Look saved: " .. path) else log_error("Look could not be saved: " .. path) end
    return ok
end

local function import_look(data, path)
    if not path or path == "" or not data.settings then return false end
    local d = obs.obs_data_create_from_json_file(path)
    if not d then
        log_error("Look could not be read: " .. path)
        return false
    end
    local count = 0
    for _, def in ipairs(PARAMS) do
        if is_look_key(def.key) and obs.obs_data_has_user_value(d, def.key) then
            local value = obs.obs_data_get_double(d, def.key)
            value = math.max(def.min, math.min(def.max, value))
            obs.obs_data_set_double(data.settings, def.key, value)
            count = count + 1
        end
    end
    obs.obs_data_release(d)
    if count == 0 then
        log_warn("Look file contains no known settings: " .. path)
        return false
    end
    obs.obs_source_update(data.source, nil)
    log_info(string.format("Look loaded (%d settings): %s", count, path))
    return true
end

-- ---------------------------------------------------------------------------
-- Presets anwenden
-- ---------------------------------------------------------------------------
local function apply_preset_to_settings(settings, preset)
    for _, def in ipairs(PARAMS) do
        if is_look_key(def.key) then
            local value = preset.v[def.key]
            if value == nil then value = def.def end
            obs.obs_data_set_double(settings, def.key, value)
        end
    end
end

local function reset_settings(settings)
    for _, def in ipairs(PARAMS) do
        obs.obs_data_set_double(settings, def.key, def.def)
    end
    obs.obs_data_set_bool(settings, "enable_mask", false)
    obs.obs_data_set_double(settings, "mask_shape", 1.0)
    obs.obs_data_set_string(settings, "preset_select", "")
end

-- ---------------------------------------------------------------------------
-- Filter-Definition
-- ---------------------------------------------------------------------------
local source_info = {}
source_info.id = "lumetric_corrector_filter"
source_info.type = obs.OBS_SOURCE_TYPE_FILTER
source_info.output_flags = bit.bor(obs.OBS_SOURCE_VIDEO, obs.OBS_SOURCE_CUSTOM_DRAW)

source_info.get_name = function()
    return tr("lumetric_corrector")
end

source_info.get_defaults = function(settings)
    for _, def in ipairs(PARAMS) do
        obs.obs_data_set_default_double(settings, def.key, def.def)
    end
    obs.obs_data_set_default_bool(settings, "enable_mask", false)
    obs.obs_data_set_default_double(settings, "mask_shape", 1.0)
    obs.obs_data_set_default_string(settings, "preset_select", "")
    obs.obs_data_set_default_string(settings, "lut_path", "")
    obs.obs_data_set_default_string(settings, "lut_export_path", default_documents_path("lumetric_look.cube"))
    obs.obs_data_set_default_string(settings, "look_export_path", default_documents_path("lumetric_look.json"))
    obs.obs_data_set_default_string(settings, "look_import_path", "")
end

-- Eigene Referenz auf die Settings halten: Button-Callbacks laufen, nachdem
-- create/update zurückgekehrt sind; das übergebene Objekt ist nur geliehen.
local function retain_settings(data, settings)
    if settings ~= nil then obs.obs_data_addref(settings) end
    if data.settings ~= nil then obs.obs_data_release(data.settings) end
    data.settings = settings
end

local function cleanup_legacy_keys(settings)
    if not obs.obs_data_has_user_value(settings, "dirty") and
       not obs.obs_data_has_user_value(settings, "last_exposure") and
       not obs.obs_data_has_user_value(settings, "shadows_red") then
        return
    end
    for _, key in ipairs(LEGACY_JUNK_KEYS) do
        if obs.obs_data_has_user_value(settings, key) then obs.obs_data_erase(settings, key) end
    end
    log_info("Removed legacy keys from filter settings")
end

source_info.update = function(data, settings)
    if not data then return end
    retain_settings(data, settings)
    cleanup_legacy_keys(settings)

    local v = data.v
    for _, def in ipairs(PARAMS) do
        v[def.key] = obs.obs_data_get_double(settings, def.key)
    end
    v.enable_mask = obs.obs_data_get_bool(settings, "enable_mask")
    v.mask_shape = obs.obs_data_get_double(settings, "mask_shape")

    local lut_path = obs.obs_data_get_string(settings, "lut_path") or ""
    if lut_path ~= data.lut_path then
        data.lut_path = lut_path
        data.lut_pending = prepare_lut(data, lut_path)
        data.lut_change = true   -- Textur wird im nächsten Render-Aufruf getauscht
    end

    data.dirty = true
end

-- Uniforms übertragen; nur wenn sich etwas geändert hat (dirty) oder jedes
-- Frame für die animierten Teile.
local function upload_params(data, width, height)
    local params = data.params
    local v = data.v

    if data.dirty then
        for _, def in ipairs(PARAMS) do
            local param = def.shader and params[def.shader]
            if param then obs.gs_effect_set_float(param, v[def.key]) end
        end
        for _, vec in ipairs(VEC4_PARAMS) do
            local param = params[vec.shader]
            if param then
                local t = data.vec4
                t.x = v[vec.keys[1]] or 0
                t.y = v[vec.keys[2]] or 0
                t.z = v[vec.keys[3]] or 0
                t.w = v[vec.keys[4]] or 0
                obs.gs_effect_set_vec4(param, t)
            end
        end
        if params.enable_mask then obs.gs_effect_set_float(params.enable_mask, v.enable_mask and 1.0 or 0.0) end
        if params.mask_roundness then obs.gs_effect_set_float(params.mask_roundness, v.mask_shape or 1.0) end
        if params.mask_pos then
            local t = data.vec2
            t.x = v.mask_x; t.y = v.mask_y
            obs.gs_effect_set_vec2(params.mask_pos, t)
        end
        if params.mask_size then
            local t = data.vec2
            t.x = v.mask_width; t.y = v.mask_height
            obs.gs_effect_set_vec2(params.mask_size, t)
        end
        if params.lut_info then
            local t = data.vec4
            if data.lut then
                t.x = data.lut.size; t.y = data.lut.tiles; t.z = 1.0 / data.lut.w; t.w = 1.0 / data.lut.h
            else
                t.x = 2; t.y = 2; t.z = 1; t.w = 1
            end
            obs.gs_effect_set_vec4(params.lut_info, t)
        end
        if params.lut_tex and data.lut and data.lut.tex then
            obs.gs_effect_set_texture(params.lut_tex, data.lut.tex)
        end
        if params.lut_strength and not data.lut then
            obs.gs_effect_set_float(params.lut_strength, 0.0)   -- keine LUT geladen: Stufe überspringen
        end
        if params.grain_time then obs.gs_effect_set_float(params.grain_time, data.time) end
        data.dirty = false
    end

    if params.buffer_size and (data.uploaded_width ~= width or data.uploaded_height ~= height) then
        local t = data.vec4
        t.x = width; t.y = height; t.z = 1.0 / width; t.w = 1.0 / height
        obs.gs_effect_set_vec4(params.buffer_size, t)
        data.uploaded_width = width
        data.uploaded_height = height
    end

    if params.grain_time and v.grain_amount > 0 then
        obs.gs_effect_set_float(params.grain_time, data.time)
    end
end

-- OBS-Lua-Filter müssen get_width/get_height liefern: obs-scripting installiert die
-- Callbacks immer, und ohne Lua-Funktion melden sie 0. Da OBS die Größe einer
-- Quelle über ihren ersten Filter abfragt, wäre die Quelle dann unsichtbar.
local function target_size(data, getter)
    if not data or not data.source then return 0 end
    local target = obs.obs_filter_get_target(data.source)
    if target == nil then return 0 end
    return getter(target) or 0
end

source_info.get_width = function(data)
    return target_size(data, obs.obs_source_get_base_width)
end

source_info.get_height = function(data)
    return target_size(data, obs.obs_source_get_base_height)
end

source_info.video_tick = function(data, seconds)
    if not data then return end
    data.time = (data.time + (seconds or 0)) % 1000
end

-- Shader erst im Render-Thread bauen: dort ist der Grafik-Kontext bereits aktiv,
-- der UI-Thread muss ihn nie anfordern (vermeidet Lock-Wartezeiten beim Anlegen).
local function ensure_effect(data)
    if data.effect or data.invalid then return end
    local ok, err = pcall(function()
        data.effect = obs.gs_effect_create(shader_code, "lumetric_corrector", nil)
        if not data.effect then error("gs_effect_create returned nil") end
        local names = { "buffer_size", "enable_mask", "mask_pos", "mask_size", "mask_roundness", "lut_info", "lut_tex", "grain_time" }
        for _, def in ipairs(PARAMS) do if def.shader then names[#names + 1] = def.shader end end
        for _, vec in ipairs(VEC4_PARAMS) do names[#names + 1] = vec.shader end
        local count = 0
        for _, name in ipairs(names) do
            local param = obs.gs_effect_get_param_by_name(data.effect, name)
            if param then
                data.params[name] = param
                count = count + 1
            else
                log_warn("shader parameter missing: " .. name)
            end
        end
        -- Direct3D 11 verwirft jeden Draw-Aufruf, solange auch nur ein Constant-Buffer-
        -- Parameter des Shaders noch nie gesetzt wurde ("Not all shader parameters were
        -- set"). Deshalb bekommt jeder Nicht-Textur-Parameter sofort einen Nullwert;
        -- die echten Werte folgen im ersten dirty-Upload.
        local zero4 = data.vec4
        zero4.x, zero4.y, zero4.z, zero4.w = 0, 0, 0, 0
        local zero2 = data.vec2
        zero2.x, zero2.y = 0, 0
        for name, param in pairs(data.params) do
            if VEC2_PARAM_NAMES[name] then
                obs.gs_effect_set_vec2(param, zero2)
            elseif VEC4_PARAM_NAMES[name] then
                obs.gs_effect_set_vec4(param, zero4)
            elseif not TEXTURE_PARAM_NAMES[name] then
                obs.gs_effect_set_float(param, 0.0)
            end
        end
        log_info(string.format("v%s shader ready (%d parameters)", VERSION, count))
    end)
    if not ok then
        data.invalid = true
        log_error("shader could not be created: " .. tostring(err))
    end
    data.dirty = true
    data.uploaded_width = nil
end

source_info.video_render = function(data)
    if not data or not data.source then return end
    ensure_effect(data)
    if not data.effect or data.invalid then
        obs.obs_source_skip_video_filter(data.source)
        return
    end
    if data.lut_change then
        data.lut_change = false
        apply_pending_lut(data)
    end

    local target = obs.obs_filter_get_target(data.source)
    if target == nil then
        obs.obs_source_skip_video_filter(data.source)
        return
    end
    local width = obs.obs_source_get_base_width(target)
    local height = obs.obs_source_get_base_height(target)
    if width == 0 or height == 0 then
        obs.obs_source_skip_video_filter(data.source)
        return
    end

    -- OBS besitzt den Draw-Pass zwischen begin und end. Ein Lua-Fehler beim Setzen
    -- der Uniforms darf den Pass nicht offen lassen.
    local begun = false
    local ok, err = pcall(function()
        begun = obs.obs_source_process_filter_begin(data.source, obs.GS_RGBA, obs.OBS_NO_DIRECT_RENDERING)
        if not begun then return end
        upload_params(data, width, height)
        obs.obs_source_process_filter_end(data.source, data.effect, width, height)
        begun = false
    end)
    if begun then
        pcall(obs.obs_source_process_filter_end, data.source, data.effect, width, height)
    end
    if not ok then
        data.render_errors = (data.render_errors or 0) + 1
        if data.render_errors <= 3 then log_error("Render error: " .. tostring(err)) end
    end
end

source_info.create = function(settings, source)
    local data = {
        source = source,
        settings = nil,
        v = {},
        params = {},
        lut = nil,
        lut_path = nil,
        lut_status = "",
        time = 0,
        dirty = true,
        vec2 = obs.vec2(),
        vec4 = obs.vec4(),
    }
    for _, def in ipairs(PARAMS) do data.v[def.key] = def.def end
    data.v.enable_mask = false
    data.v.mask_shape = 1.0

    -- Shader und LUT-Textur entstehen beim ersten Rendern (siehe ensure_effect).
    source_info.update(data, settings)
    return data
end

source_info.destroy = function(data)
    if not data then return end
    if data.effect or (data.lut and data.lut.tex) then
        graphics_call(function()
            if data.effect then pcall(obs.gs_effect_destroy, data.effect) end
            release_lut_texture(data)
        end)
    end
    data.effect = nil
    data.lut = nil
    data.lut_pending = nil
    if data.settings ~= nil then
        obs.obs_data_release(data.settings)
        data.settings = nil
    end
end

-- ---------------------------------------------------------------------------
-- Eigenschaften (UI)
-- ---------------------------------------------------------------------------
local function add_slider(group, def)
    local prop = obs.obs_properties_add_float_slider(group, def.key, tr(def.key), def.min, def.max, def.step)
    if def.desc then obs.obs_property_set_long_description(prop, tr(def.desc)) end
    return prop
end

local function add_group_with_sliders(props, group_id, def_filter)
    local group = obs.obs_properties_create()
    for _, def in ipairs(PARAMS) do
        if def.group == group_id and (not def_filter or def_filter(def)) then add_slider(group, def) end
    end
    obs.obs_properties_add_group(props, group_id .. "_group", tr(group_id), obs.OBS_GROUP_NORMAL, group)
    return group
end

source_info.get_properties = function(data)
    local props = obs.obs_properties_create()

    -- Presets ---------------------------------------------------------------
    local preset_group = obs.obs_properties_create()
    local preset_list = obs.obs_properties_add_list(preset_group, "preset_select", tr("select_preset"),
        obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    obs.obs_property_set_long_description(preset_list, tr("select_preset_desc"))
    obs.obs_property_list_add_string(preset_list, "", "")
    for _, cat in ipairs(PRESET_CATEGORIES) do
        local idx = obs.obs_property_list_add_string(preset_list, tr(cat.id), "separator_" .. cat.id)
        obs.obs_property_list_item_disable(preset_list, idx, true)
        for _, preset in ipairs(cat.presets) do
            obs.obs_property_list_add_string(preset_list, preset_name(preset.id), preset.id)
        end
    end
    obs.obs_property_set_modified_callback(preset_list, function(_, _, settings)
        local preset = PRESET_BY_ID[obs.obs_data_get_string(settings, "preset_select")]
        if not preset then return false end
        apply_preset_to_settings(settings, preset)
        if data and data.source then obs.obs_source_update(data.source, nil) end
        return true
    end)
    obs.obs_properties_add_button(preset_group, "apply_preset_button", tr("apply_preset"), function()
        if not data or not data.settings then return false end
        local preset = PRESET_BY_ID[obs.obs_data_get_string(data.settings, "preset_select")]
        if not preset then return false end
        apply_preset_to_settings(data.settings, preset)
        obs.obs_source_update(data.source, nil)
        return true
    end)
    obs.obs_properties_add_button(preset_group, "reset_button", tr("reset_all"), function()
        if not data or not data.settings then return false end
        reset_settings(data.settings)
        obs.obs_source_update(data.source, nil)
        return true
    end)
    obs.obs_properties_add_group(props, "presets_group", tr("presets"), obs.OBS_GROUP_NORMAL, preset_group)

    -- Regler-Gruppen -------------------------------------------------------------
    add_group_with_sliders(props, "tone")
    add_group_with_sliders(props, "fade")
    add_group_with_sliders(props, "wb")
    add_group_with_sliders(props, "color")
    add_group_with_sliders(props, "wheels")
    add_group_with_sliders(props, "split")
    add_group_with_sliders(props, "fx")
    add_group_with_sliders(props, "vignette")

    -- Maske (abhakbare Gruppe, Schlüssel enable_mask) -------------------------------
    local mask_group = obs.obs_properties_create()
    local shape_list = obs.obs_properties_add_list(mask_group, "mask_shape", tr("mask_shape"),
        obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_FLOAT)
    obs.obs_property_list_add_float(shape_list, tr("mask_round"), 1.0)
    obs.obs_property_list_add_float(shape_list, tr("mask_rect"), 0.0)
    for _, def in ipairs(PARAMS) do
        if def.group == "mask" then add_slider(mask_group, def) end
    end
    obs.obs_properties_add_group(props, "enable_mask", tr("mask"), obs.OBS_GROUP_CHECKABLE, mask_group)

    -- LUT --------------------------------------------------------------------------
    local lut_group = obs.obs_properties_create()
    local lut_path_prop = obs.obs_properties_add_path(lut_group, "lut_path", tr("lut_path"), obs.OBS_PATH_FILE,
        "LUT (*.cube *.png);;Cube LUT (*.cube);;PNG LUT (*.png);;All files (*.*)", nil)
    obs.obs_property_set_long_description(lut_path_prop, tr("lut_path_desc"))
    add_slider(lut_group, PARAM_BY_KEY.lut_strength)
    local status_text = (data and data.lut_status and data.lut_status ~= "") and data.lut_status or "-"
    local status_prop = obs.obs_properties_add_text(lut_group, "lut_status_text", tr("lut_status") .. ": " .. status_text, obs.OBS_TEXT_INFO)
    if data and data.lut_error and obs.obs_property_text_set_info_type then
        obs.obs_property_text_set_info_type(status_prop, obs.OBS_TEXT_INFO_WARNING)
    end
    obs.obs_property_set_modified_callback(lut_path_prop, function() return true end)  -- Statuszeile aktualisieren
    obs.obs_properties_add_group(props, "lut_group", tr("lut"), obs.OBS_GROUP_NORMAL, lut_group)

    -- Looks & Export -----------------------------------------------------------------
    local looks_group = obs.obs_properties_create()
    obs.obs_properties_add_text(looks_group, "look_info", tr("look_desc"), obs.OBS_TEXT_INFO)
    -- Ergebnis der letzten Aktion (Speichern/Laden/Export) sichtbar machen; die Buttons
    -- geben true zurück, damit OBS die Eigenschaften neu aufbaut und die Zeile aktualisiert.
    local function record_action(ok, label, path)
        if not data then return true end
        data.action_status = (ok and "OK: " or "ERROR: ") .. label .. " " .. tostring(path)
        data.action_failed = not ok
        return true
    end
    obs.obs_properties_add_path(looks_group, "look_export_path", tr("look_export_path"), obs.OBS_PATH_FILE_SAVE,
        "Lumetric Look (*.json)", default_documents_path("lumetric_look.json"))
    obs.obs_properties_add_button(looks_group, "save_look_button", tr("save_look"), function()
        if not data or not data.settings then return false end
        local path = obs.obs_data_get_string(data.settings, "look_export_path")
        return record_action(export_look(data, path), tr("save_look"), path)
    end)
    obs.obs_properties_add_path(looks_group, "look_import_path", tr("look_import_path"), obs.OBS_PATH_FILE,
        "Lumetric Look (*.json);;All files (*.*)", nil)
    obs.obs_properties_add_button(looks_group, "load_look_button", tr("load_look"), function()
        if not data or not data.settings then return false end
        local path = obs.obs_data_get_string(data.settings, "look_import_path")
        return record_action(import_look(data, path), tr("load_look"), path)
    end)
    local lut_export_prop = obs.obs_properties_add_path(looks_group, "lut_export_path", tr("lut_export_path"), obs.OBS_PATH_FILE_SAVE,
        "Cube LUT (*.cube);;PNG LUT (*.png)", default_documents_path("lumetric_look.cube"))
    obs.obs_property_set_long_description(lut_export_prop, tr("lut_export_path_desc"))
    local export_button = obs.obs_properties_add_button(looks_group, "export_lut_button", tr("export_lut"), function()
        if not data or not data.settings then return false end
        local path = obs.obs_data_get_string(data.settings, "lut_export_path")
        local ok = export_lut(data, path)
        return record_action(ok, tr("export_lut"), path)
    end)
    obs.obs_property_set_long_description(export_button, tr("export_lut_desc"))
    if data and data.action_status then
        local action_prop = obs.obs_properties_add_text(looks_group, "action_status_text", data.action_status, obs.OBS_TEXT_INFO)
        if data.action_failed and obs.obs_property_text_set_info_type then
            obs.obs_property_text_set_info_type(action_prop, obs.OBS_TEXT_INFO_WARNING)
        end
    end
    obs.obs_properties_add_group(props, "looks_group", tr("looks"), obs.OBS_GROUP_NORMAL, looks_group)

    -- Info ---------------------------------------------------------------------------
    obs.obs_properties_add_text(props, "info_text", string.format(tr("info_text"), VERSION), obs.OBS_TEXT_INFO)
    return props
end

-- ---------------------------------------------------------------------------
-- Skript-Einstieg
-- ---------------------------------------------------------------------------
function script_description()
    return string.format(
        "<b>%s</b> v%s<br/>" ..
        "Color correction and grading filter: tone, white balance, color wheels, split toning, " ..
        "bloom, halation, sharpen, film grain, vignette, mask, 3D LUT (.cube/.png), LUT and look export, %d presets.<br/><br/>" ..
        "Add it via <i>Filters &rarr; + &rarr; %s</i> on any source or scene.<br/>" ..
        "<a href=\"https://github.com/The-Geek-Freaks/lumetric_corrector\">GitHub</a> &middot; " ..
        "<a href=\"https://tgf.click/discord\">Discord</a>",
        tr("lumetric_corrector"), VERSION, PRESET_COUNT, tr("lumetric_corrector"))
end

function script_load(settings)
    obs.obs_register_source(source_info)
    log_info("Lumetric Corrector v" .. VERSION .. " registered")
end

function script_unload()
end

-- Testhaken: nur aktiv, wenn die Testumgebung vor dem Laden ein Global setzt.
if rawget(_G, "LUMETRIC_TEST_HOOK") then
    LUMETRIC_TEST_HOOK({
        VERSION = VERSION, PARAMS = PARAMS, PARAM_BY_KEY = PARAM_BY_KEY, VEC4_PARAMS = VEC4_PARAMS,
        PRESET_CATEGORIES = PRESET_CATEGORIES, PRESET_BY_ID = PRESET_BY_ID, L10N = L10N, PRESET_NAMES = PRESET_NAMES,
        LEGACY_JUNK_KEYS = LEGACY_JUNK_KEYS, shader_code = shader_code, source_info = source_info,
        png_encoder = png_encoder, cube_lut = cube_lut, grade_pixel = grade_pixel,
        export_lut = export_lut, export_look = export_look, import_look = import_look,
        apply_preset_to_settings = apply_preset_to_settings, reset_settings = reset_settings,
        prepare_lut = prepare_lut, lut_cache_dir = lut_cache_dir, tr = tr, is_look_key = is_look_key,
    })
end
