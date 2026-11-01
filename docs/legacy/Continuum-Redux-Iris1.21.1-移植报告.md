# Continuum 2.0 Redux Build 2 → Iris 1.21.1 (NeoForge) 移植报告

- **移植对象**：`Continuum 2.0 Redux Build 2.zip`（08.03.2026，Continuum Graphics 官方认可的 Continuum 2.0 改编版）
- **原环境**：Minecraft 1.21.10 / 1.21.11 + Iris 1.9.6+（官方 FAQ 声明）
- **目标环境**：Minecraft 1.21.1 + NeoForge + Iris（Iris 1.8.x 线，NeoForge 官方构建如 `1.8.12+1.21.1-neoforge`，Sodium 随附）
- **交付物**：`Continuum 2.0 Redux Build 2 [1.21.1].zip`（4.0 MB，336 条目，含 `shaders/` 332 文件 + LICENSE + README + pack.mcmeta + 移植说明）
- **结论**：**源码零修改即可兼容**；移植 = 全量 API 核验 + 新增 `pack.mcmeta` + 打包。逐项核验未发现任何需要改写的 1.9.x 专属用法（Voxy 相关代码全部处于 `#ifdef VOXY` 守卫内，Iris 1.21.1 下自动走非 Voxy 分支）。

---

## 1. 为什么选 Redux Build 2 而不是 Continuum 2.0.5

| 维度 | Continuum 2.0.5 | Continuum 2.0 Redux Build 2 |
|---|---|---|
| 发布定位 | 2021 年原版（追求物理正确） | 2026 年官方认可改编版（游戏友好/风格化） |
| 官方支持 MC | ≤ 1.19.0 | 1.21.10 / 1.21.11（Iris 1.9.6+） |
| 布局 | OptiFine 经典布局（program 在根目录、world-1/world1） | 现代 Iris 布局（DimOverworld/DimNether/DimEnd + Passes/ + dimension.properties + `#include`） |
| GLSL | `#version 120`（遗留语法） | `#version 430`（168 个 compatibility + 27 个无 profile） |
| 特性 | 基础 PBR | LPV 彩色光照、Tessendorf 波浪、froxel 体积光、植物次表面、worley/perlin 体积云、TAA、下界/末地支持 |
| 移植到 1.21.1 的工作量 | 大（老语法 + 老布局 + 无维度支持） | **经核验为零** |

Redux 的现代布局与 GLSL 430 恰好落在 Iris 1.8.x 的能力范围内，因此作为移植基底。

## 2. 平台事实（基于 IrisShaders/Iris `1.21.1` 分支源码核验）

| 事实 | 结论 |
|---|---|
| Iris 官方 NeoForge 构建 | 自 1.21.1 起提供（Modrinth：`1.8.12+1.21.1-neoforge` 等） |
| `iris.features.required` 合法值 | `FeatureFlags` 枚举含 `CUSTOM_IMAGES`、`SSBO`、`COMPUTE_SHADERS` 等 —— Redux 要求的 `CUSTOM_IMAGES SSBO` **均支持** |
| `#version 430 compatibility` | `TransformPatcher` 保留版本号，profile 自动转 core，低于 330 自动提升 —— **支持** |
| 维度目录布局 | `dimension.properties` + `Dim*` 目录为标准特性（含 `*` 通配）—— **支持** |
| 程序发现 | `Setup/Begin/ShadowComposite/Prepare/Deferred/Composite` 数组各 100 个槽位，`_a`..`_z` compute 后缀全覆盖 —— Redux 的 `deferred8`/`composite9`/`composite4_a`/`begin1/2` **全部合法** |
| 指令族 | `alphaTest / blend / bufferObject / customTexture / image. / flip. / size.buffer / texture. / program.*.enabled / uniform.* / variable.* / allowConcurrentCompute` **全部被解析** |
| 纹理格式 | `RGBA16F / R16F / R11F_G11F_B10F / RG8 / RGB8 / RGBA8 / R32F`、TEXTURE_3D raw（7/8 参数）—— **全部存在** |
| Voxy | Iris 1.21.1 源码 **零引用**（Voxy 支持是 1.9.x 的事）—— Redux 的 Voxy 文件变为惰性 |
| DH | Redux 本身不支持 DH（作者 roadmap 长期目标）—— 无需处理 |

