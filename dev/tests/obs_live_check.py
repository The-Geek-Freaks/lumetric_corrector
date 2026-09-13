"""Live rendering check against a running OBS Studio via obs-websocket 5.

Creates a temporary scene with a colour source, attaches the Lumetric filter,
changes settings and compares source screenshots (rendered on the real GPU with
the real shader). Everything created here is removed again at the end.

    uv run --with obsws-python --with pillow python dev/tests/obs_live_check.py [--port 4456] [--password ...]

Requires: OBS running, obs-websocket enabled, the Lumetric script loaded.
"""
import argparse
import base64
import io
import os
import sys
import tempfile
import time

import obsws_python as obs
from PIL import Image

SCENE = "Lumetric Test (temp)"
INPUT = "Lumetric Test Color"
FILTER = "Lumetric Test Filter"
# colour_source_v3 stores 0xAABBGGRR
R, G, B = 204, 102, 51
COLOR = 0xFF000000 | (B << 16) | (G << 8) | R

results: list[tuple[str, bool, str]] = []


def check(name: str, ok: bool, detail: str = "") -> None:
    results.append((name, ok, detail))
    print(("PASS " if ok else "FAIL ") + name + (f"  [{detail}]" if detail else ""))


def screenshot(cl: obs.ReqClient, w: int = 32, h: int = 18) -> Image.Image:
    resp = cl.get_source_screenshot(INPUT, "png", w, h, -1)
    data = resp.image_data.split(",", 1)[1]
    return Image.open(io.BytesIO(base64.b64decode(data))).convert("RGBA")


def px(img: Image.Image, x: int, y: int) -> tuple[int, int, int]:
    return img.getpixel((x, y))[:4]


def close(a: tuple[int, int, int], b: tuple[int, int, int], tol: int = 3) -> bool:
    return all(abs(int(p) - int(q)) <= tol for p, q in zip(a[:3], b[:3]))


