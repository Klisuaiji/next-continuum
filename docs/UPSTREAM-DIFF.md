# 上游差异台账（UPSTREAM-DIFF）

基线：**Continuum 2.0 Redux Build 2**（08.03.2026，官方 zip，332 个 shaders/ 文件）。
规则：**任何对 `shaders/` 的修改必须在此登记**（文件、原因、可否 rebase）；纯新增文件也要登记。每次上游新 build，按本表逐条 rebase。

## Phase 1（移植线，已归档 legacy-1.21.1）

- `shaders/` 全部文件：**零修改**（静态核验通过，见 docs/legacy 移植报告 §3-4）。
- 新增：`pack.mcmeta`、`移植说明.md`、`Continuum-Redux-Iris1.21.1-移植报告.md`、`README.md`、`LICENSE`（保留原件）。

## Phase 2（LOD 支持线，进行中）

### S0 工程化基线（本次提交，`shaders/` 仍零修改）

| 文件 | 类型 | 说明 |
|---|---|---|
| `scripts/check_includes.py` | 新增 | include 图校验（Iris 预处理等价模拟） |
| `scripts/check_resources.py` | 新增 | image 上限/voxy.json schema/维度一致性/保留字/colortex 台账 |
| `scripts/check_glsl.py` + `scripts/glsl_baseline.json` | 新增 | glslang 基线差分（只禁新增失败） |
| `.github/workflows/ci.yml` | 新增 | push/PR 触发三项校验 |
| `docs/TARGET-MATRIX.md` | 新增 | 支持矩阵与升级红线 |
| `docs/UPSTREAM-DIFF.md` | 新增 | 本台账 |
| `docs/legacy/*` | 移动 | Phase 1 两份移植文档归档 |
| `pack.mcmeta` | 修改 | description 更新为 1.21.1+ 定位（pack_format 34 保持=下限） |
| `README.md` | 修改 | 增补 Phase 2 状态与文档指引 |

### S1 抽象层（本次提交）

| 文件 | 类型 | 说明 | rebase 难度 |
|---|---|---|---|
| `shaders/InternalLib/Common/LodSupport.glsl` | 新增 | 唯一 LOD 语义入口（DH/Voxy uniform 声明+统一命名+nc_is_lod_terrain） | 无（纯新增） |
| `shaders/Passes/C0_ConstructDepth.comp` | 修改 | vx* 局部声明→抽象层；`#ifdef VOXY`→`#ifdef LOD_PRESENT`；变量更名 DH→Lod；语义对 Voxy 保持等价 | 低（上游若改深度合成需人工合并） |
| `shaders/Passes/D0_ConstructDepth.comp` | 修改 | 同 C0 | 低 |
| `shaders/Passes/B0_InitSSBOs.comp` | 修改 | 新增 DISTANT_HORIZONS 分支（直接用 Iris combined 矩阵，不重建透视）；VOXY 分支保持现状=已知债；删除本地 vxRenderDistance 声明（改由抽象层声明） | 低 |

### S2 初版 · DH 通道骨架（本次提交）

| 文件 | 类型 | 说明 | rebase 难度 |
|---|---|---|---|
| `shaders/Passes/DH/Terrain.vert/.frag` | 新增 | dh_terrain 程序体：块网格对齐 + dhProjection（经抽象层）+ TAA 抖动；输出契约与 GBuffersMain 三项 gl_FragData 完全一致；LOD 无视差/法线贴图，roughness=1/f0=0/shadow 中性/matFlag=0 | 无（纯新增） |
| `shaders/Passes/DH/Water.vert/.frag` | 新增 | dh_water 程序体（初版无波浪位移，f0=0.04，matFlag=8/255 对齐 Voxy 水标记） | 无 |
| `shaders/Dim*/dh_terrain.{vsh,fsh}`、`Dim*/dh_water.{vsh,fsh}` | 新增 | 12 个维度入口薄壳（#version 430 compatibility + DIM_* 宏 + include） | 无 |
| `scripts/check_glsl.py` | 修改 | `Passes/DH/` 程序体与 `Dim*/dh_*` 入口退出无宏基线遍历（LOD 专用代码由宏门控覆盖，防假阳性） | 低 |
| `scripts/check_lod_macros.py` | 修改 | TARGETS 扩展至 4 个 DH 程序体（按 stage 编译，VOXY/DISTANT_HORIZONS 双宏无新增错误类别） | 低 |

