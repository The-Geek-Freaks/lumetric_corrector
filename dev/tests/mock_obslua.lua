-- Minimal obslua mock for running lumetric_corrector.lua outside OBS (LuaJIT via lupa).
-- Covers exactly the API surface the script uses and records calls for assertions.
local M = {}

M.log = {}
M.locale = "en-US"
M.calls = { filter_end = 0, skip = 0 }
M.registered = nil
M.cache_root = nil   -- set by the test to a temp directory

-- Konstanten -----------------------------------------------------------------
M.LOG_ERROR, M.LOG_WARNING, M.LOG_INFO, M.LOG_DEBUG = 100, 200, 300, 400
M.OBS_SOURCE_TYPE_FILTER = 1
M.OBS_SOURCE_VIDEO = 1
M.OBS_SOURCE_CUSTOM_DRAW = 8
M.GS_RGBA = 3
M.OBS_NO_DIRECT_RENDERING = 0
M.OBS_COMBO_TYPE_LIST = 1
M.OBS_COMBO_FORMAT_STRING = 2
M.OBS_COMBO_FORMAT_FLOAT = 3
M.OBS_GROUP_NORMAL = 1
M.OBS_GROUP_CHECKABLE = 2
M.OBS_PATH_FILE = 0
M.OBS_PATH_FILE_SAVE = 1
M.OBS_TEXT_INFO = 3
M.OBS_TEXT_INFO_WARNING = 1

function M.blog(level, msg) table.insert(M.log, { level = level, msg = msg }) end
function M.script_log(level, msg) M.blog(level, msg) end
function M.obs_get_locale() return M.locale end

-- obs_data ---------------------------------------------------------------------
local function new_data()
    return { __obs_data = true, values = {}, defaults = {}, refs = 1 }
end
function M.obs_data_create() return new_data() end
function M.obs_data_addref(d) d.refs = d.refs + 1 end
function M.obs_data_release(d) d.refs = d.refs - 1; assert(d.refs >= 0, "obs_data over-released") end
local function setter(kind)
    return function(d, key, value) d.values[key] = value end
end
local function default_setter(kind)
    return function(d, key, value) d.defaults[key] = value end
end
local function getter(kind, fallback)
    return function(d, key)
        local v = d.values[key]
        if v == nil then v = d.defaults[key] end
        if v == nil then return fallback end
        if kind == "double" and type(v) == "boolean" then return v and 1 or 0 end
        return v
    end
end
M.obs_data_set_double, M.obs_data_set_bool, M.obs_data_set_string, M.obs_data_set_int = setter(), setter(), setter(), setter()
M.obs_data_set_default_double, M.obs_data_set_default_bool, M.obs_data_set_default_string = default_setter(), default_setter(), default_setter()
M.obs_data_get_double = getter("double", 0.0)
M.obs_data_get_int = function(d, key) local v = M.obs_data_get_double(d, key); return math.floor(v) end
M.obs_data_get_bool = getter("bool", false)
M.obs_data_get_string = getter("string", "")
function M.obs_data_has_user_value(d, key) return d.values[key] ~= nil end
function M.obs_data_erase(d, key) d.values[key] = nil end
function M.obs_data_apply(target, src) for k, v in pairs(src.values) do target.values[k] = v end end
function M.obs_data_clear(d) d.values = {} end

