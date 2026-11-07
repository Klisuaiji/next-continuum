#!/usr/bin/env python3
"""Next Continuum · 资源账与集成面校验
1) shaders.properties：image.* 数量 ≤ 16（Iris 硬上限）、bufferObject/customTexture 清单
2) 各 Dim* 目录 voxy.json：可解析、version==1、必备键齐全
3) 维度目录一致性：三个 Dim* 的程序文件集合必须相同
4) 保留字扫描：moj_import / irisMain / iris_ 前缀（Iris 直接拒绝）
5) colortex 占用台账（含 size.buffer / flip / const bool colortexN*）
用法: python3 scripts/check_resources.py [shaders目录]
"""
import os, re, sys, json
from check_includes import expand, INCLUDE_RE

MAX_IMAGES = 16
VOXY_REQUIRED = ['version', 'opaqueDrawBuffers', 'translucentDrawBuffers', 'uniforms', 'samplers']

def fail(msg):
    print(f'  [FAIL] {msg}')
    return 1

def strip_preproc(text):
    lines = [l for l in text.splitlines() if not INCLUDE_RE.match(l) and not re.match(r'^\s*#', l)]
    return '\n'.join(lines)

def lenient_json(text):
    # Voxy 用 Gson 宽松模式解析：数字键可不带引号（如 -1: "off"）。校验器补齐引号。
    return re.sub(r'([{,])\s*(-?\w+)\s*:', r'\1"\2":', text)