S2 尾注（本次提交）：`Passes/DH/Water.frag` 接入 `GetWavesNormal(waveTex,...)` 波浪法线（与 Voxy 通道同源同参：NoV/roughness/f0/matFlag=8 全对齐）。

LOD 阴影调研结论（2026-10-31，Iris 1.21.11 + Voxy dev 源码核验）：
- **DH 有独立 shadow 程序槽**（`DHCompatInternal.java` L82：`shadowProgram = IrisLodRenderProgram.createProgram(shadow.getName(), true, false, ...)`，Bliss 的 world0 `dh_shadow.*` 即走此通道）；
- **当前 Voxy 集成面不含 shadow 程序**（`MixinShaderPackSourceNames` 仅注入 `voxy.json`/`voxy_opaque.glsl`/`voxy_translucent.glsl`；Voxy 仓库全文检索 shadow_voxels 0 命中）——Voxy 侧 LOD 阴影暂不可得，Photon main 的 shadow_voxels 属超前/废弃文件，不追随；
- dh_shadow 待办挂起原因：DH shadow 程序的顶点坐标系语义（网格对齐 vs 相机原系）需比对 Bliss 参考实装后才能定，避免推测写入。

### S2 续 · dh_shadow（本次提交）

| 文件 | 类型 | 说明 | rebase 难度 |
|---|---|---|---|
| `shaders/Passes/DH/Shadow.vert/.frag` | 新增 | LOD 进主阴影图：相机原系顶点（无网格对齐，语义=Bliss dh_shadow 经源码核验），投影链复用本包 DistortShadowSpace+z*0.25；水体(gl_Color.a<1)与 cutout discard；不写体素光网格/不接 caustics | 无 |
| `shaders/DimOverworld/dh_shadow.{vsh,fsh}` | 新增 | 仅主世界（对齐 Bliss；下界/末无太阳阴影语义） | 无 |
| `scripts/check_resources.py` | 修改 | 维度一致性豁免 dh_shadow.* | 低 |
| `scripts/check_lod_macros.py` | 修改 | TARGETS 增至 9 个（含 Shadow.vert/.frag） | 低 |

### 本地化（本次提交）

| 文件 | 类型 | 说明 |
|---|---|---|
| `shaders/lang/zh_CN.lang` | 新增 | 简体中文全量 446 键（术语表驱动：体积云/全局光照/瑞利·米氏散射/焦散/半影角 等统一；单位后缀 mm/m/K/lx 保持原样） |
| `shaders/lang/zh_TW.lang` | 新增 | 繁体中文（OpenCC s2twp 自动转换） |
| `shaders/lang/ja_JP.lang` | 新增 | 日文全量 446 键 |

### 计划改动（实施时逐条登记）

- S1：`InternalLib/Common/LodSupport.glsl`（新增）；`Passes/B0_InitSSBOs.comp`、`Passes/C0|D0_ConstructDepth.comp`、`Passes/C8_TAA.frag`（修改）
- S2 后续：波浪法线/材质映射精修（见上）
- S3：`Dim*/shadow_voxels.*`（视 0.2.16 集成面核实）、`Dim*/voxy.json`（renderScale 预留）（修改）
- 已知债（暂不修）：B0 VOXY 分支 GenPerspectiveMat 重建丢剪切分量；修复候选期为 S2 后评估。

---

内容由 AI 生成
