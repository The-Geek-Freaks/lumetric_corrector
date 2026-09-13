"""Independent verifier for PNGs produced by test_png_encoder.lua.

Usage:
    uv run --with pillow python dev/tests/verify_png.py

For every case listed in dev/tests/out/manifest.txt this:
  (a) opens the PNG with Pillow and checks reported size (mode is also
      reported, but not asserted for 16-bit since Pillow downsamples RGBA;16
      to 8 bit on load - it is not a channel-exact proof for that case).
  (b) runs an independent manual decoder (struct + zlib only) that:
        - verifies the PNG signature
        - walks every chunk, recomputing the CRC-32 in a completely separate
          implementation (zlib.crc32) and comparing to the stored CRC
        - parses and validates the IHDR fields
        - concatenates the IDAT chunk(s) and zlib.decompress()s them
          (this also verifies the Adler-32 trailer, since zlib.decompress
          raises on a checksum mismatch)
        - checks every scanline's filter byte is 0
        - reassembles the raw pixel bytes and compares them BYTE-FOR-BYTE
          against the *_raw.bin dump written by the Lua side
"""
import os
import struct
import sys
import zlib

try:
    from PIL import Image
except ImportError:  # pragma: no cover
    Image = None

HERE = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(HERE, "out")

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"

failures = 0
total = 0


def check(cond, msg):
    global failures, total
    total += 1
    if cond:
        print(f"PASS: {msg}")
    else:
        failures += 1
        print(f"FAIL: {msg}")


def parse_chunks(data: bytes):
    assert data[:8] == PNG_SIGNATURE, "bad PNG signature"
    offset = 8
    chunks = []
    n = len(data)
    while offset < n:
        (length,) = struct.unpack(">I", data[offset:offset + 4])
        ctype = data[offset + 4:offset + 8]
        cdata = data[offset + 8:offset + 8 + length]
        crc_stored = struct.unpack(">I", data[offset + 8 + length:offset + 12 + length])[0]
        crc_computed = zlib.crc32(ctype + cdata) & 0xFFFFFFFF
        if crc_computed != crc_stored:
            raise AssertionError(
                f"CRC mismatch in chunk {ctype!r} at offset {offset}: "
                f"stored={crc_stored:#010x} computed={crc_computed:#010x}"
            )
        chunks.append((ctype, cdata))
        offset += 12 + length
    return chunks


def manual_decode(png_path: str, width: int, height: int, bitdepth: int) -> bytes:
    with open(png_path, "rb") as fh:
        data = fh.read()

    chunks = parse_chunks(data)
    assert chunks, "no chunks found"
    assert chunks[0][0] == b"IHDR", "first chunk is not IHDR"
    assert chunks[-1][0] == b"IEND", "last chunk is not IEND"
    assert chunks[-1][1] == b"", "IEND chunk is not empty"

    ihdr = chunks[0][1]
    (w, h, bd, colortype, compression, filt, interlace) = struct.unpack(">IIBBBBB", ihdr)
    assert w == width, f"IHDR width {w} != expected {width}"
    assert h == height, f"IHDR height {h} != expected {height}"
    assert bd == bitdepth, f"IHDR bitdepth {bd} != expected {bitdepth}"
    assert colortype == 6, f"IHDR colour type {colortype} != 6 (RGBA)"
    assert compression == 0, f"IHDR compression {compression} != 0"
    assert filt == 0, f"IHDR filter method {filt} != 0"
    assert interlace == 0, f"IHDR interlace {interlace} != 0"

    idat_concat = b"".join(cdata for ctype, cdata in chunks if ctype == b"IDAT")
    assert idat_concat, "no IDAT chunks found"

    # zlib.decompress verifies the Adler-32 trailer itself (raises on mismatch)
    raw = zlib.decompress(idat_concat)

    bytes_per_pixel = 4 * (bitdepth // 8)
    row_stride = width * bytes_per_pixel
    expected_total = height * (1 + row_stride)
    assert len(raw) == expected_total, (
        f"decompressed size {len(raw)} != expected {expected_total}"
    )

    pixel_rows = []
    pos = 0
    for y in range(height):
        filter_byte = raw[pos]
        assert filter_byte == 0, f"row {y} has filter byte {filter_byte}, expected 0 (None)"
        pos += 1
        pixel_rows.append(raw[pos:pos + row_stride])
        pos += row_stride
    assert pos == len(raw)

    return b"".join(pixel_rows)


def verify_case(name: str, width: int, height: int, bitdepth: int):
    png_path = os.path.join(OUT_DIR, f"{name}.png")
    raw_path = os.path.join(OUT_DIR, f"{name}_raw.bin")

    print(f"\n--- {name}: {width}x{height} @ {bitdepth}-bit ---")

    # (a) Pillow sanity check
    if Image is not None:
        with Image.open(png_path) as im:
            im.load()
            check(im.size == (width, height), f"{name}: Pillow reports size {im.size} == {(width, height)}")
            print(f"    Pillow mode: {im.mode}")
    else:
        print("    (Pillow not available, skipping (a))")

    # (b) independent manual decode, byte-exact proof
    try:
        decoded = manual_decode(png_path, width, height, bitdepth)
        manual_ok = True
    except Exception as exc:  # noqa: BLE001
        manual_ok = False
        print(f"    manual decode error: {exc}")
    check(manual_ok, f"{name}: manual struct+zlib decode succeeds and validates IHDR/CRCs/Adler32")

    if manual_ok:
        with open(raw_path, "rb") as fh:
            expected_raw = fh.read()
        check(
            decoded == expected_raw,
            f"{name}: decoded pixel bytes match {os.path.basename(raw_path)} exactly "
            f"({len(decoded)} bytes)",
        )


def main() -> int:
    manifest_path = os.path.join(OUT_DIR, "manifest.txt")
    if not os.path.exists(manifest_path):
        print(f"manifest not found at {manifest_path}; run the Lua test first")
        return 1

    with open(manifest_path, encoding="utf-8") as fh:
        lines = [ln.strip() for ln in fh if ln.strip()]

    if not lines:
        print("manifest is empty")
        return 1

    for line in lines:
        name, w, h, bd = line.split()
        verify_case(name, int(w), int(h), int(bd))

    print(f"\n{total - failures}/{total} Python-side checks passed")
    if failures:
        print(f"{failures} Python-side check(s) FAILED")
        return 1
    print("ALL PYTHON-SIDE CHECKS PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
