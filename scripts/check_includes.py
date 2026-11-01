#!/usr/bin/env python3
"""Next Continuum · include 图校验器
模拟 Iris 预处理器的 #include 解析：相对路径、/ 绝对路径（相对 shaders/）、递归、循环防护。
覆盖 Dim* 程序与 Passes/UserLib/InternalLib 全部文本文件（含 *.json 内被预处理器处理的 include 行）。
用法: python3 scripts/check_includes.py [shaders目录]
"""
import os, re, sys

INCLUDE_RE = re.compile(r'^\s*#include\s*[<"]([^">]+)[">]\s*$')
TEXT_EXT = {'.glsl', '.comp', '.frag', '.vert', '.vsh', '.fsh', '.csh', '.json', '.dat'}
SKIP_EXT = {'.dat', '.png'}  # 二进制资源不做 include 扫描

def resolve(raw, current_file, shader_root):
    p = raw.strip()
    if p.startswith('/'):
        return os.path.normpath(os.path.join(shader_root, p.lstrip('/')))
    return os.path.normpath(os.path.join(os.path.dirname(current_file), p))

def scan_file(path, shader_root, stack, results, expand_cache):
    if path in stack:
        results['cycles'].append(' -> '.join(stack + [path]))
        return
    try:
        with open(path, 'r', encoding='utf-8', errors='replace') as f:
            lines = f.read().splitlines()
    except FileNotFoundError:
        results['missing'].append((stack[-1] if stack else '?', path))
        return
    for i, line in enumerate(lines, 1):
        m = INCLUDE_RE.match(line)
        if not m:
            continue
        target = resolve(m.group(1), path, shader_root)
        results['edges'] += 1
        if not os.path.isfile(target):
            results['missing'].append((f'{path}:{i}', target))
            continue
        scan_file(target, shader_root, stack + [path], results, expand_cache)

def expand(path, shader_root, seen=None):
    """把 include 内联展开（用于 glsl 单文件校验）。"""
    seen = seen or set()
    key = os.path.normpath(path)
    if key in seen:
        return ''
    out = []
    with open(key, 'r', encoding='utf-8', errors='replace') as f:
        for line in f.read().splitlines(True):
            m = INCLUDE_RE.match(line)
            if m:
                t = resolve(m.group(1), key, shader_root)
                if os.path.isfile(t):
                    out.append(expand(t, shader_root, seen | {key}))
                    continue
            out.append(line)
    return ''.join(out)

def main():
    shader_root = sys.argv[1] if len(sys.argv) > 1 else 'shaders'
    results = {'edges': 0, 'missing': [], 'cycles': []}
    files = 0
    for dirpath, _, names in os.walk(shader_root):
        for n in names:
            ext = os.path.splitext(n)[1]
            if ext in SKIP_EXT or ext not in TEXT_EXT:
                continue
            files += 1
            scan_file(os.path.join(dirpath, n), os.path.abspath(shader_root), [], results, {})
    print(f'[check_includes] 扫描文件 {files} 个，include 边 {results["edges"]} 条')
    ok = True
    for src, dst in results['missing']:
        ok = False
        print(f'  [缺失] {src} -> {dst}')
    for c in results['cycles']:
        ok = False
        print(f'  [循环] {c}')
    print('[check_includes] PASS' if ok else '[check_includes] FAIL')
    sys.exit(0 if ok else 1)

if __name__ == '__main__':
    main()
