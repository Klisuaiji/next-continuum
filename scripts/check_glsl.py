#!/usr/bin/env python3
"""Next Continuum · GLSL 批检（glslangValidator + 基线差分）
把 Dim*/Passes 入口程序内联展开为单文件，逐一跑 glslangValidator（OpenGL 目标环境）。
已知现象（移植报告）：SPIR-V 模式对 compat profile / uniform-IO location 存在成批伪错误，
因此本工具不追求全绿，而是维护"失败集合基线"：只禁止新增失败，允许失败消失（打印提示）。
用法: python3 scripts/check_glsl.py [shaders目录] [--update-baseline]
"""
import os, re, sys, json, subprocess, tempfile, shutil
from check_includes import expand

STAGE_EXT = {'.vsh': '.vert', '.fsh': '.frag', '.csh': '.comp'}
BASELINE = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'glsl_baseline.json')
G = re.compile(r'\.glsl$')

def entry_programs(shader_root):
    out = []
    for dirpath, _, names in os.walk(shader_root):
        for n in names:
            p = os.path.join(dirpath, n)
            ext = os.path.splitext(n)[1]
            if ext in STAGE_EXT:
                # DH 专用 Dim 入口同样交给宏门控校验，不参与无宏基线
                if n.startswith('dh_'):
                    continue
                out.append(p)
            elif n.endswith(('.comp', '.frag', '.vert')) and '/Passes/' in p.replace(os.sep, '/'):
                # Passes/DH 下的程序体必须带 DISTANT_HORIZONS/VOXY 宏才有意义，
                # 由 check_lod_macros.py 的宏门控覆盖，不参与无宏基线遍历
                if '/Passes/DH/' in p.replace(os.sep, '/'):
                    continue
                out.append(p)
    return sorted(out)

def main():
    shader_root = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith('--') else 'shaders'
    update = '--update-baseline' in sys.argv
    tmp = tempfile.mkdtemp(prefix='nc-glsl-')
    failed = []
    total = 0
    for prog in entry_programs(shader_root):
        total += 1
        rel = os.path.relpath(prog, shader_root).replace(os.sep, '/')
        ext = os.path.splitext(prog)[1]
        out_ext = STAGE_EXT.get(ext, ext)
        name = re.sub(r'[^a-zA-Z0-9]', '_', rel) + out_ext
        fused = os.path.join(tmp, name)
        with open(fused, 'w', encoding='utf-8') as f:
            f.write(expand(prog, os.path.abspath(shader_root)))
        r = subprocess.run(['glslangValidator', '-o', fused + '.spv',
                            '--target-env', 'opengl', fused],
                           capture_output=True, text=True, cwd=tmp)
        if r.returncode != 0:
            failed.append(rel)
    shutil.rmtree(tmp, ignore_errors=True)

    baseline = set(json.load(open(BASELINE))) if os.path.isfile(BASELINE) and not update else None
    now = set(failed)
    if update or baseline is None:
        json.dump(sorted(now), open(BASELINE, 'w'), indent=1, ensure_ascii=False)
        print(f'[check_glsl] 基线已写入: {len(now)}/{total} 失败（glslang SPIR-V 模式伪错误为主，见移植报告 §4）')
        sys.exit(0)

    new = sorted(now - baseline)
    gone = sorted(baseline - now)
    print(f'[check_glsl] 失败 {len(now)}/{total}，基线 {len(baseline)}')
    for n in gone:
        print(f'  [改善] 已修复: {n}')
    ok = True
    for n in new:
        ok = False
        print(f'  [新增失败] {n}')
    print('[check_glsl] PASS' if ok else '[check_glsl] FAIL')
    sys.exit(0 if ok else 1)

if __name__ == '__main__':
    main()
