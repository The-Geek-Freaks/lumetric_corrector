"""Generate the Lumetric Corrector icon set and patch the banners.

The icon is an original design (clapperboard + colour chips + wordmark) without
any OBS Project assets, as required by the OBS Forum Resource and IP Policy.

    uv run --with pillow python dev/make_icon.py

Outputs: icon/LumetricCorrector-{1024,512,192,96}x*.png, icon/LumetricCorrector.ico,
icon/LumetricCorrector.svg, docs/lumetric_icon_128x128.png, and the icon tile inside
icon/banner.png and docs/banner.png is replaced in place.
"""
import base64
import io
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT_BOLD = r"C:\Windows\Fonts\Montserrat-ExtraBold.ttf"
FONT_ALT = r"C:\Windows\Fonts\arialbd.ttf"

BG = (30, 31, 34, 255)
CHIPS = [
    ["#ff3b30", "#ff9500", "#ffcc00", "#34c759"],
    ["#ff2d55", "#ff6b3d", "#ffd60a", "#30d158"],
    ["#af52de", "#5e5ce6", "#0a84ff", "#5ac8fa"],
]


def font(size: int) -> ImageFont.FreeTypeFont:
    for path in (FONT_BOLD, FONT_ALT):
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def draw_icon(size: int = 1024, radius_ratio: float = 0.22) -> Image.Image:
    s = size
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    r = int(s * radius_ratio)
    d.rounded_rectangle((0, 0, s - 1, s - 1), radius=r, fill=BG)

    # clapperboard body (colour chips) -------------------------------------
    bx0, by0, bx1, by1 = int(s * 0.19), int(s * 0.33), int(s * 0.81), int(s * 0.64)
    d.rounded_rectangle((bx0, by0, bx1, by1), radius=int(s * 0.03), fill=(20, 20, 22, 255))
    pad = int(s * 0.018)
    cols, rows = 4, 3
    cw = (bx1 - bx0 - pad * (cols + 1)) / cols
    ch = (by1 - by0 - pad * (rows + 1)) / rows
    for j, row in enumerate(CHIPS):
        for i, hexcol in enumerate(row):
            x = bx0 + pad + i * (cw + pad)
            y = by0 + pad + j * (ch + pad)
            d.rounded_rectangle((x, y, x + cw, y + ch), radius=int(s * 0.012), fill=hexcol)

    # clapper stick, slightly open, with diagonal stripes -------------------
    stick = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    sd = ImageDraw.Draw(stick)
    sw, sh = bx1 - bx0, int(s * 0.085)
    stick_img = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    sdd = ImageDraw.Draw(stick_img)
    sdd.rounded_rectangle((0, 0, sw - 1, sh - 1), radius=int(s * 0.02), fill=(236, 236, 240, 255))
    stripe = int(sw / 9)
    for k in range(0, sw + sh, stripe * 2):
        sdd.polygon([(k, 0), (k + stripe, 0), (k + stripe - sh, sh), (k - sh, sh)], fill=(30, 31, 34, 255))
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw - 1, sh - 1), radius=int(s * 0.02), fill=255)
    stick_img.putalpha(mask)
    stick_img = stick_img.rotate(9, resample=Image.BICUBIC, expand=True)
    stick.paste(stick_img, (bx0 - int(s * 0.01), by0 - sh - int(s * 0.035)), stick_img)
    img.alpha_composite(stick)

    # wordmark ------------------------------------------------------------------
    d = ImageDraw.Draw(img)
    f1 = font(int(s * 0.118))
    f2 = font(int(s * 0.098))
    for text, f, y in (("LUMETRIC", f1, int(s * 0.685)), ("CORRECTOR", f2, int(s * 0.815))):
        w = d.textlength(text, font=f)
        d.text(((s - w) / 2, y), text, font=f, fill=(245, 245, 247, 255))
    return img


def patch_banner(path: str, icon: Image.Image) -> None:
    banner = Image.open(path).convert("RGBA")
    w, h = banner.size
    # find the old icon tile: its background is a very uniform dark grey (~32,33,35)
    # that does not occur in the starfield around it
    px = banner.load()
    col_hits = [0] * w
    row_hits = [0] * h
    for y in range(int(h * 0.1), int(h * 0.95)):
        for x in range(int(w * 0.05), int(w * 0.35)):
            r, g, b, _ = px[x, y]
            if abs(r - 32) <= 5 and abs(g - 33) <= 5 and abs(b - 35) <= 5:
                col_hits[x] += 1
                row_hits[y] += 1
    # keep only densely matching rows/columns (ignores stray grey pixels in the starfield)
    xs = [x for x, n in enumerate(col_hits) if n >= 0.3 * max(col_hits)]
    ys = [y for y, n in enumerate(row_hits) if n >= 0.3 * max(row_hits)]
    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
    side = max(x1 - x0, y1 - y0) + 1
    tile = icon.resize((side, side), Image.LANCZOS)
    banner.alpha_composite(tile, (x0, y0))
    banner.save(path, optimize=True)
    print(f"patched {os.path.relpath(path, ROOT)}: tile at ({x0},{y0}) size {side}")


def main() -> None:
    master = draw_icon(1024)
    icon_dir = os.path.join(ROOT, "icon")
    for size in (1024, 512, 192, 96):
        out = master.resize((size, size), Image.LANCZOS)
        out.save(os.path.join(icon_dir, f"LumetricCorrector-{size}x{size}.png"), optimize=True)
    master.resize((128, 128), Image.LANCZOS).save(os.path.join(ROOT, "docs", "lumetric_icon_128x128.png"), optimize=True)
    master.save(os.path.join(icon_dir, "LumetricCorrector.ico"), sizes=[(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)])
    buf = io.BytesIO()
    master.save(buf, format="PNG", optimize=True)
    b64 = base64.b64encode(buf.getvalue()).decode("ascii")
    with open(os.path.join(icon_dir, "LumetricCorrector.svg"), "w", encoding="utf-8") as fh:
        fh.write('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1024" height="1024" viewBox="0 0 1024 1024">'
                 f'<image width="1024" height="1024" xlink:href="data:image/png;base64,{b64}"/></svg>')
    for banner in (os.path.join(icon_dir, "banner.png"), os.path.join(ROOT, "docs", "banner.png")):
        patch_banner(banner, master)
    print("icons written")


if __name__ == "__main__":
    main()
