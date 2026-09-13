-- End-to-end tests for lumetric_corrector.lua against the obslua mock.
-- Run:  uv run --with lupa python dev/run_lua.py dev/tests/test_script.lua
local mock = require("mock_obslua")

local HERE = debug.getinfo(1, "S").source:sub(2):gsub("\\", "/"):match("^(.*)/[^/]+$") or "."
local ROOT = HERE:match("^(.*)/dev/tests$") or (HERE .. "/../..")
local SCRIPT = ROOT .. "/lumetric_corrector.lua"
local OUT = HERE .. "/out"
mock.os_mkdirs(OUT)
mock.cache_root = OUT .. "/config"

local passed, failed = 0, 0
local function check(cond, msg)
    if cond then passed = passed + 1 else failed = failed + 1; print("  FAIL: " .. msg) end
end
local function section(name) print("== " .. name) end
local function near(a, b, eps) return math.abs(a - b) <= (eps or 1e-9) end

-- Skript laden -----------------------------------------------------------------
local H
_G.LUMETRIC_TEST_HOOK = function(t) H = t end
_G.obslua = mock
local chunk, err = loadfile(SCRIPT)
assert(chunk, "script does not compile: " .. tostring(err))
chunk()
assert(H, "test hook not called")
script_load(nil)
local info = mock.registered
local modules_loaded = H.png_encoder ~= nil and H.cube_lut ~= nil and H.grade_pixel ~= nil

