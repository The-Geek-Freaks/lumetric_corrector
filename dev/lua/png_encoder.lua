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
