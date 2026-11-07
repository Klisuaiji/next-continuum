# Continua

**Continua 1.0 — 面向 Minecraft 1.21.1 + Iris 的写实光影包（发布版）。**

`next-continuum` 是开发线；**Continua** 是从这条开发线冻结出的发布版名称，自 v1.0 起用于和仍在迭代的开发版本区分。两者共用同一套 `shaders/` 源码，但 Continua 1.0 只面向 **Minecraft 1.21.1 + Iris 1.8.x（Fabric / NeoForge）**，不追求多版本同步。下方三条维护线（1.21.1 / 1.21.11 / 26.2）描述的是开发线范围。

## 路线调整：不再开发 NeoFocal Engine

原先计划以自研 Java 渲染引擎（Focal Engine / NeoFocal Engine）承载 Continuum 2.1.3 的 compute 渲染图。**该路线已放弃**——逐项核验后确认 Iris 1.21.1 已原生支持 `CUSTOM_IMAGES`、`SSBO`、compute programs、`image.*`（含 3D 格式）、`bufferObject.*`、`allowConcurrentCompute` 与 `dimension.properties`，无需额外的模组侧渲染器。

因此 Continua 采用纯 shaderpack 路线：把 2.1.3 / Focal 的新渲染逻辑（自动曝光 M1、体积云 V2、四档性能配置、快速滤镜、视觉风格与水体预设拆分、自定义维度映射等）**直接移植到 1.21.1 的老包基础上**，渲染管线仍由 Iris 托管。原先 NeoFocal 引擎侧的资源管理器、程序链接、GlobalUniforms、渲染图执行器与 `CompositeRenderer` mixin 等里程碑全部作废。

## Project Goals

- Investigate Continuum Redux compatibility with Minecraft 1.21.1 / 1.21.11 / 26.2.
- Explore Iris shader pipeline compatibility.
- Study rendering differences between shader platform versions.
- Identify and document migration issues.
- Develop independently authored compatibility tools and technical documentation.
- Maintain a clear separation between original project materials and independently developed work.

## Target Environment

| Component | Target |
|---|---|
| Minecraft (maintained) | 1.21.1 · 1.21.11 · 26.2 |
| Mod Loader | Fabric / NeoForge |
| Shader Loader | Iris (1.8.x on 1.21.1 · 1.10.x on 1.21.11 · 1.11.x on 26.2) |
| LOD | Distant Horizons 3.3.3 (all three) · Voxy (1.21.11 / 26.2 native Fabric, 1.21.1 via Roxy) |
| Upstream Project | Continuum 2.0 Redux Build 2 |
| Shader Language | GLSL |

Per-version Iris / Distant Horizons / Voxy / Roxy builds and the verified integration surface are tracked in [`docs/TARGET-MATRIX.md`](docs/TARGET-MATRIX.md).

## Project Status

**Experimental — Under Development**

This is an ongoing technical research and porting project. Compatibility, performance, and feature support are still being investigated.

### Phase 2 (since 2026-10): LOD Support

- Scope: **Iris only, on the three maintained lines — Minecraft 1.21.1 / 1.21.11 / 26.2**. The OptiFine ("高清修复") compatibility line and the 1.21.1 down-port are archived as tag `legacy-1.21.1`.
- Adding **Distant Horizon LOD support** (`dh_terrain` / `dh_water` / `dh_shadow` programs + LodSupport abstraction layer; uniform and sampler names re-verified against the Iris `1.21.1`, `1.21.11` and `26.2` branches).
- **Voxy integration kept as first-class** (`voxy.json` schema v1, verified against Voxy `0.2.16-beta` for 1.21.11 and `0.2.19-beta` for 26.2 — both inject `#define VOXY 2`; `shadow_voxels` and `renderScale` still planned), maintained together with **Roxy** (MIT NeoForge translation layer, the only Voxy path on 1.21.1) — see `docs/TARGET-MATRIX.md`.
- Localization: `zh_CN` / `zh_TW` / `ja_JP` language files for the Iris settings UI (full key coverage of `en_US.lang`);
- Static checks (include graph / resource budget / GLSL baseline diff) run in CI; all deviations from upstream are tracked in `docs/UPSTREAM-DIFF.md`.

## Continua 1.0（2026-11-07）

| 项 | 内容 |
|---|---|
| 版本 | Continua 1.0（首个可加载发布版，基于 `main @ 105e578`） |
| 目标环境 | Minecraft 1.21.1 · Iris 1.8.x · Fabric / NeoForge |
| 交付物 | `Continua 1.0 [MC 1.21.1][Iris].zip` |
| 关键修复 | `shaders/InternalLib/UserLibManager.glsl` 三处 `#include` 行尾注释（Iris 报 `failed to resolve #include directive / file not found`）；`scripts/check_includes.py` 增加行尾注释检出，消除假 PASS |
| CI 修复 | `scripts/check_glsl.py` 维度薄壳失败按内容签名归一，避免每新增维度目录产生上百条等价伪失败 |
| 开源参考 | Photon / Alpha Piscium / Noble / Complementary（路线图 §11，仅作工程组织与实现思路参考，不复制代码，遵守各自许可证） |

**已知限制**：实机验证率仍为 0%；HiZ / GTAO / SSGI 被 `image 16/16` 资源预算阻塞；`DIM_TWILIGHT` / `DIM_AETHER` / `DIM_SPACE` 尚未被 Passes 消费，自定义维度当前回退主世界环境参数；七档体系与现行四档的差异见路线图 §5。

## Upstream Project

Next Continuum is based on research into the publicly released Continuum 2.0 Redux project.

For information about the original shaderpack, please visit:

- [Continuum Graphics — Official Website](https://continuum.graphics/)
- [Continuum Shaders — Official Project Page](https://continuum.graphics/continuum-shaders/)

Please obtain original shaderpack materials through their official distribution channels and follow the applicable terms.

## Important Notice

Next Continuum is an independent, unofficial project. It is not affiliated with, endorsed by, or officially supported by Continuum Graphics or the Redux author.

Continuum, Continuum Redux, and their associated shader code and assets remain the property of their respective copyright holders.

No authorization has been obtained to redistribute the original Redux shader files or modified versions of those files.

This repository is intended to focus on independently developed compatibility work, migration documentation, and tools. It does not grant permission to copy, modify, or redistribute upstream materials.

## License

Original materials authored by the repository maintainer are subject to the license specified in this repository.

All third-party materials remain subject to their respective copyright holders and license terms.

---

*An independent effort to explore the next step in Continuum compatibility.*
