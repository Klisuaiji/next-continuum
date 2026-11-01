# 目标版本矩阵（Target Matrix）

> 本包定位：**放弃高清修复（OptiFine）与低版本适配线，自 Minecraft 1.21.1 起向上支持。**
> 最后核验：2026-10-31（来源：Roxy README 2026-10-17、Voxy changelog 2026-10-19、DH/MC百科、Iris 源码核验见 docs/legacy 移植报告）。

## 支持分级

| 档位 | MC | 加载器 | Iris | Voxy 集成 | DH 集成 | 状态 |
|---|---|---|---|---|---|---|
| 基准验证线 | 1.21.10 / 1.21.11 | Fabric | 1.9.x | ✅ 原生（voxy.json v1） | ✅（DH 2.x，Iris≥1.7.5） | Phase 2 主验证环境 |
| NeoForge 线 | 1.21.10 / 1.21.11 | NeoForge | 1.9.x neoforge 构建 | ✅（Voxy 0.2.16-beta 官方 NeoForge 支持核验中） | ✅ | 与基准线同包 |
| 下限兼容线 | 1.21.1 | NeoForge / Fabric | 1.8.x | ⚠️ Iris 1.8.x 无 Voxy 管线注入；需 Roxy 组合实机验证 VOXY 宏来源 | ✅（Iris 1.8.x ≥1.7.5 满足 DH 门槛） | 尽力支持，S2 实机矩阵验证 |
| 跟踪观察 | 26.x | Fabric | ≤1.11.7 | 最新 Voxy 支持 | ✅ | **不出包**，仅跟踪上游 |

## 红线（升级前必查）

1. **Iris ≥ 1.12 会破坏 Voxy 集成**（Voxy changelog 2026-10-19：`iris 1.11.7 support (breaks with iris >= 1.12)`）。CI/发布前锁定 Iris 上限。
2. DH 2.1.0+ 需 Iris 1.7+；DH 2.2.0+ 需 Iris 1.7.5+；光影包必须显式适配 DH。
3. Voxy 本体要求 OpenGL 4.6；本包要求 GL 4.3+（Iris 会提示不支持）。
4. 已验证 Roxy 组合：MC 1.21.1 NeoForge + Roxy + **原版 voxy-0.2.16-beta jar（为 1.21.11 编译）** + Forgified Fabric API + Sodium 0.8.12+；Linux AMD/Mesa 建议 `AMD_DEBUG=nohyperz`（水面空洞问题）。
5. Voxy 非官方移植版分发违反其 ARR 许可——Roxy 为 MIT 翻译层（不再分发 Voxy），与上游沟通时区分清楚。

## 上游跟踪清单

- Voxy（Modrinth `voxy`，作者 cortex）：发版即跑 CI + 更新本表；宏定义版本随 `IrisShaderPatch.SHADER_DEFINE_VERSION`（现为 3，`#define VOXY 3` 带值宏，消费方以 `#ifdef`/`#if defined` 判断兼容）
- DH shadow：`dh_shadow` 程序槽存在（Iris compat/dh DHCompatInternal L82），Voxy 无 shadow 程序（集成面仅 voxy.json/opaque/translucent）
- Redux 官方（continuum.graphics）：新 build 发布后重跑移植报告 §4 静态核验并 rebase 差异台账
- Iris（IrisShaders/Iris）：关注 1.12 线 Voxy 接口变动、DH combined 矩阵 uniform 名稳定性

---

内容由 AI 生成