## 3. Uniform 级核验（95 项）

- 逐项比对 Redux 全部 uniform 与 Iris 1.21.1 / 1.21.11 两分支源码：**无任何 uniform 是 1.9.x 专属**；
- temporal/TAA 矩阵（`gbufferPreviousModelView`、`gbufferPreviousProjection`）为 C8_TAA.frag 中声明未使用的项，编译期被消除，无害；
- `previousCameraPosition`、`centerDepthSmooth`、`eyeBrightnessSmooth`、`frameTimeCounter` 等在两版本均存在；
- Voxy 专用 `vxDepthTexOpaque / vxDepthTexTrans / vxProj / vxProjInv / vxRenderDistance`：实际使用全部位于 `#ifdef VOXY` / `#if defined VOXY` 守卫内（B0_InitSSBOs.comp、C0/D0_ConstructDepth.comp），顶层仅剩声明，非 Voxy 环境编译期消除。

## 4. 静态校验结果

| 校验 | 方法 | 结果 |
|---|---|---|
| include 图 | 模拟 Iris 解析（相对路径 + `/` 绝对路径 + 递归内联 + 循环防护），覆盖 3 个维度 × 69 个程序文件 | **207/207 全部解析，0 缺失** |
| 预处理结构 | 合并后 `#if/#if/#endif` 配平扫描 | 全部配平 |
| GLSL 语法 | glslang 16.6.0（`--target-env opengl`）逐程序校验 | 29 个直接通过；178 个报错经逐条分类**全部为 SPIR-V 模式伪错误**：compat profile 148、uniform/IO location 157、const 折叠 9，其余为级联中止；桌面 GL 下均合法（Iris 的 Transformer 正是做这些转换） |
| 指令与资源 | `image.*` 16 项（恰达 Iris 16 张上限）、`customTexture.*` 7 项、`bufferObject.0..3`、`texture.deferred.colortex2` | 全部合法 |
| Iris 内部接口保留字 | 扫描 `moj_import` / `irisMain` / `iris_` 前缀（Iris 会直接抛错拒绝） | **0 命中** |
| 遗留空文件 | `gbuffers_main*.fsh` 仅含版权头、无 `#version` | 非 Iris 程序名（不在 ProgramId），不会被发现/编译，无害 |

## 5. 交付物与使用

**`Continuum 2.0 Redux Build 2 [1.21.1].zip`**（4.0 MB）

```
├── shaders/                # 332 个文件，与原版完全一致（源码零修改）
├── LICENSE                 # 原许可保留
├── README.md               # 原版说明保留
├── pack.mcmeta             # 新增：pack_format 34（MC 1.21.1）
└── 移植说明.md             # 新增：适配说明
```

使用方法：放入 `.minecraft/shaderpacks/` → 视频设置 → 光影 → 选择 "Continuum 2.0 Redux Build 2" → 应用。硬件要求 GL 4.3+（作者要求，GTX 950 起步）。profile 系统作者提示有问题，**建议直接用 High profile**。

## 6. 注意事项与残余风险

1. **Voxy 功能不可用**：Iris 1.21.1 不支持 Voxy（需 1.9.x + Fabric 端 Voxy 模组）。已在 `#ifdef VOXY` 外无泄漏，静态可确认；若在 Voxy -enabled 的更高版本 Iris 上使用同一 zip，Voxy 分支会自动激活。
2. **DH 不支持**：原版即无 DH 代码。
3. **实机加载未验证**：本环境无法运行 Minecraft。已完成的是全量静态核验（API/指令/uniform/include/语法）；建议实机首次加载时观察 Iris 日志有无 `Unsupported` / shader 编译错误。若个别 pass 出现运行时差异，预计只会是数值行为（如 TAA 细节）而非加载失败。
4. **许可**：Continuum Graphics ARR。本 zip 为个人使用适配；请勿再分发（LICENSE 已保留在包内）。

## 7. 附：核验环境

- Iris 源码：`IrisShaders/Iris` 分支 `1.21.1`（≈1.8.x）与 `1.21.11`（≈1.9.x）对照
- glslang 16.6.0（Windows）；Python 3.13 自研 include 模拟器
- Modrinth API（Iris/DERCODE 版本事实）、continuum.graphics FAQ（Redux 官方支持矩阵）