def set_filter(cl: obs.ReqClient, **settings) -> None:
    cl.set_source_filter_settings(INPUT, FILTER, settings, True)
    time.sleep(0.4)  # let a couple of frames render


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default="localhost")
    ap.add_argument("--port", type=int, default=4456)
    ap.add_argument("--password", default="")
    args = ap.parse_args()

    cl = obs.ReqClient(host=args.host, port=args.port, password=args.password, timeout=10)
    ver = cl.get_version()
    print(f"OBS {ver.obs_version}, obs-websocket {ver.obs_web_socket_version}")

    kinds = cl.get_source_filter_kind_list().source_filter_kinds
    check("filter kind registered", "lumetric_corrector_filter" in kinds)

    scenes = [s["sceneName"] for s in cl.get_scene_list().scenes]
    if SCENE in scenes:
        cl.remove_scene(SCENE)
        time.sleep(0.3)
    cl.create_scene(SCENE)
    created_scene = True
    created_input = False
    tmpdir = tempfile.mkdtemp(prefix="lumetric_live_")
    try:
        cl.create_input(SCENE, INPUT, "color_source_v3", {"color": COLOR, "width": 320, "height": 180}, True)
        created_input = True
        time.sleep(0.5)

        base = px(screenshot(cl), 16, 9)
        check("baseline colour", close(base, (R, G, B)), f"{base}")

        cl.create_source_filter(INPUT, FILTER, "lumetric_corrector_filter", {})
        time.sleep(0.8)
        ident = px(screenshot(cl), 16, 9)
        check("default filter is identity", close(ident, base), f"{ident}")

        set_filter(cl, exposure=1.0)
        p = px(screenshot(cl), 16, 9)
        check("exposure +1 doubles and clips", close(p, (255, 204, 102)), f"{p}")

        set_filter(cl, exposure=0.0, saturation=-1.0)
        p = px(screenshot(cl), 16, 9)
        luma = round(0.2126 * R + 0.7152 * G + 0.0722 * B)
        check("saturation -1 gives grey", close(p, (luma, luma, luma), 4), f"{p} expected ~{luma}")

        # LUT: 2x2x2 cube that rotates channels (r,g,b) -> (g,b,r)
        cube = os.path.join(tmpdir, "rotate.cube")
        lines = ["TITLE \"rotate\"", "LUT_3D_SIZE 2"]
        for b in (0, 1):
            for g in (0, 1):
                for r in (0, 1):
                    lines.append(f"{g:.1f} {b:.1f} {r:.1f}")
        with open(cube, "w", encoding="utf-8") as fh:
            fh.write("\n".join(lines) + "\n")
        set_filter(cl, saturation=0.0, lut_path=cube.replace("\\", "/"), lut_strength=1.0)
        time.sleep(0.8)
        p = px(screenshot(cl), 16, 9)
        check("cube LUT rotates channels", close(p, (G, B, R), 4), f"{p} expected {(G, B, R)}")

        set_filter(cl, lut_strength=0.5)
        p = px(screenshot(cl), 16, 9)
        mid = tuple(round((a + b) / 2) for a, b in zip((R, G, B), (G, B, R)))
        check("LUT strength 0.5 blends", close(p, mid, 4), f"{p} expected ~{mid}")

        # same LUT from a folder with a non-ASCII name (UTF-8 path handling on Windows)
        udir = os.path.join(tmpdir, "lüt-ordner")
        os.makedirs(udir, exist_ok=True)
        ucube = os.path.join(udir, "rotäte.cube")
        with open(cube, "rb") as src, open(ucube, "wb") as dst:
            dst.write(src.read())
        set_filter(cl, lut_path=ucube.replace("\\", "/"), lut_strength=1.0)
        time.sleep(0.8)
        p = px(screenshot(cl), 16, 9)
        check("cube LUT from non-ASCII path", close(p, (G, B, R), 4), f"{p} expected {(G, B, R)}")

        set_filter(cl, lut_path="", lut_strength=1.0)
        p = px(screenshot(cl), 16, 9)
        check("clearing LUT restores image", close(p, base), f"{p}")

        set_filter(cl, vignette_amount=1.0, vignette_radius=0.3, vignette_feather=0.1)
        img = screenshot(cl)
        c, corner = px(img, 16, 9), px(img, 1, 1)
        check("vignette darkens corners only", close(c, base, 4) and sum(corner[:3]) < 40 and corner[3] == 255, f"center {c} corner {corner}")

        set_filter(cl, vignette_amount=0.0, enable_mask=True, mask_x=0.25, mask_y=0.5, mask_width=0.2, mask_height=0.6, mask_shape=0.0, mask_feather=0.0, exposure=-1.0)
        img = screenshot(cl)
        left, right = px(img, 8, 9), px(img, 26, 9)
        check("mask limits effect to region", close(left, tuple(v // 2 for v in (R, G, B)), 4) and close(right, base, 4), f"left {left} right {right}")

        set_filter(cl, enable_mask=False, exposure=0.0, grain_amount=1.0, grain_size=1.0)
        a = screenshot(cl, 64, 36)
        time.sleep(0.3)
        b = screenshot(cl, 64, 36)
        diff = sum(abs(pa - pb) for pa, pb in zip(a.tobytes(), b.tobytes()))
        check("grain is animated", diff > 0, f"frame diff {diff}")

        set_filter(cl, grain_amount=0.0, bloom=1.0, halation=1.0, sharpen=1.0)
        p = px(screenshot(cl), 16, 9)
        check("bloom/halation/sharpen render without error", all(0 <= v <= 255 for v in p), f"{p}")
    finally:
        if created_input:
            try:
                cl.remove_input(INPUT)
            except Exception as exc:  # noqa: BLE001
                print("cleanup: remove_input failed:", exc)
        if created_scene:
            try:
                cl.remove_scene(SCENE)
            except Exception as exc:  # noqa: BLE001
                print("cleanup: remove_scene failed:", exc)
        time.sleep(0.3)
        scenes = [s["sceneName"] for s in cl.get_scene_list().scenes]
        inputs = [i["inputName"] for i in cl.get_input_list().inputs]
        check("temporary scene removed", SCENE not in scenes)
        check("temporary input removed", INPUT not in inputs)

    failed = [r for r in results if not r[1]]
    print(f"\n{len(results) - len(failed)} passed, {len(failed)} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
