--[[
  Test suite for png_encoder.lua.

  Run:
    uv run --with lupa python dev/run_lua.py dev/tests/test_png_encoder.lua

  Writes PNGs + raw scanline dumps + a manifest under dev/tests/out/, then
  hand off to dev/tests/verify_png.py (Pillow + an independent manual zlib
  decoder) for the actual byte-exact proof.
]]

local png = require("png_encoder")

local OUT_DIR = "dev/tests/out"

local failures = 0
local total = 0

local function check(cond, msg)
  total = total + 1
  if cond then
    print("PASS: " .. msg)
  else
    failures = failures + 1
    print("FAIL: " .. msg)
  end
end

--------------------------------------------------------------------------
-- 1. Known checksum vectors
--------------------------------------------------------------------------

check(png.crc32("") == 0, "crc32('') == 0")
check(png.crc32("123456789") == 0xCBF43926, "crc32('123456789') == 0xCBF43926")
check(png.adler32("Wikipedia") == 0x11E60398, "adler32('Wikipedia') == 0x11E60398")

--------------------------------------------------------------------------
-- Deterministic PRNG (LCG, Numerical-Recipes constants, exact in doubles:
-- state < 2^32 and multiplier chosen so state*a stays < 2^53).
--------------------------------------------------------------------------

local function make_rng(seed)
  local state = seed % 4294967296
  return function()
    state = (state * 1664525 + 1013904223) % 4294967296
    return state
  end
end

local function next_byte(rng)
  return math.floor(rng() / 16777216) -- top 8 bits of the 32-bit state
end

local function next_u16(rng)
  return math.floor(rng() / 65536) -- top 16 bits of the 32-bit state
end

local function chars(values)
  local t = {}
  for i = 1, #values do t[i] = string.char(values[i]) end
  return table.concat(t)
end

--- Build `height` scanlines of `width`x4 8-bit samples using `rng`.
local function make_rows_8(width, height, rng)
  local rows = {}
  for y = 1, height do
    local vals = {}
    for i = 1, width * 4 do vals[i] = next_byte(rng) end
    rows[y] = chars(vals)
  end
  return rows
end

--- Build `height` scanlines of `width`x4 16-bit (big-endian) samples.
local function make_rows_16(width, height, rng)
  local rows = {}
  for y = 1, height do
    local vals = {}
    local vi = 0
    for i = 1, width * 4 do
      local v = next_u16(rng)
      vi = vi + 1; vals[vi] = math.floor(v / 256)
      vi = vi + 1; vals[vi] = v % 256
    end
    rows[y] = chars(vals)
  end
  return rows
end

local function write_file(path, data)
  local f, err = io.open(path, "wb")
  if not f then error("could not open " .. path .. " for writing: " .. tostring(err)) end
  f:write(data)
  f:close()
end

--------------------------------------------------------------------------
-- Manifest: one line per test case, consumed by verify_png.py
--------------------------------------------------------------------------

