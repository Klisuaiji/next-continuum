#!/usr/bin/env python3
"""Next Continuum · GLSL 批检（glslangValidator + 基线差分）
把 Dim*/Passes 入口程序内联展开为单文件，逐一跑 glslangValidator（OpenGL 目标环境）。
已知现象（移植报告）：SPIR-V 模式对 compat profile / uniform-IO location 存在成批伪错误，
因此本工具不追求全绿，而是维护"失败集合基线"：只禁止新增失败，允许失败消失（打印提示）。

维度副本归一化：Dim*/ 下由 generate_dimension_shells.py 生成的程序副本，与原模板
只差一行 `#define DIM_*`，真正被编译的是同一份程序体（薄壳 include 到 Passes，
或逐字复制的占位文件）。比对基线时按"去掉 DIM_* 宏后的内容签名"把这类失败
归一到模板条目，新增维度目录便不会凭空产生上百条等价的"新增失败"——否则每加
一个维度就得刷一次基线。签名对不上的文件（含真实的维度专属改动）保持原路径，
仍会被当作新增失败检出。`--strict` 关闭归一化，回到逐路径比对，便于排查。

用法: python3 scripts/check_glsl.py [shaders目录] [--update-baseline] [--strict]
"""
import os, re, sys, json, subprocess, tempfile, shutil, hashlib
from check_includes import expand

STAGE_EXT = {'.vsh': '.vert', '.fsh': '.frag', '.csh': '.comp'}
BASELINE = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'glsl_baseline.json')
G = re.compile(r'\.glsl$')
DIM_DEFINE_RE = re.compile(r'^\s*#define\s+DIM_[A-Z0-9_]+\b.*$', re.M)
TEMPLATE_DIMS = ('DimOverworld', 'DimNether', 'DimEnd')


def dimension_signature(path):
    """文件去掉所有 #define DIM_* 后的内容签名（换行统一、首尾空白忽略）。"""
    try:
        with open(path, 'r', encoding='utf-8', errors='replace') as f:
            text = f.read()
    except OSError:
        return None
    text = DIM_DEFINE_RE.sub('', text).replace('\r\n', '\n').strip()
    return hashlib.sha1(text.encode('utf-8')).hexdigest()[:16]


def build_signature_map(raw_baseline, shader_root):
    """把基线中模板维度的失败条目登记为 签名 -> 模板相对路径。"""
    sig_map = {}
    for rel in sorted(raw_baseline):
        if '/' not in rel or rel.split('/')[0] not in TEMPLATE_DIMS:
            continue
        sig = dimension_signature(os.path.join(shader_root, rel))
        if sig:
            sig_map.setdefault(sig, rel)
    return sig_map


def canonical(rel, shader_root, sig_map):
    """维度副本按内容签名归一到模板条目；签名不匹配则保持原路径。"""
    if not rel.startswith('Dim') or '/' not in rel:
        return rel
    sig = dimension_signature(os.path.join(shader_root, rel))
    if sig and sig in sig_map:
        return sig_map[sig]
    return rel


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
    root = os.path.abspath(shader_root)
    update = '--update-baseline' in sys.argv
    strict = '--strict' in sys.argv
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
            f.write(expand(prog, root))
        r = subprocess.run(['glslangValidator', '-o', fused + '.spv',
                            '--target-env', 'opengl', fused],
                           capture_output=True, text=True, cwd=tmp)
        if r.returncode != 0:
            failed.append(rel)
    shutil.rmtree(tmp, ignore_errors=True)

    raw_baseline = set(json.load(open(BASELINE))) if os.path.isfile(BASELINE) and not update else None
    raw_now = set(failed)
    if update or raw_baseline is None:
        # 基线仍以原始相对路径记录，便于人工阅读与审计；归一化只在比对时进行。
        json.dump(sorted(raw_now), open(BASELINE, 'w'), indent=1, ensure_ascii=False)
        print(f'[check_glsl] 基线已写入: {len(raw_now)}/{total} 失败（glslang SPIR-V 模式伪错误为主，见移植报告 §4）')
        sys.exit(0)

    sig_map = {} if strict else build_signature_map(raw_baseline, root)

    def key(rel):
        return rel if strict else canonical(rel, root, sig_map)

    baseline = {key(x) for x in raw_baseline}
    now = {key(x) for x in raw_now}
    new = sorted(now - baseline)
    gone = sorted(baseline - now)
    mode = '逐路径 (--strict)' if strict else f'维度签名归一 ({len(sig_map)} 个模板签名)'
    print(f'[check_glsl] 失败 {len(raw_now)}/{total}，归一后 {len(now)} 键，基线 {len(baseline)} 键，模式 {mode}')
    for n in gone[:20]:
        print(f'  [改善] 已修复: {n}')
    if len(gone) > 20:
        print(f'  [改善] ...另有 {len(gone) - 20} 条失败消失')
    ok = True
    for n in new:
        ok = False
        print(f'  [新增失败] {n}')
    print('[check_glsl] PASS' if ok else '[check_glsl] FAIL')
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()
