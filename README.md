# Next Continuum

**An experimental compatibility and porting project for Continuum 2.0 Redux.**

Next Continuum explores the adaptation of **Continuum 2.0 Redux Build 2** to modern Minecraft environments, with a particular focus on Iris and the three maintained Minecraft lines: **1.21.1, 1.21.11 and 26.2**.

The project aims to investigate rendering compatibility, shader behavior, performance, and integration challenges while developing an independent migration and compatibility workflow.

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