def main():
    shader_root = sys.argv[1] if len(sys.argv) > 1 else 'shaders'
    props_path = os.path.join(shader_root, 'shaders.properties')
    with open(props_path, encoding='utf-8') as f:
        props = f.read()
    errors = 0

    # 1) image 上限
    images = re.findall(r'^image\.\w+', props, re.M)
    print(f'[resources] image.* 声明 {len(images)} 个（上限 {MAX_IMAGES}）')
    if len(images) > MAX_IMAGES:
        errors += fail(f'image 超限: {len(images)}')

    # 2) voxy.json 校验（注意：unusedThing 技巧=把 #include 塞进字符串值，
    #    与 Iris 预处理一致——按"剥掉 # 行"解析，而非内联展开，否则 GLSL 体混入 JSON）
    dims = sorted(d for d in os.listdir(shader_root) if d.startswith('Dim'))
    voxy_files = [os.path.join(shader_root, d, 'voxy.json') for d in dims]
    voxy_files.append(os.path.join(shader_root, 'Passes', 'Voxy.json'))
    checked_any = False
    for vp in voxy_files:
        if not os.path.isfile(vp):
            continue
        with open(vp, encoding='utf-8') as f:
            body = strip_preproc(f.read()).strip()
        if not body:
            continue  # Dim 薄壳文件只含 #define/#include，交由 include 校验器覆盖
        checked_any = True
        try:
            data = json.loads(lenient_json(body), strict=False)
        except Exception as e:
            errors += fail(f'{vp} JSON 解析失败: {e}')
            continue
        if data.get('version') != 1:
            errors += fail(f'{vp} version={data.get("version")}（当前 Voxy 集成面为 1）')
        for k in VOXY_REQUIRED:
            if k not in data:
                errors += fail(f'{vp} 缺必备键 {k}')
    print(f'[resources] voxy.json 校验完成（维度目录: {", ".join(dims)}）')

    # 3) 维度一致性
    sets = {d: set(os.listdir(os.path.join(shader_root, d))) for d in dims}
    # dh_shadow 惯例仅主世界提供（Bliss 先例），从一致性集合中剔除
    sets = {d: {f for f in fs if not f.startswith('dh_shadow')} for d, fs in sets.items()}
    base = sets[dims[0]]
    for d in dims[1:]:
        diff = base ^ sets[d]
        if diff:
            errors += fail(f'{d} 与 {dims[0]} 程序集合不一致: {sorted(diff)}')
    if not errors:
        print('[resources] 维度目录程序集合一致')

    # 4) 保留字扫描
    hit = 0
    for dirpath, _, names in os.walk(shader_root):
        for n in names:
            if not n.endswith(('.glsl', '.comp', '.frag', '.vert', '.vsh', '.fsh', '.csh')):
                continue
            p = os.path.join(dirpath, n)
            with open(p, encoding='utf-8', errors='replace') as f:
                t = f.read()
            for kw in ('moj_import', 'irisMain'):
                if kw in t:
                    print(f'  [FAIL] 保留字 {kw} @ {p}'); hit += 1
            if re.search(r'\biris_\w+', t):
                print(f'  [FAIL] iris_ 前缀标识符 @ {p}'); hit += 1
    errors += hit and fail(f'保留字命中 {hit}')
    if hit == 0:
        print('[resources] 保留字扫描 0 命中')

    # 5) colortex 台账
    used = sorted({int(m) for m in re.findall(r'colortex(\d+)', props)}, reverse=False)
    print(f'[resources] shaders.properties 涉及 colortex 槽位: {used}')

    # 6) properties 必须纯 ASCII
    # Iris 用 JCPP 对 *.properties 做 C 预处理；非 ASCII 字符会抛
    # InternalException "Bad token"，导致整份条件选项静默失效。
    non_ascii = 0
    for dirpath, _, names in os.walk(shader_root):
        for n in names:
            if not n.endswith('.properties'):
                continue
            p = os.path.join(dirpath, n)
            with open(p, encoding='utf-8', errors='replace') as f:
                for ln, line in enumerate(f, 1):
                    if any(ord(c) > 127 for c in line):
                        errors += fail(f'{p}:{ln} 含非 ASCII 字符（JCPP 预处理会抛 Bad token）: {line.strip()[:70]}')
                        non_ascii += 1
    if non_ascii == 0:
        print('[resources] *.properties 纯 ASCII 检查通过')

    # 7) customTexture / texture 路径必须真实存在（zipfs 大小写敏感）
    # 实例案例：colorLookup3D.DAT 声明、实际文件 colorLookup3D.dat → NoSuchFileException
    tex_paths = re.findall(r'^(?:customTexture|texture)\.[\w.]+\s*=\s*(\S+)', props, re.M)
    tex_missing = 0
    for rel in tex_paths:
        target = os.path.join(shader_root, rel.lstrip('/').replace('/', os.sep))
        # 必须按精确文件名比对：Windows 文件系统大小写不敏感，但 Iris 从 zipfs
        # 读取时区分大小写，os.path.isfile() 会把 .DAT / .dat 误判为存在。
        parent, base = os.path.split(target)
        if not os.path.isfile(target) or base not in os.listdir(parent):
            errors += fail(f'纹理文件不存在或大小写不符: {rel}')
            tex_missing += 1
    print(f'[resources] 纹理路径校验 {len(tex_paths)} 条，缺失 {tex_missing}')

    # 8) DH 程序只允许调用目标 Iris 版本实际注入的函数
    # Iris 1.8.x(1.21.1) 不注入任何 dh_* 函数；dh_hasTexture / dh_sampleTexture
    # 属于新版 DISTANT_HORIZONS_TEXTURES 分支。升级目标平台时更新此白名单即可。
    DH_INJECTED_FUNCTIONS = set()
    dh_dir = os.path.join(shader_root, 'Passes', 'DH')
    dh_bad = 0
    if os.path.isdir(dh_dir):
        for n in sorted(os.listdir(dh_dir)):
            p = os.path.join(dh_dir, n)
            if not os.path.isfile(p):
                continue
            with open(p, encoding='utf-8', errors='replace') as f:
                for ln, line in enumerate(f, 1):
                    if line.lstrip().startswith('//'):
                        continue
                    for fn in re.findall(r'\b(dh_\w+)\s*\(', line):
                        if fn not in DH_INJECTED_FUNCTIONS:
                            errors += fail(f'{p}:{ln} 调用了目标 Iris 未注入的 DH 函数 {fn}()')
                            dh_bad += 1
    if dh_bad == 0:
        print(f'[resources] DH 注入函数白名单检查通过（允许 {len(DH_INJECTED_FUNCTIONS)} 个）')

    print('[resources] PASS' if errors == 0 else f'[resources] FAIL ({errors})')
    sys.exit(0 if errors == 0 else 1)

if __name__ == '__main__':
    main()