section("registration")
check(info and info.id == "lumetric_corrector_filter", "filter id registered")
check(type(script_description()) == "string" and script_description():find(H.VERSION, 1, true), "description contains version")
check(#mock.logs_matching("registered") == 1, "registration logged once")

section("static consistency")
for _, cat in ipairs(H.PRESET_CATEGORIES) do
    for _, preset in ipairs(cat.presets) do
        for key, value in pairs(preset.v) do
            local def = H.PARAM_BY_KEY[key]
            check(def ~= nil, string.format("preset %s uses unknown key %s", preset.id, key))
            if def then
                check(value >= def.min and value <= def.max, string.format("preset %s: %s=%s outside [%s,%s]", preset.id, key, value, def.min, def.max))
                check(H.is_look_key(key), string.format("preset %s touches non-look key %s", preset.id, key))
            end
        end
        for _, lang in ipairs({ "en-US", "de-DE" }) do
            check(H.PRESET_NAMES[lang][preset.id] ~= nil, "preset name " .. lang .. " for " .. preset.id)
        end
    end
end
for _, def in ipairs(H.PARAMS) do
    for _, lang in ipairs({ "en-US", "de-DE" }) do
        check(H.L10N[lang][def.key] ~= nil, "label " .. lang .. " for " .. def.key)
        check(def.desc == nil or H.L10N[lang][def.desc] ~= nil, "tooltip " .. lang .. " for " .. def.key)
    end
    if def.shader then
        check(H.shader_code:find("uniform%s+float%s+" .. def.shader .. "%s*;") ~= nil, "uniform in shader: " .. def.shader)
    end
end
for _, vec in ipairs(H.VEC4_PARAMS) do
    check(H.shader_code:find("uniform%s+float4%s+" .. vec.shader .. "%s*;") ~= nil, "vec4 uniform in shader: " .. vec.shader)
end
for key in pairs(H.L10N["en-US"]) do
    check(H.L10N["de-DE"][key] ~= nil, "german translation for " .. key)
end
check(H.PARAM_BY_KEY.lut_strength.def == 1, "lut strength defaults to 1")

section("create / defaults / update")
mock.reset_log()
local source, data, settings = mock.create_filter()
check(data.effect == nil and mock.graphics_depth == 0, "create does not touch the graphics context")
info.video_render(data)   -- erster Render-Aufruf baut den Shader
check(data.effect ~= nil and not data.invalid, "effect created on first render")
check(#mock.logs_matching("shader parameter missing") == 0, "all shader parameters found")
check(#mock.logs_matching("shader ready") == 1, "shader creation logged once")
check(settings.refs == 2, "settings retained once (refs=2)")
mock.calls.filter_end = 0
for _, def in ipairs(H.PARAMS) do
    check(near(data.v[def.key], def.def), "value default for " .. def.key)
end
check(data.v.enable_mask == false and data.v.mask_shape == 1.0, "mask defaults")

section("size callbacks")
check(type(info.get_width) == "function" and type(info.get_height) == "function", "get_width/get_height defined (OBS reports 0 otherwise)")
check(info.get_width(data) == 1920 and info.get_height(data) == 1080, "size callbacks return the target size")
check(info.get_width(nil) == 0 and info.get_height({}) == 0, "size callbacks are nil-safe")

section("render")
info.video_tick(data, 0.016)
info.video_render(data)
check(mock.calls.filter_end == 1, "filter pass completed")
local eff = data.effect
check(near(eff.values.buffer_size[1], 1920) and near(eff.values.buffer_size[3], 1 / 1920), "buffer_size uploaded")
check(near(eff.values.exposure, 0), "exposure uploaded")
check(eff.values.split_shadow ~= nil and #eff.values.split_shadow == 4, "split vec4 uploaded")
check(near(eff.values.lut_strength, 0), "lut strength forced to 0 without LUT")
local sets_before = eff.params.exposure.sets
local grain_sets = eff.params.grain_time.sets
check(grain_sets ~= nil, "grain_time initialised even while grain is 0 (D3D11 rejects draws with unset parameters)")
for name, param in pairs(eff.params) do
    if name ~= "ViewProj" and name ~= "image" and name ~= "lut_tex" then
        check(eff.values[name] ~= nil, "parameter initialised after first render: " .. name)
    end
end
info.video_render(data)
check(eff.params.exposure.sets == sets_before and eff.params.grain_time.sets == grain_sets, "no re-upload when not dirty")
settings.values.grain_amount = 0.3
mock.obs_source_update(source, nil)
info.video_render(data)
check(eff.params.grain_time.sets > grain_sets and eff.params.exposure.sets == sets_before + 1, "dirty re-upload + grain time")
local grain_sets2 = eff.params.grain_time.sets
info.video_render(data)
check(eff.params.grain_time.sets == grain_sets2 + 1, "grain time updates every frame while grain is on")
-- Zielgröße ändert sich
source.target = { w = 3840, h = 2160 }
info.video_render(data)
check(near(eff.values.buffer_size[2], 2160), "buffer_size follows target size")
-- ungültige Zustände
local skips = mock.calls.skip
source.target = nil
info.video_render(data)
check(mock.calls.skip == skips + 1, "no target -> skip")
source.target = { w = 0, h = 0 }
info.video_render(data)
check(mock.calls.skip == skips + 2, "zero size -> skip")
source.target = { w = 1280, h = 720 }
info.video_render(nil)
check(mock.calls.skip == skips + 2, "nil data does not call skip")

section("legacy cleanup")
local _, data2, settings2 = mock.create_filter({ dirty = true, last_exposure = 0.3, width = 1920, shadows_red = 0.2, exposure = 0.4 })
check(settings2.values.dirty == nil and settings2.values.last_exposure == nil and settings2.values.width == nil, "junk keys erased")
check(settings2.values.shadows_red == nil, "legacy split keys erased")
check(near(settings2.values.exposure, 0.4) and near(data2.v.exposure, 0.4), "real values kept")
info.destroy(data2)
check(settings2.refs == 1, "settings released on destroy")

section("properties")
for _, lang in ipairs({ "en-US", "de-DE" }) do
    mock.locale = lang
    local props = info.get_properties(data)
    local sliders, groups = {}, {}
    local function walk(p, group_key)
        for _, item in ipairs(p.items) do
            if item.kind == "float_slider" then
                sliders[item.key] = item
                check(item.label ~= item.key, lang .. ": slider label translated for " .. item.key)
                check(item.tooltip ~= nil and item.tooltip ~= "" and not item.tooltip:find("_desc"), lang .. ": tooltip for " .. item.key)
                local def = H.PARAM_BY_KEY[item.key]
                check(def and near(item.min, def.min) and near(item.max, def.max), lang .. ": slider range matches PARAMS for " .. item.key)
            elseif item.kind == "group" then
                groups[item.key] = item
                check(item.label ~= item.key and not item.label:find("_group"), lang .. ": group label translated for " .. item.key)
                walk(item.group, item.key)
            elseif item.kind == "button" or item.kind == "path" or item.kind == "list" then
                check(item.label ~= item.key, lang .. ": label translated for " .. item.key)
            end
        end
    end
    walk(props)
    for _, def in ipairs(H.PARAMS) do
        check(sliders[def.key] ~= nil, lang .. ": slider present for " .. def.key)
    end
    local mask_group = groups["enable_mask"]
    check(mask_group ~= nil and mask_group.gtype == mock.OBS_GROUP_CHECKABLE, lang .. ": mask is a checkable group keyed enable_mask")
    local preset_list = mock.obs_properties_get(props, "preset_select")
    check(preset_list ~= nil, lang .. ": preset list exists")
    if preset_list then
        local seen, disabled = 0, 0
        for _, e in ipairs(preset_list.entries) do
            if e.disabled then disabled = disabled + 1 elseif H.PRESET_BY_ID[e.value] then seen = seen + 1 end
            if e.value:find("^separator_") then check(e.disabled, lang .. ": separator disabled: " .. e.value) end
        end
        local total = 0
        for _ in pairs(H.PRESET_BY_ID) do total = total + 1 end
        check(seen == total, lang .. ": all presets listed (" .. seen .. "/" .. total .. ")")
        check(disabled == #H.PRESET_CATEGORIES, lang .. ": one disabled header per category")
    end
    check(mock.obs_properties_get(props, "lut_export_path") ~= nil and mock.obs_properties_get(props, "export_lut_button") ~= nil, lang .. ": LUT export controls present")
    check(mock.obs_properties_get(props, "info_text") ~= nil, lang .. ": info text present")
end
mock.locale = "en-US"

section("presets via modified callback")
local props = info.get_properties(data)
local preset_list = mock.obs_properties_get(props, "preset_select")
settings.values.mask_x = 0.3
settings.values.lut_strength = 0.4
settings.values.preset_select = "teal_orange"
local refresh = preset_list.modified(props, preset_list, settings)
check(refresh == true, "preset callback requests refresh")
check(near(settings.values.sh_r, 0.25) and near(settings.values.ss_b, 0.25), "split toning keys written by preset")
check(near(data.v.sh_r, 0.25) and near(data.v.contrast, 0.2), "filter state updated immediately")
check(near(settings.values.mask_x, 0.3) and near(settings.values.lut_strength, 0.4), "mask and LUT untouched by preset")
check(near(settings.values.grain_amount, 0), "previous grain reset by preset")
settings.values.preset_select = "separator_cat_style"
check(preset_list.modified(props, preset_list, settings) == false, "separator selection ignored")
check(near(data.v.sh_r, 0.25), "separator does not reset values")
-- Reset-Button
local reset_btn = mock.obs_properties_get(props, "reset_button")
check(reset_btn.callback() == true, "reset button refreshes")
check(near(data.v.sh_r, 0) and near(data.v.contrast, 0) and settings.values.enable_mask == false, "reset restores defaults")
check(near(data.v.mask_x, 0.5) and near(data.v.lut_strength, 1), "reset also restores mask and LUT strength")
-- Apply-Button ohne Auswahl
settings.values.preset_select = ""
local apply_btn = mock.obs_properties_get(props, "apply_preset_button")
check(apply_btn.callback() == false, "apply without preset does nothing")
-- Properties ohne Instanz dürfen nicht abstürzen
local ok_nil = pcall(info.get_properties, nil)
check(ok_nil, "get_properties(nil) works")

if not modules_loaded then
    print("!! modules not inlined yet, skipping LUT / export tests")
else
    section("LUT: cube -> atlas -> texture")
    local fixture = OUT .. "/identity3.cube"
    do
        local lines = { "TITLE \"identity\"", "LUT_3D_SIZE 3", "" }
        for b = 0, 2 do for g = 0, 2 do for r = 0, 2 do lines[#lines + 1] = string.format("%.4f %.4f %.4f", r / 2, g / 2, b / 2) end end end
        local fh = assert(io.open(fixture, "wb")); fh:write(table.concat(lines, "\n")); fh:close()
    end
    mock.reset_log()
    settings.values.lut_path = fixture
    mock.obs_source_update(source, nil)
    check(data.lut == nil and data.lut_pending ~= nil and mock.graphics_depth == 0, "update only prepares the LUT (no graphics call)")
    check(data.lut_status:find("prepared") ~= nil, "status after prepare")
    info.video_render(data)
    check(data.lut ~= nil and data.lut_pending == nil, "cube LUT loaded on render")
    if data.lut then
        check(data.lut.size == 3 and data.lut.tiles == 3 and data.lut.w == 9 and data.lut.h == 3, "atlas dimensions 9x3")
        check(data.lut.bits == 16, "16-bit atlas used")
        check(data.lut.tex.bits == 16, "png header says 16 bit")
        info.video_render(data)
        check(near(eff.values.lut_info[1], 3) and near(eff.values.lut_info[2], 3) and near(eff.values.lut_info[3], 1 / 9), "lut_info uploaded")
        check(eff.values.lut_tex == data.lut.tex, "lut texture bound")
        check(near(eff.values.lut_strength, 1), "lut strength uploaded")
    end
    check(#mock.logs_matching("LUT loaded") == 1, "load logged")
    local created = mock.textures_created
    settings.values.lut_path = fixture   -- unverändert
    mock.obs_source_update(source, nil)
    info.video_render(data)
    check(mock.textures_created == created, "unchanged path does not reload")
    -- zweites Laden nutzt den Cache (keine neue PNG-Erzeugung nötig, aber neue Textur)
    settings.values.lut_path = ""
    mock.obs_source_update(source, nil)
    info.video_render(data)
    check(data.lut == nil and mock.textures_destroyed == 1, "LUT released when path cleared")
    settings.values.lut_path = fixture
    mock.obs_source_update(source, nil)
    info.video_render(data)
    check(data.lut ~= nil and mock.textures_created == created + 1, "reload from cache")
    local range_lut = H.cube_lut.parse_cube("LUT_3D_SIZE 2\nLUT_3D_INPUT_RANGE 0.0 2.0\n0 0 0\n2 0 0\n0 2 0\n2 2 0\n0 0 2\n2 0 2\n0 2 2\n2 2 2\n")
    check(range_lut and range_lut.domain_max[1] == 2 and range_lut.domain_min[1] == 0, "LUT_3D_INPUT_RANGE parsed as domain")

    section("LUT: png layouts and errors")
    local strip = OUT .. "/strip4x2.png"
    do
        local rows = {}
        for y = 0, 1 do
            local row = {}
            for x = 0, 3 do row[#row + 1] = string.char(x * 60, y * 120, (math.floor(x / 2)) * 200, 255) end
            rows[#rows + 1] = table.concat(row)
        end
        local fh = assert(io.open(strip, "wb")); fh:write(H.png_encoder.encode_rgba(4, 2, rows, 8)); fh:close()
    end
    settings.values.lut_path = strip
    mock.obs_source_update(source, nil)
    info.video_render(data)
    check(data.lut and data.lut.size == 2 and data.lut.tiles == 2, "strip png layout detected")
    local odd = OUT .. "/odd5x3.png"
    do
        local rows = {}
        for y = 1, 3 do rows[y] = string.rep(string.char(1, 2, 3, 255), 5) end
        local fh = assert(io.open(odd, "wb")); fh:write(H.png_encoder.encode_rgba(5, 3, rows, 8)); fh:close()
    end
    mock.reset_log()
    settings.values.lut_path = odd
    mock.obs_source_update(source, nil)
    info.video_render(data)
    check(data.lut == nil and #mock.logs_matching("unsupported PNG layout") == 1, "png with unknown layout rejected")
    mock.reset_log()
    settings.values.lut_path = OUT .. "/missing.cube"
    mock.obs_source_update(source, nil)
    info.video_render(data)
    check(data.lut == nil and #mock.logs_matching("LUT load failed", mock.LOG_ERROR) == 1, "missing file reported")
    settings.values.lut_path = OUT .. "/bad.txt"
    mock.obs_source_update(source, nil)
    check(#mock.logs_matching("unsupported file type") == 1, "unsupported extension reported")
    local bad_cube = OUT .. "/bad.cube"
    do local fh = assert(io.open(bad_cube, "wb")); fh:write("LUT_1D_SIZE 4\n0 0 0\n1 1 1\n"); fh:close() end
    settings.values.lut_path = bad_cube
    mock.obs_source_update(source, nil)
    check(data.lut == nil and data.lut_status:find("error") and data.lut_error == true, "1D cube rejected with status + error flag")
    do
        local props_err = info.get_properties(data)
        local st = mock.obs_properties_get(props_err, "lut_status_text")
        check(st and st.info_type == mock.OBS_TEXT_INFO_WARNING, "status line shown as warning after failed load")
    end
    settings.values.lut_path = fixture
    mock.obs_source_update(source, nil)
    info.video_render(data)
    check(data.lut ~= nil and data.lut_error == false, "error flag cleared by a successful load")
    settings.values.lut_path = bad_cube
    mock.obs_source_update(source, nil)
    info.video_render(data)
    check(near(eff.values.lut_strength, 0), "lut strength forced to 0 after failed load")

    section("LUT export")
    settings.values.lut_path = ""
    H.reset_settings(settings)
    mock.obs_source_update(source, nil)
    local cube_out = OUT .. "/export_identity.cube"
    check(H.export_lut(data, cube_out) == true, "cube export succeeds")
    local text = assert(io.open(cube_out, "rb")):read("*a")
    local lut = assert(H.cube_lut.parse_cube(text))
    check(lut.size == 33, "exported size 33")
    local max_err = 0
    local n = 33
    for b = 0, n - 1 do for g = 0, n - 1 do for r = 0, n - 1 do
        local i = ((b * n + g) * n + r) * 3
        max_err = math.max(max_err, math.abs(lut.data[i + 1] - r / (n - 1)), math.abs(lut.data[i + 2] - g / (n - 1)), math.abs(lut.data[i + 3] - b / (n - 1)))
    end end end
    check(max_err < 1e-5, "identity export is identity (max err " .. max_err .. ")")
    settings.values.exposure = 1.0
    mock.obs_source_update(source, nil)
    check(H.export_lut(data, cube_out) == true, "cube export with exposure")
    lut = assert(H.cube_lut.parse_cube(assert(io.open(cube_out, "rb")):read("*a")))
    check(near(lut.data[((0 * n + 0) * n + 8) * 3 + 1], 0.5, 1e-5), "exposure +1 doubles 0.25 -> 0.5")
    local png_out = OUT .. "/export.png"
    local t0 = os.clock()
    check(H.export_lut(data, png_out) == true, "png export succeeds")
    print(string.format("  png export took %.2fs", os.clock() - t0))
    local tex = mock.gs_texture_create_from_file(png_out)
    check(tex and tex.w == 512 and tex.h == 512 and tex.bits == 8, "png export is 512x512 8-bit")
    check(H.export_lut(data, OUT .. "/noext") == true and mock.os_file_exists(OUT .. "/noext.cube"), "missing extension defaults to .cube")
    -- Export mit geladener CUBE-LUT bäckt die LUT ein
    settings.values.exposure = 0
    settings.values.lut_path = fixture
    mock.obs_source_update(source, nil)
    info.video_render(data)
    check(data.lut and data.lut.is_cube == true and data.lut.path == fixture, "cube LUT remembered for export")
    check(H.export_lut(data, cube_out) == true, "export with cube LUT")
    lut = assert(H.cube_lut.parse_cube(assert(io.open(cube_out, "rb")):read("*a")))
    check(near(lut.data[((0 * n + 0) * n + 16) * 3 + 1], 0.5, 1e-5), "identity LUT baked into export keeps values")
    -- Cache: same content under a new name hits the cache (no new atlas files), changed content misses
    local before_files = #(function() local t = {} for f in io.popen('dir /b "' .. (H.lut_cache_dir():gsub("/", "\\")) .. '"'):lines() do t[#t + 1] = f end return t end)()
    local copy = OUT .. "/identity3_copy.cube"
    do local fh = assert(io.open(copy, "wb")); fh:write(assert(io.open(fixture, "rb")):read("*a")); fh:close() end
    settings.values.lut_path = copy
    mock.obs_source_update(source, nil)
    info.video_render(data)
    local after_files = #(function() local t = {} for f in io.popen('dir /b "' .. (H.lut_cache_dir():gsub("/", "\\")) .. '"'):lines() do t[#t + 1] = f end return t end)()
    check(data.lut ~= nil and after_files == before_files + 2, "different path with same content gets its own cache entry (path is part of the key)")
    do local fh = assert(io.open(copy, "ab")); fh:write("\n# changed\n"); fh:close() end
    settings.values.lut_path = ""
    mock.obs_source_update(source, nil)
    settings.values.lut_path = copy
    mock.obs_source_update(source, nil)
    info.video_render(data)
    local after_files2 = #(function() local t = {} for f in io.popen('dir /b "' .. (H.lut_cache_dir():gsub("/", "\\")) .. '"'):lines() do t[#t + 1] = f end return t end)()
    check(data.lut ~= nil and after_files2 == after_files + 2, "changed content invalidates the cache")
    settings.values.lut_path = fixture
    mock.obs_source_update(source, nil)
    info.video_render(data)

    section("look export/import")
    settings.values.lut_path = ""
    H.reset_settings(settings)
    settings.values.contrast = 0.33
    settings.values.ss_sat = 0.5
    settings.values.mask_x = 0.9
    mock.obs_source_update(source, nil)
    local look = OUT .. "/look.json"
    check(H.export_look(data, look) == true, "look saved")
    H.reset_settings(settings)
    mock.obs_source_update(source, nil)
    check(near(data.v.contrast, 0), "reset before import")
    check(H.import_look(data, look) == true, "look imported")
    check(near(data.v.contrast, 0.33) and near(data.v.ss_sat, 0.5), "look values restored")
    check(near(data.v.mask_x, 0.5), "mask not part of look")
    check(H.import_look(data, OUT .. "/nope.json") == false, "missing look reported")
end

section("destroy")
info.destroy(data)
check(data.effect == nil and data.lut == nil, "resources cleared")
check(settings.refs == 1, "settings released")
check(mock.graphics_depth == 0, "graphics context balanced")

print(string.format("\n%d passed, %d failed", passed, failed))
if failed > 0 then error(failed .. " test(s) failed") end
