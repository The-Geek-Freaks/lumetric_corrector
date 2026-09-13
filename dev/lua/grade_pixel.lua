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
