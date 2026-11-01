# 目标版本矩阵（Target Matrix）

> 本包定位：**只维护三条线 —— Minecraft 1.21.1 / 1.21.11 / 26.2。** 高清修复（OptiFine）与低版本适配线已放弃，1.21.1 下移植版归档为 tag `legacy-1.21.1`。
> 最后核验：2026-11-01。来源：Modrinth API 版本清单与 changelog（iris / distanthorizons / voxy / roxy）、Iris GitHub 分支源码（`1.21.1` / `1.21.11` / `26.2`）、Voxy GitHub 分支源码（`12111` / `2622` / `263` / `dev`）、Roxy README（仓库 `main`，pushed 2026-10-31）。

## 支持分级

| 档位 | MC | 加载器 | Iris（最新构建） | DH 集成 | Voxy 集成 | Roxy |
|---|---|---|---|---|---|---|
| 下限兼容线 | 1.21.1 | Fabric / NeoForge | `1.8.14-beta.1+1.21.1`（2026-06-13，fabric+neoforge） | ✅ `3.3.3-1.21.1`（2026-09-29，fabric+neoforge） | ⚠️ Voxy **无 1.21.1 构建**（Modrinth 查询 0 命中），只能经 Roxy | ✅ `0.4.1-neoforge+mc1.21.1`（2026-10-22，仅 NeoForge） |
| 主验证线 | 1.21.11 | Fabric / NeoForge | `1.10.8+1.21.11`（2026-09-29，fabric+neoforge） | ✅ `3.3.3-1.21.11`（2026-09-29） | ✅ `0.2.16-beta`（2026-05-25，仅 Fabric） | — |
| 新版本线 | 26.2 | Fabric / NeoForge | `1.11.4+26.2`（2026-09-13，fabric+neoforge） | ✅ `3.3.3-26.2`（2026-09-29）；**要求 DH ≥ 3.3.3** | ✅ `0.2.19-beta`（2026-08-29，仅 Fabric） | — |

范围说明：

- Iris 三条线均有 fabric 与 neoforge 构建；**Voxy 全部仅 Fabric**（Modrinth `loaders` 字段），NeoForge 侧只能用 Roxy。
- Roxy 只发布 MC 1.21.1 NeoForge 构建，1.21.11 / 26.2 既不需要也用不上。
- **1.21.10 不再单列档位**：Iris 在 1.21.10 停在 `1.9.7+1.21.10`（2025-12-18）、Voxy 停在 `0.2.9-alpha`（2026-01-15），上游均已不再更新；DH 3.3.3 虽同时发布 1.21.10/1.21.11，但没有值得单独维护的差异。
- 三条线共用同一个包，不做分版本出包；版本差异全部靠 Iris / Voxy 注入的宏与 uniform 在运行时区分。

## 接口核验（2026-11-01 逐分支实测）

### Iris 侧 · DH 通道

- DH 兼容层在三条分支上结构一致：`compat/dh/DHCompatInternal.java` 创建 terrain / water / shadow / generic 四个程序（`shadowProgram = IrisLodRenderProgram.createProgram(...)`，1.21.1 L81 / 1.21.11 L82 / 26.2 L82），`IrisLodRenderProgram` 以 `.setName("dh_" + name)` 命名 → 程序名 `dh_terrain` / `dh_water` / `dh_shadow`，与本包 `Dim*/dh_*.{vsh,fsh}` 入口一致。
- DH uniform 由 `CommonUniforms` 提供：`dhNearPlane` / `dhFarPlane` / `dhRenderDistance`（1.21.1 L168-170、26.2 L184-186，1.21.11 同源）。**`dhRenderDistance` 单位是方块**（`DHCompatInternal.getDhBlockRenderDistance()` = `chunkRenderDistance * 16`），不是 chunk。
- DH 深度采样器由 `IrisSamplers` 提供：`dhDepthTex` / `dhDepthTex0`（含半透明）与 `dhDepthTex1`（不含半透明），1.21.1 L96-97 与 26.2 L109-110 一致 → 本包 `lod_depth_tex = dhDepthTex0`、`lod_depth_tex_solid = dhDepthTex1` 语义正确。
- **26.2 独有差异**：`IrisLodRenderProgram` 新增 `dhBlockAtlas`（26.2 分支 L51 字段、L136 `tryGetUniformLocation2("dhBlockAtlas")`、L234 `setUniform(dhBlockAtlas, 0)`，并把 DH block ratio atlas 绑到纹理单元 0）；1.21.1 / 1.21.11 分支无此路径。本包 DH 程序当前不采样方块图集（`Passes/DH/Terrain.frag` 无采样器声明），故不受影响。**后续若给 DH 地形加图集着色：26.2 必须走 `dhBlockAtlas`，不能假定单元 0 仍是原版方块图集。**
- DH `3.3.3` changelog（2026-09-29）明确修复 “Iris on MC 26.1.2 and newer” 的 DH lightmap 缺失与 blend 错误 → 26.2 线要求 DH ≥ 3.3.3。同版本把 DH config version 4→5，会清空用户既有配置。

