# Developer notes — hard-won rules for this OBS Lua filter

These cost hours to find. Read before touching the render path.

## 1. `get_width` / `get_height` are mandatory for Lua filters
obs-scripting always installs the C `get_width`/`get_height` callbacks for a Lua
source; without a Lua implementation they return 0. OBS asks a source's size via
its *first filter* (`obs_source_get_width` → `get_recurse_width`), so a filter
without these callbacks makes the whole source 0×0 → invisible / transparent
screenshots. The filter must return the target's base size.

## 2. Direct3D 11: every constant-buffer parameter must be set before the first draw
`gs_shader::UploadParams` throws `Not all shader parameters were set` if any
non-texture parameter of the compiled shader has never been assigned, and
`device_draw` then aborts the draw. Symptom: the filter output is fully
transparent, no Lua error, only a `device_draw (D3D11): Not all shader parameters
were set` line in the OBS log. `ensure_effect()` therefore primes every parameter
with zeros right after compiling. Unused uniforms are dropped by the effect
parser and do not count; a parameter only referenced inside an `if` still counts.

## 3. Testing in real OBS without touching the user's setup
`dev/tests/obs_sandbox.ps1` restarts a portable OBS copy (`C:\Temp\obs-portable`,
`portable_mode.txt`, own config, obs-websocket on port 4457) whose scene
collection loads the repo script directly. `dev/tests/obs_live_check.py` then
creates a temporary colour source + filter and compares GPU screenshots.
- OBS 32 keeps a `.sentinel` *directory*; a killed instance leaves it behind and
  the next start shows the crash dialog (websocket never comes up). The script
  removes it.
- obs-websocket listens on IPv4 and IPv6, but connect to `127.0.0.1`, not
  `localhost`, from Python.
- `--disable-shutdown-check` only skips the safe-mode prompt, not the crash dialog.

## 4. Offline checks
- `dev/run_lua.py dev/tests/test_script.lua`: whole script against `mock_obslua.lua`
  (the mock enforces rule 2 in `obs_source_process_filter_end`).
- `dev/effect_to_hlsl.py --from-lua lumetric_corrector.lua`: fxc compile of the
  embedded effect (vs_4_0/ps_4_0). fxc assigns texture/sampler registers in
  declaration order, matching libobs.
- Module sources live in `dev/lua/`; `dev/inline_modules.py` copies them into the
  script (single-file distribution).
