"""Independent Python reference of grade_color() from dev/shader_spec.effect.

This is a from-scratch re-reading of the HLSL (not a translation of grade_pixel.lua)
used to cross-check dev/lua/grade_pixel.lua. Plain floats, no numpy.

Run standalone to fuzz both implementations against each other:

    uv run --with lupa python dev/tests/ref_grade.py
"""
import math
import random


def hlsl_saturate(x: float) -> float:
    if x < 0.0:
        return 0.0
    if x > 1.0:
        return 1.0
    return x


def hlsl_lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def hlsl_smoothstep(edge0: float, edge1: float, x: float) -> float:
    t = (x - edge0) / (edge1 - edge0)
    if t < 0.0:
        t = 0.0
    elif t > 1.0:
        t = 1.0
    return t * t * (3.0 - 2.0 * t)


def luma_of(r: float, g: float, b: float) -> float:
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def grade_color(params: dict, r: float, g: float, b: float):
    """params keys: exposure, contrast, brightness, highlights, shadows, whites,
    blacks, black_lift, highlight_fade, shadow_fade, temperature, tint, saturation,
    vibrance (floats); shadows_color, midtones_color, highlights_color ((r,g,b));
    split_shadow, split_highlight ((r,g,b,w))."""
    exposure = params.get("exposure", 0.0)
    contrast = params.get("contrast", 0.0)
    brightness = params.get("brightness", 0.0)
    highlights = params.get("highlights", 0.0)
    shadows = params.get("shadows", 0.0)
    whites = params.get("whites", 0.0)
    blacks = params.get("blacks", 0.0)
    black_lift = params.get("black_lift", 0.0)
    highlight_fade = params.get("highlight_fade", 0.0)
    shadow_fade = params.get("shadow_fade", 0.0)
    temperature = params.get("temperature", 0.0)
    tint = params.get("tint", 0.0)
    saturation = params.get("saturation", 0.0)
    vibrance = params.get("vibrance", 0.0)

    sh_r, sh_g, sh_b = params.get("shadows_color", (0.0, 0.0, 0.0))
    mid_r, mid_g, mid_b = params.get("midtones_color", (0.0, 0.0, 0.0))
    hi_r, hi_g, hi_b = params.get("highlights_color", (0.0, 0.0, 0.0))
    ss_r, ss_g, ss_b, ss_w = params.get("split_shadow", (0.0, 0.0, 0.0, 0.0))
    sh2_r, sh2_g, sh2_b, sh2_w = params.get("split_highlight", (0.0, 0.0, 0.0, 0.0))

    # 1. exposure
    factor = math.pow(2.0, exposure)
    r *= factor
    g *= factor
    b *= factor

    # 2. tonal ranges, weighted by luminance
    l = luma_of(r, g, b)
    hw = hlsl_smoothstep(0.5, 1.0, l)
    sw = 1.0 - hlsl_smoothstep(0.0, 0.5, l)
    ww = hlsl_smoothstep(0.7, 1.0, l)
    bw = 1.0 - hlsl_smoothstep(0.0, 0.3, l)
    lw = 1.0 - hlsl_smoothstep(0.0, 0.4, l)
    mult = (1.0 + highlights * hw) * (1.0 + shadows * sw)
    r *= mult
    g *= mult
    b *= mult
    add = whites * 0.5 * ww + blacks * 0.5 * bw + black_lift * 0.5 * lw
    r += add
    g += add
    b += add

    # 3. brightness, 4. contrast
    r += brightness
    g += brightness
    b += brightness
    r = (r - 0.5) * (1.0 + contrast) + 0.5
    g = (g - 0.5) * (1.0 + contrast) + 0.5
    b = (b - 0.5) * (1.0 + contrast) + 0.5

    # 5. white balance
    r += temperature * 0.1 + tint * 0.05
    g += temperature * 0.0 + tint * (-0.1)
    b += temperature * (-0.1) + tint * 0.05
    r, g, b = hlsl_saturate(r), hlsl_saturate(g), hlsl_saturate(b)

    # 6. fades towards white (same l used for both weights)
    l = luma_of(r, g, b)
    t_hi = hlsl_smoothstep(0.7, 1.0, l) * highlight_fade
    r, g, b = hlsl_lerp(r, 1.0, t_hi), hlsl_lerp(g, 1.0, t_hi), hlsl_lerp(b, 1.0, t_hi)
    t_sh = (1.0 - hlsl_smoothstep(0.0, 0.3, l)) * shadow_fade
    r, g, b = hlsl_lerp(r, 1.0, t_sh), hlsl_lerp(g, 1.0, t_sh), hlsl_lerp(b, 1.0, t_sh)

    # 7. colour wheels
    l = luma_of(r, g, b)
    w_sh = 1.0 - hlsl_smoothstep(0.0, 0.5, l)
    w_hi = hlsl_smoothstep(0.5, 1.0, l)
    w_mid = 1.0 - w_sh - w_hi
    r = hlsl_saturate(r + sh_r * w_sh * 0.5 + mid_r * w_mid * 0.3 + hi_r * w_hi * 0.5)
    g = hlsl_saturate(g + sh_g * w_sh * 0.5 + mid_g * w_mid * 0.3 + hi_g * w_hi * 0.5)
    b = hlsl_saturate(b + sh_b * w_sh * 0.5 + mid_b * w_mid * 0.3 + hi_b * w_hi * 0.5)

    # 8. split toning
    l = luma_of(r, g, b)
    wS = hlsl_saturate(1.0 - l * 2.0)
    wH = hlsl_saturate((l - 0.5) * 2.0)
    tr, tg, tb = hlsl_saturate(r + ss_r), hlsl_saturate(g + ss_g), hlsl_saturate(b + ss_b)
    t = ss_w * wS
    r, g, b = hlsl_lerp(r, tr, t), hlsl_lerp(g, tg, t), hlsl_lerp(b, tb, t)
    tr, tg, tb = hlsl_saturate(r + sh2_r), hlsl_saturate(g + sh2_g), hlsl_saturate(b + sh2_b)
    t = sh2_w * wH
    r, g, b = hlsl_lerp(r, tr, t), hlsl_lerp(g, tg, t), hlsl_lerp(b, tb, t)

    # 9. saturation
    gl = luma_of(r, g, b)
    sf = 1.0 + saturation
    r, g, b = hlsl_lerp(gl, r, sf), hlsl_lerp(gl, g, sf), hlsl_lerp(gl, b, sf)

    # 10. vibrance
    lum = luma_of(r, g, b)
    mx = max(r, g, b)
    mn = min(r, g, b)
    sat = (mx - mn) / max(mx, 0.0001)
    vf = 1.0 + vibrance * (1.0 - sat)
    r, g, b = hlsl_lerp(lum, r, vf), hlsl_lerp(lum, g, vf), hlsl_lerp(lum, b, vf)

    return r, g, b