### Voxy 侧 · voxy.json 通道

- **集成入口在 Voxy，不在 Iris**：Iris 仓库三条分支全文检索 `voxy` 与 `SHADER_DEFINE_VERSION` 均 0 命中；实际由 Voxy 的 `MixinShaderPackSourceNames`（向 `ShaderPackSourceNames.findPotentialStarts` 注入 `voxy.json` / `voxy_opaque.glsl` / `voxy_translucent.glsl` 三个入口名）与 `IrisShaderPatch` 完成。
- `IrisShaderPatch.VERSION = 1`（schema 版本，`12111` 与 `2622` 两分支该文件逐字节相同）→ 本包 `voxy.json` 的 `"version": 1` 正确；版本不匹配时 Voxy 直接 `throw IllegalStateException`（L391-393）。
- schema 键位（同上文件）：`version` / `opaqueDrawBuffers` / `translucentDrawBuffers` / `uniforms` / `samplers` / `blending` / `taaOffset` / `excludeLodsFromVanillaDepth` / `useViewportDims` —— 本包 `Passes/Voxy.json` 全部命中，无未知键、无缺键（`scripts/check_resources.py` 常态校验）。
- `#define VOXY` 的取值 = `IrisShaderPatch.SHADER_DEFINE_VERSION`：**1.21.11（分支 `12111`，对应 0.2.16-beta）与 26.2（分支 `2622`，对应 0.2.19-beta）都是 `2`**；`3` 只出现在 `263` / `dev`（0.2.20-beta，MC 26.3）。因此本包一律用 `#ifdef` / `#if defined` 判断，禁止写 `#if VOXY >= n`（`LodSupport.glsl` 已符合）。
- uniform / sampler 名（`VoxyUniforms.java` / `VoxySamplers.java`；两分支接口相同，差异只在内部取 render system 的方式）：
  - `vxRenderDistance`（int，**单位是 chunk** = `sectionRenderDistance * 32`）
  - `vxProj` / `vxProjInv` / `vxProjPrev`、`vxModelView` / `vxModelViewInv` / `vxModelViewPrev`、`vxViewProj` / `vxViewProjInv` / `vxViewProjPrev`
  - 采样器 `vxDepthTexOpaque`（opaque FBO 深度）、`vxDepthTexTrans`（translucent FBO 深度）
  - 本包 `LodSupport.glsl` 与 `Passes/Voxy.json` 的 `uniforms` 列表声明与之一致。
- `IMPERSONATE_DISTANT_HORIZONS`（Voxy 伪装成 DH、额外提供 `dh*` uniform 与 `dhDepthTex*` 采样器）在 `12111` / `2622` 两分支中**均为注释状态** → DH 与 Voxy 的 uniform 命名空间不会同时出现，本包 `#if defined DISTANT_HORIZONS / #elif defined VOXY` 的二选一结构成立。
- Voxy 注入面只有上述三个文件，**不含 shadow 程序** → Voxy 侧 LOD 阴影不可得，LOD 阴影只有 DH 通道（`dh_shadow`）一条路，与既有结论一致。
- Voxy 依赖（Modrinth）：required = Sodium、Fabric API；optional = Mod Menu。

### Roxy 侧 · 1.21.1 NeoForge 专用

