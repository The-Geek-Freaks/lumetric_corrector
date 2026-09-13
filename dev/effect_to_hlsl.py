"""Translate an OBS .effect (HLSL dialect) into plain HLSL and compile it with fxc.

This approximates what libobs' d3d11 shader processor does so the shader can be
syntax/type checked offline on Windows:

    uv run python dev/effect_to_hlsl.py dev/shader_spec.effect
    uv run python dev/effect_to_hlsl.py --from-lua lumetric_corrector.lua

Exit code 0 means vertex and pixel shader compiled with vs_4_0 / ps_4_0.
"""
import glob
import os
import re
import subprocess
import sys
import tempfile


def find_fxc() -> str:
    candidates = sorted(
        glob.glob(r"C:\Program Files (x86)\Windows Kits\10\bin\*\x64\fxc.exe")
    )
    if not candidates:
        raise SystemExit("fxc.exe not found (Windows SDK required)")
    return candidates[-1]


def extract_from_lua(lua_src: str) -> str:
    m = re.search(r"shader_code\s*=\s*\[\[(.*?)\]\]", lua_src, re.S)
    if not m:
        raise SystemExit("shader_code = [[...]] block not found in Lua file")
    return m.group(1)


def translate(effect: str) -> str:
    src = effect
    # samplers: OBS declares sampler_state blocks; plain HLSL wants SamplerState decls
    src = re.sub(r"sampler_state\s+(\w+)\s*\{[^}]*\}\s*;", r"SamplerState \1;", src)
    src = re.sub(r"\btexture2d\b", "Texture2D", src)
    src = re.sub(r"\btexture3d\b", "Texture3D", src)
    # semantics used by libobs
    src = re.sub(r":\s*TARGET\b", ": SV_Target", src)
    src = re.sub(r":\s*POSITION\b", ": SV_Position", src)
    # drop technique block
    src = re.sub(r"technique\s+\w+\s*\{.*?\}\s*\}", "", src, flags=re.S)
    return src


def compile_stage(fxc: str, hlsl_path: str, profile: str, entry: str) -> bool:
    proc = subprocess.run(
        [fxc, "/nologo", "/T", profile, "/E", entry, "/Fo", os.devnull, hlsl_path],
        capture_output=True,
        text=True,
    )
    ok = proc.returncode == 0
    print(f"[{profile} {entry}] {'OK' if ok else 'FAILED'}")
    if proc.stdout.strip():
        print(proc.stdout)
    if proc.stderr.strip():
        print(proc.stderr)
    return ok


def main() -> int:
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        return 2
    from_lua = False
    if args[0] == "--from-lua":
        from_lua = True
        args = args[1:]
    path = args[0]
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    effect = extract_from_lua(text) if from_lua else text
    hlsl = translate(effect)
    fxc = find_fxc()
    with tempfile.NamedTemporaryFile("w", suffix=".hlsl", delete=False, encoding="utf-8") as tmp:
        tmp.write(hlsl)
        hlsl_path = tmp.name
    try:
        ok_vs = compile_stage(fxc, hlsl_path, "vs_4_0", "VSDefault")
        ok_ps = compile_stage(fxc, hlsl_path, "ps_4_0", "PSDefault")
    finally:
        os.unlink(hlsl_path)
    return 0 if (ok_vs and ok_ps) else 1


if __name__ == "__main__":
    sys.exit(main())