def random_params(rng: random.Random) -> dict:
    def u(lo, hi):
        return rng.uniform(lo, hi)

    return {
        "exposure": u(-1, 1),
        "contrast": u(-1, 1),
        "brightness": u(-1, 1),
        "highlights": u(-1, 1),
        "shadows": u(-1, 1),
        "whites": u(-1, 1),
        "blacks": u(-1, 1),
        "black_lift": u(0, 1),
        "highlight_fade": u(0, 1),
        "shadow_fade": u(0, 1),
        "temperature": u(-1, 1),
        "tint": u(-1, 1),
        "saturation": u(-1, 1),
        "vibrance": u(-1, 1),
        "shadows_color": (u(-1, 1), u(-1, 1), u(-1, 1)),
        "midtones_color": (u(-1, 1), u(-1, 1), u(-1, 1)),
        "highlights_color": (u(-1, 1), u(-1, 1), u(-1, 1)),
        "split_shadow": (u(-1, 1), u(-1, 1), u(-1, 1), u(0, 1)),
        "split_highlight": (u(-1, 1), u(-1, 1), u(-1, 1), u(0, 1)),
    }


def generate_cases(n: int, seed: int = 12345):
    rng = random.Random(seed)
    cases = []
    for _ in range(n):
        p = random_params(rng)
        r, g, b = rng.uniform(0, 1), rng.uniform(0, 1), rng.uniform(0, 1)
        cases.append((p, r, g, b))
    return cases


if __name__ == "__main__":
    # Standalone cross-check: drive grade_pixel.lua via lupa and compare.
    from lupa import luajit21 as lupa
    import os

    here = os.path.dirname(os.path.abspath(__file__)).replace("\\", "/")
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    lua.execute('package.path = "%s/../lua/?.lua;" .. package.path' % here)
    grade_pixel = lua.eval('require("grade_pixel")')

    cases = generate_cases(3000)
    max_diff = 0.0
    worst = None
    for p, r, g, b in cases:
        lp = lua.table_from(
            {
                k: (lua.table_from(v) if isinstance(v, tuple) else v)
                for k, v in p.items()
            }
        )
        lr, lg, lb = grade_pixel.grade_color(lp, r, g, b)
        pr, pg, pb = grade_color(p, r, g, b)
        diff = max(abs(lr - pr), abs(lg - pg), abs(lb - pb))
        if diff > max_diff:
            max_diff = diff
            worst = (p, (r, g, b), (lr, lg, lb), (pr, pg, pb))

    print("cases:", len(cases))
    print("max abs diff:", max_diff)
    if max_diff >= 1e-9:
        print("WORST CASE:", worst)
        raise SystemExit("FAIL: cross-implementation difference too large")
    print("PASS: Lua and Python grade_color agree within 1e-9")
