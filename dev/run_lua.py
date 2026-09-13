"""Run a Lua file under LuaJIT 2.1 (via lupa), mimicking the OBS scripting runtime.

Usage:  uv run --with lupa python dev/run_lua.py <file.lua> [args...]

package.path is extended with dev/lua/?.lua and dev/tests/?.lua so tests can
`require("png_encoder")` etc.  Exit code is non-zero on any Lua error.
"""
import os
import sys

from lupa import luajit21 as lupa  # LuaJIT 2.1, same VM family as OBS

HERE = os.path.dirname(os.path.abspath(__file__)).replace("\\", "/")


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    path = sys.argv[1]
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(
        'package.path = "%s/lua/?.lua;%s/tests/?.lua;" .. package.path' % (HERE, HERE)
    )
    lua.globals().arg = lua.table_from([path] + sys.argv[2:])
    with open(path, encoding="utf-8") as fh:
        src = fh.read()
    loader = lua.eval(
        "function(src, name) local c, e = loadstring(src, '=' .. name); return c, e end"
    )
    chunk, err = loader(src, path)
    if chunk is None:
        print("LUA SYNTAX ERROR:", err)
        return 1
    try:
        chunk()
    except lupa.LuaError as exc:  # runtime error inside Lua
        print("LUA RUNTIME ERROR:", exc)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