- Roxy 是 MIT 翻译层，**不分发 Voxy**；README 要求：MC 1.21.1 NeoForge + Forgified Fabric API + Sodium 0.8.12+ + 原版 `voxy-0.2.16-beta` jar（README 原文称这是“唯一完整验证过的版本”，该 jar 为 MC 1.21.11 编译）。
- Modrinth 依赖（0.4.1）：required = Forgified Fabric API / Voxy / Sodium；incompatible = Vivecraft；optional = Fog。
- 0.4.1（2026-10-22）新增 Apple Silicon macOS 实验性支持，需额外 patch bundle。
- Linux AMD/Mesa 出现地形形状的水面空洞时，加启动器实例环境变量 `AMD_DEBUG=nohyperz`。
- Roxy 组合下 `VOXY` 宏来自被加载的 Voxy 本体 mixin（与 Fabric 原生同源），因此 `SHADER_DEFINE_VERSION` 跟随 **voxy-0.2.16-beta = 2**。

## 红线（升级前必查）

1. **Iris ≥ 1.12 会破坏 Voxy 集成**（Voxy `0.2.20-beta` changelog，2026-10-19：“iris 1.11.7 support (breaks with iris >= 1.12)”）。当前三线分别是 Iris 1.8.14-beta.1 / 1.10.8 / 1.11.4，都在线下；**26.2 线离断点最近**，Iris 升到 1.12 前必须先确认 Voxy 已适配。
2. **26.2 线要求 DH ≥ 3.3.3**（修复 Iris 在 MC 26.1.2+ 的 lightmap / blend）。
3. **`voxy.json` 的 `version` 必须为 1**，不匹配 Voxy 直接抛异常拒绝加载。
4. Voxy 客户端 GL 能力层用到 GL 4.4 常量（`GL_DYNAMIC_STORAGE_BIT` / `GL_MAP_COHERENT_BIT`）、`GL_ARB_gpu_shader_int64` 与 `GL_KHR_shader_subgroup_basic/arithmetic`（`Capabilities.java`，分支 `2622`）；本包自身要求 GL 4.3+。（旧版本表里写的“Voxy 要求 OpenGL 4.6”本轮未在源码中核到，已删除，不做无来源断言。）
5. 已验证 Roxy 组合：MC 1.21.1 NeoForge + Roxy 0.4.1 + 原版 `voxy-0.2.16-beta` jar（为 1.21.11 编译）+ Forgified Fabric API + Sodium 0.8.12+；Roxy 与 Vivecraft 不兼容。
6. Voxy 为 ARR（Modrinth license = `LicenseRef-All-Rights-Reserved`），非官方移植版分发违反其许可；与上游沟通时把 Roxy（MIT 翻译层，不分发 Voxy）区分清楚。

## 上游跟踪清单

- **Voxy `263` / `dev` 已把 shader 版本推到 3**（0.2.20-beta，MC 26.3），同时新增 `vxNearPlane` / `vxFarPlane` uniform、`useDynamicFarPlane` 选项，并对 `voxy_opaque` / `voxy_translucent` 的补丁源做 **revZ 深度反转重写**（`gl_FragDepth → (1.0-gl_FragDepth)`、`gl_FragCoord.z` 反转、深度采样器读取反转，见 `IrisShaderPatch` 中的 revZ 修正函数）；schema `VERSION` 仍为 1。**一旦 26.2 线出现 `SHADER_DEFINE_VERSION = 3` 的 Voxy 构建**，必须重查本包 `voxy_opaque.glsl` / `voxy_translucent.glsl` 里 `gl_FragDepth` / `gl_FragCoord` / 深度采样的写法，并评估 `vxNearPlane` / `vxFarPlane` 能否替掉现有透视矩阵重建。
- Voxy（Modrinth `voxy`，作者 cortex，仓库 `MCRcortex/voxy`，默认分支 `dev`）：发版即跑 CI + 更新本表。
- DH（Modrinth `distanthorizons`，作者 jeseibel，仓库在 GitLab）：关注 config version 变更与 Iris 兼容修复。
- Iris（`IrisShaders/Iris`，默认分支 `26.1`）：关注 1.12 线 Voxy 接口变动、DH combined 矩阵 uniform 名稳定性、`dhBlockAtlas` 是否回灌到 1.21.x 分支。
- Redux 官方（continuum.graphics）：新 build 发布后重跑移植报告 §4 静态核验并 rebase 差异台账。

---

内容由 AI 生成
