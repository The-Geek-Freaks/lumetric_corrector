-- test_cube_lut.lua
-- Run with:
--   uv run --with lupa python dev/run_lua.py dev/tests/test_cube_lut.lua

local cube_lut = require("cube_lut")

local pass_count, fail_count = 0, 0
local failures = {}

local function record(ok, msg)
  if ok then
    pass_count = pass_count + 1
  else
    fail_count = fail_count + 1
    failures[#failures + 1] = msg
    print("FAIL: " .. msg)
  end
end

local function assert_true(cond, msg)
  record(cond and true or false, msg or "assert_true failed")
end

local function assert_eq(a, b, msg)
  record(a == b, (msg or "assert_eq failed") .. (" (got %s, expected %s)"):format(tostring(a), tostring(b)))
end

local function assert_near(a, b, tol, msg)
  local ok = math.abs(a - b) <= tol
  record(ok, (msg or "assert_near failed") .. (" (got %s, expected %s, tol %s)"):format(tostring(a), tostring(b), tostring(tol)))
end

local function assert_nil(v, msg)
  record(v == nil, msg or "expected nil")
end

-- ---------------------------------------------------------------------------
-- 1. parse_cube: identity 2x2x2 with TITLE, comments, CRLF, DOMAIN, tabs, sci
-- ---------------------------------------------------------------------------

do
  local lines = {
    "# top-of-file comment",
    'TITLE "Identity 2x2x2"',
    "",
    "LUT_3D_SIZE 2",
    "DOMAIN_MIN 0.0 0.0 0.0",
    "DOMAIN_MAX 1.0e0 1.0 1.0",
    "",
    "0.0\t0.0\t0.0",
    "1.0 0.0 0.0  # first red corner",
    "0.0 1.0 0.0",
    "1.0 1.0 0.0",
    "0E+00 0.0 1.0",
    "1.0 0.0 1.0",
    "0.0 1.0 1.0",
    "1.0 1.0 1.0",
  }
  local text = table.concat(lines, "\r\n")
  local lut, err = cube_lut.parse_cube(text)
  assert_true(lut ~= nil, "identity 2^3 should parse: " .. tostring(err))
  if lut then
    assert_eq(lut.size, 2, "identity 2^3 size")
    assert_eq(lut.title, "Identity 2x2x2", "identity 2^3 title")
    assert_eq(#lut.data, 2 * 2 * 2 * 3, "identity 2^3 data length")
    assert_near(lut.domain_min[1], 0.0, 1e-12, "domain_min[1]")
    assert_near(lut.domain_max[1], 1.0, 1e-12, "domain_max[1] (scientific notation)")
    for b = 0, 1 do
      for g = 0, 1 do
        for r = 0, 1 do
          local point = r + g * 2 + b * 4
          local base = point * 3
          assert_near(lut.data[base + 1], r, 1e-12, ("2^3 r at (%d,%d,%d)"):format(r, g, b))
          assert_near(lut.data[base + 2], g, 1e-12, ("2^3 g at (%d,%d,%d)"):format(r, g, b))
          assert_near(lut.data[base + 3], b, 1e-12, ("2^3 b at (%d,%d,%d)"):format(r, g, b))
        end
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- 2. parse_cube: identity 3x3x3, generated, with TITLE/comments/CRLF/DOMAIN/
--    tabs/scientific notation
-- ---------------------------------------------------------------------------

do
  local size = 3
  local function fmt(v)
    if v == 0 then return "0e0"
    elseif v == 1 then return "1E0"
    else return string.format("%.6f", v) end
  end
  local lines = {
    "# generated identity cube",
    'TITLE "Identity 3x3x3"',
    "LUT_3D_SIZE 3",
    "DOMAIN_MIN\t0.0 0.0 0.0",
    "DOMAIN_MAX\t1.0 1.0 1.0",
  }
  for b = 0, size - 1 do
    for g = 0, size - 1 do
      for r = 0, size - 1 do
        local rv, gv, bv = r / (size - 1), g / (size - 1), b / (size - 1)
        lines[#lines + 1] = fmt(rv) .. "\t" .. fmt(gv) .. "\t" .. fmt(bv) .. "  # point"
      end
    end
  end
  local text = table.concat(lines, "\r\n")
  local lut, err = cube_lut.parse_cube(text)
  assert_true(lut ~= nil, "identity 3^3 should parse: " .. tostring(err))
  if lut then
    assert_eq(lut.size, 3, "identity 3^3 size")
    assert_eq(lut.title, "Identity 3x3x3", "identity 3^3 title")
    assert_eq(#lut.data, 3 * 3 * 3 * 3, "identity 3^3 data length")
    for b = 0, size - 1 do
      for g = 0, size - 1 do
        for r = 0, size - 1 do
          local point = r + g * size + b * size * size
          local base = point * 3
          assert_near(lut.data[base + 1], r / (size - 1), 1e-9, ("3^3 r at (%d,%d,%d)"):format(r, g, b))
          assert_near(lut.data[base + 2], g / (size - 1), 1e-9, ("3^3 g at (%d,%d,%d)"):format(r, g, b))
          assert_near(lut.data[base + 3], b / (size - 1), 1e-9, ("3^3 b at (%d,%d,%d)"):format(r, g, b))
        end
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- 3. rejections
-- ---------------------------------------------------------------------------

do
  local lut, err = cube_lut.parse_cube("LUT_1D_SIZE 2\n0.0 0.0 0.0\n1.0 1.0 1.0\n")
  assert_nil(lut, "LUT_1D_SIZE must be rejected")
  assert_true(type(err) == "string" and #err > 0, "LUT_1D_SIZE rejection has a message")
end

do
  local lut, err = cube_lut.parse_cube('TITLE "no size"\n0.0 0.0 0.0\n1.0 1.0 1.0\n')
  assert_nil(lut, "missing LUT_3D_SIZE must be rejected")
  assert_true(type(err) == "string" and #err > 0, "missing size rejection has a message")
end

do
  local lut, err = cube_lut.parse_cube("LUT_3D_SIZE 1\n0.0 0.0 0.0\n")
  assert_nil(lut, "LUT_3D_SIZE < 2 must be rejected")
  assert_true(type(err) == "string", "size<2 rejection has a message")
end

do
  local lut, err = cube_lut.parse_cube("LUT_3D_SIZE 257\n")
  assert_nil(lut, "LUT_3D_SIZE > 256 must be rejected")
  assert_true(type(err) == "string", "size>256 rejection has a message")
end

do
  -- 2^3 needs 24 numbers, supply 12
  local text = "LUT_3D_SIZE 2\n" .. string.rep("0.0 0.0 0.0\n", 4)
  local lut, err = cube_lut.parse_cube(text)
  assert_nil(lut, "too few data values must be rejected")
  assert_true(type(err) == "string" and #err > 0, "too few rejection has a message")
end

do
  -- 2^3 needs 24 numbers, supply 30
  local text = "LUT_3D_SIZE 2\n" .. string.rep("0.0 ", 30) .. "\n"
  local lut, err = cube_lut.parse_cube(text)
  assert_nil(lut, "too many data values must be rejected")
  assert_true(type(err) == "string" and #err > 0, "too many rejection has a message")
end

do
  local text = table.concat({
    "LUT_3D_SIZE 2",
    "0 0 0", "1 0 0", "0 1 0", "1 1 abc",
    "0 0 1", "1 0 1", "0 1 1", "1 1 1",
  }, "\n")
  local lut, err = cube_lut.parse_cube(text)
  assert_nil(lut, "non-numeric token must be rejected")
  assert_true(type(err) == "string" and err:find("abc") ~= nil, "non-numeric rejection message mentions the bad token")
end

-- ---------------------------------------------------------------------------
-- 4. atlas_rows: 3^3 LUT with distinct values, decode and cross-check
-- ---------------------------------------------------------------------------

do
  local n = 3
  local data = {}
  for b = 0, n - 1 do
    for g = 0, n - 1 do
      for r = 0, n - 1 do
        local point = r + g * n + b * n * n
        local base = point * 3
        data[base + 1] = (r + 1) / 4
        data[base + 2] = (g + 1) / 5
        data[base + 3] = (b + 1) / 6
      end
    end
  end
  local lut = { size = n, data = data, domain_min = { 0, 0, 0 }, domain_max = { 1, 1, 1 } }

  local rows8, w8, h8 = cube_lut.atlas_rows(lut, 8)
  assert_eq(w8, n * n, "atlas width (8-bit)")
  assert_eq(h8, n, "atlas height (8-bit)")
  assert_eq(#rows8, h8, "row count (8-bit)")

  local rows16, w16, h16 = cube_lut.atlas_rows(lut, 16)
  assert_eq(w16, n * n, "atlas width (16-bit)")
  assert_eq(h16, n, "atlas height (16-bit)")
  assert_eq(#rows16, h16, "row count (16-bit)")

  local function q8(v) return math.floor(v * 255 + 0.5) end
  local function q16(v) return math.floor(v * 65535 + 0.5) end

  for gy = 0, n - 1 do
    local row8 = rows8[gy + 1]
    local row16 = rows16[gy + 1]
    assert_eq(#row8, w8 * 4, ("row8 length at g=%d"):format(gy))
    assert_eq(#row16, w16 * 8, ("row16 length at g=%d"):format(gy))
    for x = 0, w8 - 1 do
      local bx = math.floor(x / n)
      local rx = x - bx * n
      local expect_r = (rx + 1) / 4
      local expect_g = (gy + 1) / 5
      local expect_b = (bx + 1) / 6

      local b1, b2, b3, b4 = row8:byte(x * 4 + 1, x * 4 + 4)
      assert_eq(b1, q8(expect_r), ("8-bit R at x=%d y=%d"):format(x, gy))
      assert_eq(b2, q8(expect_g), ("8-bit G at x=%d y=%d"):format(x, gy))
      assert_eq(b3, q8(expect_b), ("8-bit B at x=%d y=%d"):format(x, gy))
      assert_eq(b4, 255, ("8-bit A (max) at x=%d y=%d"):format(x, gy))

      local h1, h2, h3, h4, h5, h6, h7, h8b = row16:byte(x * 8 + 1, x * 8 + 8)
      assert_eq(h1 * 256 + h2, q16(expect_r), ("16-bit R at x=%d y=%d"):format(x, gy))
      assert_eq(h3 * 256 + h4, q16(expect_g), ("16-bit G at x=%d y=%d"):format(x, gy))
      assert_eq(h5 * 256 + h6, q16(expect_b), ("16-bit B at x=%d y=%d"):format(x, gy))
      assert_eq(h7 * 256 + h8b, 65535, ("16-bit A (max) at x=%d y=%d"):format(x, gy))
    end
  end
end

-- ---------------------------------------------------------------------------
-- 5. layout_from_dims
-- ---------------------------------------------------------------------------

do
  local cases = {
    { 1089, 33, 33, 33 },
    { 4096, 64, 64, 64 },
    { 512, 512, 64, 8 },
    { 4, 2, 2, 2 },
    { 64, 64, 16, 4 },
  }
  for _, c in ipairs(cases) do
    local size, tiles = cube_lut.layout_from_dims(c[1], c[2])
    assert_eq(size, c[3], ("layout_from_dims(%d,%d) size"):format(c[1], c[2]))
    assert_eq(tiles, c[4], ("layout_from_dims(%d,%d) tiles"):format(c[1], c[2]))
  end

  local nil_cases = { { 100, 37 }, { 0, 0 } }
  for _, c in ipairs(nil_cases) do
    local size, err = cube_lut.layout_from_dims(c[1], c[2])
    assert_nil(size, ("layout_from_dims(%d,%d) should be nil"):format(c[1], c[2]))
    assert_true(type(err) == "string", ("layout_from_dims(%d,%d) has message"):format(c[1], c[2]))
  end
end

-- ---------------------------------------------------------------------------
-- 6. sample: identity, known corners, clamping
-- ---------------------------------------------------------------------------

do
  local n = 4
  local data = {}
  for b = 0, n - 1 do
    for g = 0, n - 1 do
      for r = 0, n - 1 do
        local point = r + g * n + b * n * n
        local base = point * 3
        data[base + 1] = r / (n - 1)
        data[base + 2] = g / (n - 1)
        data[base + 3] = b / (n - 1)
      end
    end
  end
  local lut = { size = n, data = data, domain_min = { 0, 0, 0 }, domain_max = { 1, 1, 1 } }

  local fracs = { 0.0, 0.25, 0.5, 0.75, 1.0 }
  for _, r in ipairs(fracs) do
    for _, g in ipairs(fracs) do
      for _, b in ipairs(fracs) do
        local sr, sg, sb = cube_lut.sample(lut, r, g, b)
        assert_near(sr, r, 1e-9, ("identity sample r at (%.2f,%.2f,%.2f)"):format(r, g, b))
        assert_near(sg, g, 1e-9, ("identity sample g at (%.2f,%.2f,%.2f)"):format(r, g, b))
        assert_near(sb, b, 1e-9, ("identity sample b at (%.2f,%.2f,%.2f)"):format(r, g, b))
      end
    end
  end
end

do
  local corners = {
    ["0,0,0"] = { 0.0, 0.0, 0.0 },
    ["1,0,0"] = { 1.0, 0.2, 0.3 },
    ["0,1,0"] = { 0.1, 1.0, 0.4 },
    ["1,1,0"] = { 0.9, 0.8, 0.1 },
    ["0,0,1"] = { 0.2, 0.3, 1.0 },
    ["1,0,1"] = { 0.7, 0.1, 0.6 },
    ["0,1,1"] = { 0.3, 0.9, 0.7 },
    ["1,1,1"] = { 1.0, 1.0, 1.0 },
  }
  local data = {}
  for b = 0, 1 do
    for g = 0, 1 do
      for r = 0, 1 do
        local point = r + g * 2 + b * 4
        local c = corners[("%d,%d,%d"):format(r, g, b)]
        data[point * 3 + 1] = c[1]
        data[point * 3 + 2] = c[2]
        data[point * 3 + 3] = c[3]
      end
    end
  end
  local lut = { size = 2, data = data, domain_min = { 0, 0, 0 }, domain_max = { 1, 1, 1 } }

  -- exact corners
  for key, c in pairs(corners) do
    local r, g, b = key:match("(%d),(%d),(%d)")
    r, g, b = tonumber(r), tonumber(g), tonumber(b)
    local sr, sg, sb = cube_lut.sample(lut, r, g, b)
    assert_near(sr, c[1], 1e-12, ("corner r at %s"):format(key))
    assert_near(sg, c[2], 1e-12, ("corner g at %s"):format(key))
    assert_near(sb, c[3], 1e-12, ("corner b at %s"):format(key))
  end

  -- exact average at the centre
  local avg = { 0, 0, 0 }
  for _, c in pairs(corners) do
    avg[1] = avg[1] + c[1]
    avg[2] = avg[2] + c[2]
    avg[3] = avg[3] + c[3]
  end
  avg[1], avg[2], avg[3] = avg[1] / 8, avg[2] / 8, avg[3] / 8
  local sr, sg, sb = cube_lut.sample(lut, 0.5, 0.5, 0.5)
  assert_near(sr, avg[1], 1e-12, "centre average r")
  assert_near(sg, avg[2], 1e-12, "centre average g")
  assert_near(sb, avg[3], 1e-12, "centre average b")

  -- clamping outside 0..1
  local cr, cg, cb = cube_lut.sample(lut, -0.5, -0.5, -0.5)
  local zr, zg, zb = cube_lut.sample(lut, 0.0, 0.0, 0.0)
  assert_near(cr, zr, 1e-12, "clamp below 0 (r)")
  assert_near(cg, zg, 1e-12, "clamp below 0 (g)")
  assert_near(cb, zb, 1e-12, "clamp below 0 (b)")

  local hr, hg, hb = cube_lut.sample(lut, 1.5, 1.5, 1.5)
  local or_, og, ob = cube_lut.sample(lut, 1.0, 1.0, 1.0)
  assert_near(hr, or_, 1e-12, "clamp above 1 (r)")
  assert_near(hg, og, 1e-12, "clamp above 1 (g)")
  assert_near(hb, ob, 1e-12, "clamp above 1 (b)")

  local mr, mg, mb = cube_lut.sample(lut, -1.0, 2.0, 0.5)
  local xr, xg, xb = cube_lut.sample(lut, 0.0, 1.0, 0.5)
  assert_near(mr, xr, 1e-12, "mixed clamp (r)")
  assert_near(mg, xg, 1e-12, "mixed clamp (g)")
  assert_near(mb, xb, 1e-12, "mixed clamp (b)")
end

-- ---------------------------------------------------------------------------
-- 7. fnv1a: spec test vectors plus extra strings (independently verified
--    against a Python FNV-1a 32-bit reference implementation)
-- ---------------------------------------------------------------------------

do
  local cases = {
    { "", "811c9dc5" },
    { "a", "e40c292c" },
    { "foobar", "bf9cf968" },
    { "abc", "1a47e90b" },
    { "The quick brown fox jumps over the lazy dog", "048fff90" },
    { "a\0b", "10f3abd2" },
    { "\0", "050c5d1f" },
    { string.rep("x", 1000), "07d18165" },
  }
  for _, c in ipairs(cases) do
    local got = cube_lut.fnv1a(c[1])
    assert_eq(got, c[2], ("fnv1a(%q) length=%d"):format(c[1], #c[1]))
    assert_eq(#got, 8, ("fnv1a(%q) result is 8 hex chars"):format(c[1]))
  end
end

-- ---------------------------------------------------------------------------
-- 8. performance: 65^3 identity cube
-- ---------------------------------------------------------------------------

do
  local size = 65
  local lines = {}
  lines[1] = "LUT_3D_SIZE " .. size
  local idx = 1
  local inv = 1 / (size - 1)
  for b = 0, size - 1 do
    for g = 0, size - 1 do
      for r = 0, size - 1 do
        idx = idx + 1
        lines[idx] = (r * inv) .. " " .. (g * inv) .. " " .. (b * inv)
      end
    end
  end
  local text = table.concat(lines, "\n")

  local t0 = os.clock()
  local lut, err = cube_lut.parse_cube(text)
  local t_parse = os.clock() - t0
  assert_true(lut ~= nil, "65^3 cube should parse: " .. tostring(err))
  print(("[perf] parse_cube(65^3): %.3fs"):format(t_parse))
  assert_true(t_parse < 1.5, ("parse_cube(65^3) must be < 1.5s, got %.3fs"):format(t_parse))

  if lut then
    assert_eq(lut.size, size, "65^3 parsed size")
    assert_eq(#lut.data, size * size * size * 3, "65^3 parsed data length")

    local t1 = os.clock()
    local rows, w, h = cube_lut.atlas_rows(lut, 16)
    local t_atlas = os.clock() - t1
    print(("[perf] atlas_rows(65^3, 16-bit): %.3fs"):format(t_atlas))
    assert_true(t_atlas < 2.0, ("atlas_rows(65^3,16) must be < 2.0s, got %.3fs"):format(t_atlas))
    assert_eq(w, size * size, "65^3 atlas width")
    assert_eq(h, size, "65^3 atlas height")
    assert_eq(#rows, h, "65^3 atlas row count")
  end
end

-- ---------------------------------------------------------------------------
-- summary
-- ---------------------------------------------------------------------------

print(("\n%d passed, %d failed"):format(pass_count, fail_count))
if fail_count > 0 then
  error(("test_cube_lut: %d assertion(s) failed"):format(fail_count))
end
