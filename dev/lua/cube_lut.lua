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
