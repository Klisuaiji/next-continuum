#!/usr/bin/env python3
"""Next Continuum · LOD 宏变体校验（相对基线）
glslang 原生不支持 Iris 运行时转换（compat→core、uniform location 提升），
绝对 0 错误不可行。正确模型：对同一文件分别以 无宏 / VOXY / DISTANT_HORIZONS
展开编译，宏开启版本的规范化错误集合必须是 无宏基线 的子集——
即"打开 LOD 宏不得引入任何新错误类别"（尤其不得出现 lod_/dh*/vx*/combined_ 相关）。
用法: python3 scripts/check_lod_macros.py [shaders目录]
"""
import os, re, sys, subprocess, tempfile
from check_includes import expand

TARGETS = [
    ('Passes/B0_InitSSBOs.comp', 'comp'),
    ('Passes/C0_ConstructDepth.comp', 'comp'),
    ('Passes/D0_ConstructDepth.comp', 'comp'),
    ('Passes/DH/Terrain.vert', 'vert'),
    ('Passes/DH/Terrain.frag', 'frag'),
    ('Passes/DH/Water.vert', 'vert'),
    ('Passes/DH/Water.frag', 'frag'),
    ('Passes/DH/Shadow.vert', 'vert'),
    ('Passes/DH/Shadow.frag', 'frag'),
]
MACROS = ['VOXY', 'DISTANT_HORIZONS']
VERSION_RE = re.compile(r'^\s*#version\s+(.+)$', re.M)

def hoist_version(src):
    m = VERSION_RE.search(src)
    ver = m.group(1) if m else '430'
    src = VERSION_RE.sub('', src)
    if 'core' not in ver and 'compatibility' not in ver and 'es' not in ver:
        ver = ver + ' compatibility'
    return '#version ' + ver + '\n' + src

def normalize(errs):
    out = set()
    for e in errs:
        e = re.sub(r'^ERROR: \S+?:\d+:', 'ERROR:', e)
        e = re.sub(r'\d+ compilation errors?', 'N compilation errors?', e)
        out.add(e.strip())
    return out

def compile_variant(src, name, tmp, ext='comp'):
    f = os.path.join(tmp, name + '.' + ext)
    with open(f, 'w', encoding='utf-8') as fh:
        fh.write(src)
    r = subprocess.run(['glslangValidator', '-o', f + '.spv', '--target-env', 'opengl', f],
                       capture_output=True, text=True, cwd=tmp)
    return normalize(re.findall(r'ERROR:.*', (r.stdout or '') + (r.stderr or '')))

def main():
    root = sys.argv[1] if len(sys.argv) > 1 else 'shaders'
    tmp = tempfile.mkdtemp(prefix='nc-lod-')
    ok = True
    for prog, ext in TARGETS:
        p = os.path.join(root, prog)
        if not os.path.isfile(p):
            print(f'  [FAIL] 缺少目标文件 {p}'); ok = False; continue
        src = hoist_version(expand(p, os.path.abspath(root)))
        head, _, body = src.partition('\n')
        base = compile_variant(src, os.path.basename(prog) + '.base', tmp, ext)
        for macro in MACROS:
            variant = head + '\n#define ' + macro + '\n' + body
            errs = compile_variant(variant, os.path.basename(prog) + '.' + macro, tmp, ext)
            new = sorted(errs - base)
            if new:
                ok = False
                print(f'  [FAIL] {prog} [{macro}] 引入 {len(new)} 类新错误:')
                for e in new[:6]:
                    print('    ', e[:160])
            else:
                print(f'  [OK] {prog} [{macro}] 无新增错误类别')
    print('[check_lod_macros] PASS' if ok else '[check_lod_macros] FAIL')
    sys.exit(0 if ok else 1)

if __name__ == '__main__':
    main()