-- sehr kleiner JSON-Codec für flache Objekte
local function json_encode(values)
    local parts = {}
    local keys = {}
    for k in pairs(values) do keys[#keys + 1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do
        local v = values[k]
        local enc
        if type(v) == "number" then enc = string.format("%.17g", v)
        elseif type(v) == "boolean" then enc = tostring(v)
        else enc = string.format("%q", tostring(v)):gsub("\\\n", "\\n") end
        parts[#parts + 1] = string.format("%q: %s", k, enc)
    end
    return "{" .. table.concat(parts, ", ") .. "}"
end
local function json_decode(text)
    local values = {}
    for k, v in text:gmatch('"([^"]+)"%s*:%s*([^,}]+)') do
        v = v:gsub("^%s+", ""):gsub("%s+$", "")
        if v == "true" then values[k] = true
        elseif v == "false" then values[k] = false
        elseif v:sub(1, 1) == '"' then values[k] = v:sub(2, -2)
        else values[k] = tonumber(v) end
    end
    return values
end
function M.obs_data_get_json(d) return json_encode(d.values) end
function M.obs_data_save_json_safe(d, path)
    local fh = io.open(path, "wb")
    if not fh then return false end
    fh:write(json_encode(d.values))
    fh:close()
    return true
end
function M.obs_data_create_from_json_file(path)
    local fh = io.open(path, "rb")
    if not fh then return nil end
    local text = fh:read("*a")
    fh:close()
    local d = new_data()
    d.values = json_decode(text)
    return d
end

-- Vektoren ---------------------------------------------------------------------
function M.vec2() return { x = 0, y = 0 } end
function M.vec4() return { x = 0, y = 0, z = 0, w = 0 } end

-- Grafik -----------------------------------------------------------------------
M.graphics_depth = 0
function M.obs_enter_graphics() M.graphics_depth = M.graphics_depth + 1 end
function M.obs_leave_graphics() M.graphics_depth = M.graphics_depth - 1; assert(M.graphics_depth >= 0) end

function M.gs_effect_create(code, name)
    local effect = { code = code, name = name, params = {}, values = {} }
    for typ, uname in code:gmatch("uniform%s+([%w_]+)%s+([%w_]+)%s*;") do
        effect.params[uname] = { name = uname, type = typ, effect = effect }
    end
    M.last_effect = effect
    return effect
end
function M.gs_effect_destroy(effect) effect.destroyed = true end
function M.gs_effect_get_param_by_name(effect, name) return effect.params[name] end
function M.gs_effect_set_float(param, v) assert(type(v) == "number", "float expected for " .. param.name); param.effect.values[param.name] = v; param.sets = (param.sets or 0) + 1 end
function M.gs_effect_set_vec2(param, v) param.effect.values[param.name] = { v.x, v.y }; param.sets = (param.sets or 0) + 1 end
function M.gs_effect_set_vec4(param, v) param.effect.values[param.name] = { v.x, v.y, v.z, v.w }; param.sets = (param.sets or 0) + 1 end
function M.gs_effect_set_texture(param, tex) param.effect.values[param.name] = tex; param.sets = (param.sets or 0) + 1 end

local function read_png_header(path)
    local fh = io.open(path, "rb")
    if not fh then return nil end
    local head = fh:read(33)
    fh:close()
    if not head or #head < 33 or head:sub(1, 8) ~= "\137PNG\r\n\26\n" then return nil end
    local function be32(s, i) local a, b, c, d = s:byte(i, i + 3); return ((a * 256 + b) * 256 + c) * 256 + d end
    return { w = be32(head, 17), h = be32(head, 21), bits = head:byte(25), color_type = head:byte(26) }
end
function M.gs_texture_create_from_file(path)
    local info = read_png_header(path)
    if not info then return nil end
    M.textures_created = (M.textures_created or 0) + 1
    return { path = path, w = info.w, h = info.h, bits = info.bits }
end
function M.gs_texture_destroy(tex) tex.destroyed = true; M.textures_destroyed = (M.textures_destroyed or 0) + 1 end
function M.gs_texture_get_width(tex) return tex.w end
function M.gs_texture_get_height(tex) return tex.h end

-- Quellen / Filter ---------------------------------------------------------------
function M.obs_register_source(info) M.registered = info end
function M.obs_filter_get_target(source) return source.target end
function M.obs_source_get_base_width(t) return t.w end
function M.obs_source_get_base_height(t) return t.h end
function M.obs_source_process_filter_begin(source) source.in_pass = true; return true end
function M.obs_source_process_filter_end(source, effect, w, h)
    assert(source.in_pass, "filter_end without begin")
    source.in_pass = false
    -- libobs (D3D11) aborts the draw with "Not all shader parameters were set" when any
    -- constant-buffer parameter of the shader was never assigned. Mirror that strictly.
    for name, param in pairs(effect.params) do
        if name ~= "ViewProj" and not param.type:find("^texture") and effect.values[name] == nil then
            error("device_draw (D3D11): Not all shader parameters were set (" .. name .. ")")
        end
    end
    M.calls.filter_end = M.calls.filter_end + 1
    source.last_render = { effect = effect, w = w, h = h }
end
function M.obs_source_skip_video_filter(source) assert(source, "skip with nil source"); M.calls.skip = M.calls.skip + 1 end
function M.obs_source_update(source, settings)
    if settings then M.obs_data_apply(source.settings, settings) end
    M.registered.update(source.data, source.settings)
end

-- Properties ---------------------------------------------------------------------
local function new_props() return { __props = true, items = {} } end
local function add_item(props, item) table.insert(props.items, item); return item end
function M.obs_properties_create() return new_props() end
function M.obs_properties_add_float_slider(props, key, label, min, max, step)
    return add_item(props, { kind = "float_slider", key = key, label = label, min = min, max = max, step = step })
end
function M.obs_properties_add_int_slider(props, key, label, min, max, step)
    return add_item(props, { kind = "int_slider", key = key, label = label, min = min, max = max, step = step })
end
function M.obs_properties_add_list(props, key, label, ctype, cformat)
    return add_item(props, { kind = "list", key = key, label = label, ctype = ctype, cformat = cformat, entries = {} })
end
function M.obs_property_list_add_string(prop, label, value)
    table.insert(prop.entries, { label = label, value = value }); return #prop.entries - 1
end
function M.obs_property_list_add_float(prop, label, value)
    table.insert(prop.entries, { label = label, value = value }); return #prop.entries - 1
end
function M.obs_property_list_item_disable(prop, idx, disabled) prop.entries[idx + 1].disabled = disabled end
function M.obs_property_set_modified_callback(prop, cb) prop.modified = cb end
function M.obs_property_set_long_description(prop, text) prop.tooltip = text end
function M.obs_property_set_visible(prop, vis) prop.visible = vis end
function M.obs_properties_add_group(props, key, label, gtype, group)
    return add_item(props, { kind = "group", key = key, label = label, gtype = gtype, group = group })
end
function M.obs_properties_add_button(props, key, label, cb)
    return add_item(props, { kind = "button", key = key, label = label, callback = cb })
end
function M.obs_properties_add_path(props, key, label, ptype, filter, default)
    return add_item(props, { kind = "path", key = key, label = label, ptype = ptype, filter = filter, default = default })
end
function M.obs_properties_add_text(props, key, text, ttype)
    return add_item(props, { kind = "text", key = key, label = text, ttype = ttype })
end
function M.obs_property_text_set_info_type(prop, t) prop.info_type = t end
function M.obs_properties_get(props, key)
    for _, item in ipairs(props.items) do
        if item.key == key then return item end
        if item.kind == "group" then
            local found = M.obs_properties_get(item.group, key)
            if found then return found end
        end
    end
    return nil
end

-- Plattform ---------------------------------------------------------------------
function M.os_get_config_path_ptr(name)
    assert(M.cache_root, "test must set mock.cache_root")
    return M.cache_root .. "/" .. name
end
function M.os_mkdirs(path)
    -- Windows and POSIX: try both mkdir styles, ignore failures
    local p = path:gsub("/", package.config:sub(1, 1))
    if package.config:sub(1, 1) == "\\" then
        os.execute('mkdir "' .. p .. '" >nul 2>&1')
    else
        os.execute('mkdir -p "' .. p .. '" 2>/dev/null')
    end
    return true
end
function M.os_file_exists(path)
    local fh = io.open(path, "rb")
    if fh then fh:close() return true end
    return false
end
function M.os_quick_read_utf8_file(path)
    local fh = io.open(path, "rb")
    if not fh then return nil end
    local t = fh:read("*a")
    fh:close()
    return t
end
function M.os_quick_write_utf8_file(path, text, len, marker)
    local fh = io.open(path, "wb")
    if not fh then return false end
    fh:write(text)
    fh:close()
    return true
end

-- Testhelfer ----------------------------------------------------------------------
-- Erzeugt eine Filterinstanz wie OBS: Defaults anwenden, create aufrufen.
function M.create_filter(user_values, target)
    local info = assert(M.registered, "script_load() not called")
    local settings = new_data()
    info.get_defaults(settings)
    for k, v in pairs(user_values or {}) do settings.values[k] = v end
    local source = { settings = settings, target = target or { w = 1920, h = 1080 } }
    source.data = info.create(settings, source)
    return source, source.data, settings
end

function M.logs_matching(pattern, level)
    local out = {}
    for _, e in ipairs(M.log) do
        if (not level or e.level == level) and e.msg:find(pattern) then out[#out + 1] = e.msg end
    end
    return out
end

function M.reset_log() M.log = {} end

return M