local manifest = {}
local function add_case(name, width, height, bitdepth)
  manifest[#manifest + 1] = string.format("%s %d %d %d", name, width, height, bitdepth)
end

--------------------------------------------------------------------------
-- 2. Deterministic 8-bit image (37x11)
--------------------------------------------------------------------------

do
  local width, height, bitdepth = 37, 11, 8
  local rng = make_rng(12345)
  local rows = make_rows_8(width, height, rng)
  local raw = table.concat(rows)

  local ok, png_bytes = pcall(png.encode_rgba, width, height, rows, bitdepth)
  check(ok, "encode_rgba succeeds for 8-bit " .. width .. "x" .. height)
  if ok then
    write_file(OUT_DIR .. "/test8.png", png_bytes)
    write_file(OUT_DIR .. "/test8_raw.bin", raw)
    add_case("test8", width, height, bitdepth)
    check(#png_bytes > 8 + 25 + 12, "8-bit PNG has plausible size (" .. #png_bytes .. " bytes)")
  end
end

--------------------------------------------------------------------------
-- 3. Deterministic 16-bit image (21x9)
--------------------------------------------------------------------------

do
  local width, height, bitdepth = 21, 9, 16
  local rng = make_rng(987654321)
  local rows = make_rows_16(width, height, rng)
  local raw = table.concat(rows)

  local ok, png_bytes = pcall(png.encode_rgba, width, height, rows, bitdepth)
  check(ok, "encode_rgba succeeds for 16-bit " .. width .. "x" .. height)
  if ok then
    write_file(OUT_DIR .. "/test16.png", png_bytes)
    write_file(OUT_DIR .. "/test16_raw.bin", raw)
    add_case("test16", width, height, bitdepth)
    check(#png_bytes > 8 + 25 + 12, "16-bit PNG has plausible size (" .. #png_bytes .. " bytes)")
  end
end

--------------------------------------------------------------------------
-- 4. Validation errors
--------------------------------------------------------------------------

do
  local ok = pcall(png.encode_rgba, 4, 2, { "x" }, 8)
  check(not ok, "encode_rgba rejects rows array with wrong length")
end

do
  local bad_rows = { string.rep("\0", 4 * 4), string.rep("\0", 4 * 4 - 1) }
  local ok = pcall(png.encode_rgba, 4, 2, bad_rows, 8)
  check(not ok, "encode_rgba rejects a scanline with wrong byte length")
end

do
  local rows = { string.rep("\0", 4 * 4) }
  local ok = pcall(png.encode_rgba, 4, 1, rows, 12)
  check(not ok, "encode_rgba rejects an unsupported bit depth")
end

do
  local rows = { string.rep("\0", 4 * 4) }
  check(not pcall(png.encode_rgba, 0, 1, rows, 8), "encode_rgba rejects width=0")
  check(not pcall(png.encode_rgba, -5, 1, rows, 8), "encode_rgba rejects negative width")
  check(not pcall(png.encode_rgba, 2.5, 1, rows, 8), "encode_rgba rejects non-integer width")
  check(not pcall(png.encode_rgba, nil, 1, rows, 8), "encode_rgba rejects nil width")
  check(not pcall(png.encode_rgba, "4", 1, rows, 8), "encode_rgba rejects non-numeric width")
  check(not pcall(png.encode_rgba, 4, 0, rows, 8), "encode_rgba rejects height=0")
  check(not pcall(png.encode_rgba, 4, -3, rows, 8), "encode_rgba rejects negative height")
  check(not pcall(png.encode_rgba, 4, 1.5, rows, 8), "encode_rgba rejects non-integer height")
  check(not pcall(png.encode_rgba, 4, nil, rows, 8), "encode_rgba rejects nil height")
  check(not pcall(png.encode_rgba, 4, 1, "not a table", 8), "encode_rgba rejects non-table rows")
end

--------------------------------------------------------------------------
-- 5. Performance case: 4225x65 RGBA16 (a 65^3 LUT atlas), must finish < 3s
--------------------------------------------------------------------------

do
  local width, height, bitdepth = 4225, 65, 16
  local rng = make_rng(42)
  local rows = make_rows_16(width, height, rng)
  local raw = table.concat(rows)
  print(string.format("perf case: raw uncompressed size = %d bytes (%.2f MB)", #raw, #raw / (1024 * 1024)))

  local t0 = os.clock()
  local ok, png_bytes = pcall(png.encode_rgba, width, height, rows, bitdepth)
  local elapsed = os.clock() - t0

  check(ok, "encode_rgba succeeds for perf case " .. width .. "x" .. height)
  print(string.format("perf case: encode_rgba took %.3f s", elapsed))
  check(elapsed < 3.0, string.format("perf case finishes under 3s (took %.3fs)", elapsed))

  if ok then
    write_file(OUT_DIR .. "/perf.png", png_bytes)
    write_file(OUT_DIR .. "/perf_raw.bin", raw)
    add_case("perf", width, height, bitdepth)
    print(string.format("perf case: PNG size = %d bytes", #png_bytes))
  end
end

--------------------------------------------------------------------------
-- Write manifest for the Python verifier
--------------------------------------------------------------------------

write_file(OUT_DIR .. "/manifest.txt", table.concat(manifest, "\n") .. "\n")

--------------------------------------------------------------------------
-- Summary
--------------------------------------------------------------------------

print(string.format("\n%d/%d Lua-side checks passed", total - failures, total))
if failures > 0 then
  error(string.format("%d Lua-side check(s) FAILED", failures))
else
  print("ALL LUA-SIDE CHECKS PASSED")
end
