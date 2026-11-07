#!/usr/bin/env python3
"""Generate mod-dimension program folder shells from an existing Dim* template.

Each shader dimension folder must expose an identical program file set
(enforced by check_resources.py). The shells only differ in their DIM_*
define, so new folders are produced by copying the template folder's files
and replacing the dimension define token.

Usage:
    python3 scripts/generate_dimension_shells.py DimNether DimTwilight DIM_TWILIGHT
    python3 scripts/generate_dimension_shells.py DimNether DimSpace DIM_SPACE --force

Idempotent: existing files whose generated content matches are skipped;
mismatched files are reported and only overwritten with --force.
"""
import sys
from pathlib import Path

SHADER_ROOT = Path(__file__).resolve().parent.parent / "shaders"


def generate(template: str, target: str, dim_define: str, force: bool) -> int:
    src_dir = SHADER_ROOT / template
    dst_dir = SHADER_ROOT / target
    if not src_dir.is_dir():
        print(f"[error] template folder missing: {src_dir}", file=sys.stderr)
        return 1

    written = skipped = mismatched = 0
    for src_file in sorted(src_dir.rglob("*")):
        rel = src_file.relative_to(src_dir)
        dst_file = dst_dir / rel
        if src_file.is_dir():
            dst_file.mkdir(parents=True, exist_ok=True)
            continue
        content = src_file.read_text(encoding="utf-8").replace("DIM_" + template.removeprefix("Dim").upper(), dim_define)
        if dst_file.exists():
            existing = dst_file.read_text(encoding="utf-8")
            if existing == content:
                skipped += 1
                continue
            if not force:
                print(f"[mismatch] {dst_file} differs; pass --force to overwrite", file=sys.stderr)
                mismatched += 1
                continue
        dst_file.parent.mkdir(parents=True, exist_ok=True)
        dst_file.write_text(content, encoding="utf-8")
        written += 1

    print(f"[generate] {target}: {written} written, {skipped} unchanged, {mismatched} mismatched")
    return 1 if mismatched else 0


if __name__ == "__main__":
    if len(sys.argv) < 4:
        print(__doc__)
        sys.exit(2)
    force = "--force" in sys.argv
    args = [a for a in sys.argv[1:] if a != "--force"]
    sys.exit(generate(args[0], args[1], args[2], force))
