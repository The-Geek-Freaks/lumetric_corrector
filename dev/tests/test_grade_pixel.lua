-- test_grade_pixel.lua
-- Unit tests for dev/lua/grade_pixel.lua.
-- Run: uv run --with lupa python dev/run_lua.py dev/tests/test_grade_pixel.lua

local grade_pixel = require("grade_pixel")

local pass_count = 0
local fail_count = 0
local failures = {}

local function record(ok, name, detail)
    if ok then
        pass_count = pass_count + 1
    else
        fail_count = fail_count + 1
        failures[#failures + 1] = name .. (detail and (": " .. detail) or "")
    end
end

local function check(ok, name, detail)
    record(ok, name, detail)
end

local function almost_equal(a, b, eps)
    return math.abs(a - b) <= eps
end

----------------------------------------------------------------------
-- 1. Identity: all params default -> grade(p, r, g, b) == (r, g, b)
----------------------------------------------------------------------
do
    local eps = 1e-12
    local p = {}
    local worst = 0.0
    local n = 9
    for i = 0, n - 1 do
        local r = i / (n - 1)
        for j = 0, n - 1 do
            local g = j / (n - 1)
            for k = 0, n - 1 do
                local b = k / (n - 1)
                local or_, og, ob = grade_pixel.grade(p, r, g, b)
                worst = math.max(worst, math.abs(or_ - r), math.abs(og - g), math.abs(ob - b))
            end
        end
    end
    check(worst <= eps, "identity 9x9x9 grid", "max abs diff = " .. tostring(worst))
end

----------------------------------------------------------------------
-- 2. exposure=1 doubles values before clamping (0.25 -> 0.5)
----------------------------------------------------------------------
do
    local p = { exposure = 1.0 }
    local r, g, b = grade_pixel.grade(p, 0.25, 0.25, 0.25)
    check(almost_equal(r, 0.5, 1e-9) and almost_equal(g, 0.5, 1e-9) and almost_equal(b, 0.5, 1e-9),
        "exposure=1 doubles 0.25 -> 0.5",
        string.format("got (%.9f, %.9f, %.9f)", r, g, b))
end

----------------------------------------------------------------------
-- 3. saturation=-1 yields r==g==b
----------------------------------------------------------------------
do
    local p = { saturation = -1.0 }
    local r, g, b = grade_pixel.grade(p, 0.8, 0.3, 0.55)
    check(almost_equal(r, g, 1e-9) and almost_equal(g, b, 1e-9),
        "saturation=-1 desaturates fully",
        string.format("got (%.9f, %.9f, %.9f)", r, g, b))
end

----------------------------------------------------------------------
-- 4. contrast=1 maps 0.5 -> 0.5 and 0.75 -> 1.0
----------------------------------------------------------------------
do
    local p = { contrast = 1.0 }
    local r1 = grade_pixel.grade(p, 0.5, 0.5, 0.5)
    local r2 = grade_pixel.grade(p, 0.75, 0.75, 0.75)
    check(almost_equal(r1, 0.5, 1e-9), "contrast=1 maps 0.5 -> 0.5", tostring(r1))
    check(almost_equal(r2, 1.0, 1e-9), "contrast=1 maps 0.75 -> 1.0", tostring(r2))
end

----------------------------------------------------------------------
-- 5. tint=+1 lowers green relative to tint=0
----------------------------------------------------------------------
do
    local r0, g0, b0 = grade_pixel.grade({ tint = 0.0 }, 0.5, 0.5, 0.5)
    local r1, g1, b1 = grade_pixel.grade({ tint = 1.0 }, 0.5, 0.5, 0.5)
    check(g1 < g0, "tint=+1 lowers green vs tint=0", string.format("g0=%.9f g1=%.9f", g0, g1))
end

----------------------------------------------------------------------
-- 6. temperature=+1 raises red and lowers blue relative to temperature=0
----------------------------------------------------------------------
do
    local r0, g0, b0 = grade_pixel.grade({ temperature = 0.0 }, 0.5, 0.5, 0.5)
    local r1, g1, b1 = grade_pixel.grade({ temperature = 1.0 }, 0.5, 0.5, 0.5)
    check(r1 > r0, "temperature=+1 raises red", string.format("r0=%.9f r1=%.9f", r0, r1))
    check(b1 < b0, "temperature=+1 lowers blue", string.format("b0=%.9f b1=%.9f", b0, b1))
end

----------------------------------------------------------------------
-- 7. exposed helpers behave per HLSL semantics
----------------------------------------------------------------------
do
    check(grade_pixel.saturate(-0.5) == 0.0, "saturate clamps below 0")
    check(grade_pixel.saturate(1.5) == 1.0, "saturate clamps above 1")
    check(almost_equal(grade_pixel.saturate(0.42), 0.42, 1e-15), "saturate passes through [0,1]")

    check(almost_equal(grade_pixel.lerp(0.0, 10.0, 0.3), 3.0, 1e-12), "lerp basic")
    check(almost_equal(grade_pixel.lerp(2.0, 2.0, 0.7), 2.0, 1e-12), "lerp a==b")

    check(grade_pixel.smoothstep(0.5, 1.0, 0.2) == 0.0, "smoothstep below edge0 -> 0")
    check(grade_pixel.smoothstep(0.5, 1.0, 1.2) == 1.0, "smoothstep above edge1 -> 1")
    check(almost_equal(grade_pixel.smoothstep(0.0, 1.0, 0.5), 0.5, 1e-12), "smoothstep midpoint -> 0.5")
end

----------------------------------------------------------------------
-- 8. LUT stage: blend and gating
----------------------------------------------------------------------
do
    local calls = 0
    local stub = function(lut, r, g, b)
        calls = calls + 1
        return 1.0 - r, 1.0 - g, 1.0 - b
    end

    -- lut_strength=0 -> stub must not be called, output equals graded colour unchanged
    calls = 0
    local p0 = { lut = {}, lut_sample = stub, lut_strength = 0.0 }
    local r0, g0, b0 = grade_pixel.grade(p0, 0.2, 0.6, 0.9)
    check(calls == 0, "lut_strength=0 does not call lut_sample", "calls=" .. calls)
    check(almost_equal(r0, 0.2, 1e-12) and almost_equal(g0, 0.6, 1e-12) and almost_equal(b0, 0.9, 1e-12),
        "lut_strength=0 leaves colour unchanged")

    -- lut_strength=0.5 -> blend halfway towards (1-r, 1-g, 1-b)
    calls = 0
    local p1 = { lut = {}, lut_sample = stub, lut_strength = 0.5 }
    local r1, g1, b1 = grade_pixel.grade(p1, 0.2, 0.6, 0.9)
    local er, eg, eb = grade_pixel.lerp(0.2, 0.8, 0.5), grade_pixel.lerp(0.6, 0.4, 0.5), grade_pixel.lerp(0.9, 0.1, 0.5)
    check(calls == 1, "lut_strength=0.5 calls lut_sample exactly once", "calls=" .. calls)
    check(almost_equal(r1, er, 1e-12) and almost_equal(g1, eg, 1e-12) and almost_equal(b1, eb, 1e-12),
        "lut_strength=0.5 blends halfway",
        string.format("got (%.9f,%.9f,%.9f) want (%.9f,%.9f,%.9f)", r1, g1, b1, er, eg, eb))

    -- missing lut table -> LUT stage skipped even if lut_strength > 0.001
    calls = 0
    local p2 = { lut_sample = stub, lut_strength = 0.5 }
    local r2 = grade_pixel.grade(p2, 0.2, 0.6, 0.9)
    check(calls == 0, "missing p.lut skips LUT stage", "calls=" .. calls)
    check(almost_equal(r2, 0.2, 1e-12), "missing p.lut leaves colour unchanged")
end

----------------------------------------------------------------------
-- summary
----------------------------------------------------------------------
print(string.format("PASS: %d, FAIL: %d", pass_count, fail_count))
if fail_count > 0 then
    for _, f in ipairs(failures) do
        print("  FAILED: " .. f)
    end
    error(fail_count .. " test(s) failed")
end
print("ALL TESTS PASSED")
