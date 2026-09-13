"""Inline the dev/lua modules into lumetric_corrector.lua.

OBS scripts are distributed as a single file, so the modules developed and
tested under dev/lua are copied verbatim into marked regions of the script:

    local png_encoder = (function()
    ...module source...
    end)()

Re-running is idempotent: the whole region between the header line and the
closing `end)()` is replaced.

    uv run python dev/inline_modules.py
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPT = os.path.join(ROOT, "lumetric_corrector.lua")
MODULES = ["png_encoder", "cube_lut", "grade_pixel"]


def main() -> int:
    with open(SCRIPT, encoding="utf-8", newline="") as fh:
        script = fh.read()
    for name in MODULES:
        path = os.path.join(ROOT, "dev", "lua", f"{name}.lua")
        with open(path, encoding="utf-8") as fh:
            body = fh.read().rstrip("\n")
        pattern = re.compile(
            r"(local %s = \(function\(\)\n)(.*?)(\nend\)\(\))" % re.escape(name), re.S
        )
        if not pattern.search(script):
            print(f"marker for {name} not found in script")
            return 1
        script, count = pattern.subn(lambda m: m.group(1) + body + m.group(3), script, count=1)
        print(f"inlined {name}: {len(body.splitlines())} lines")
    with open(SCRIPT, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(script)
    return 0


if __name__ == "__main__":
    sys.exit(main())
